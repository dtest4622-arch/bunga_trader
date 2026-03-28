from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc
from datetime import datetime

from app.db.base import get_db
from app.core.security import get_current_user_id
from app.models.trade import Trade
from app.models.trading_account import TradingAccount
from app.services.mt5_bridge import mt5_bridge

router = APIRouter()


@router.get("", response_model=List[dict])
async def get_trades(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    status: Optional[str] = None,
    pair: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get trades for current user."""
    query = select(Trade).order_by(desc(Trade.created_at))

    # Filter by user_id for security (RLS-like)
    query = query.where(Trade.user_id == user_id)

    if status:
        query = query.where(Trade.status == status.upper())
    if pair:
        query = query.where(Trade.pair.ilike(f"%{pair}%"))

    query = query.limit(limit).offset(offset)

    result = await db.execute(query)
    trades = result.scalars().all()

    return [trade.to_dict() for trade in trades]


@router.get("/active", response_model=List[dict])
async def get_active_trades(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get all active (open) trades for current user."""
    result = await db.execute(
        select(Trade)
        .where(and_(Trade.user_id == user_id, Trade.status == "OPEN"))
        .order_by(desc(Trade.created_at))
    )
    trades = result.scalars().all()
    return [trade.to_dict() for trade in trades]


@router.get("/history", response_model=List[dict])
async def get_trade_history(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get trade history (closed trades) for current user."""
    query = select(Trade).where(
        and_(
            Trade.user_id == user_id,
            Trade.status == "CLOSED"
        )
    ).order_by(desc(Trade.closed_at))

    if from_date:
        query = query.where(Trade.created_at >= from_date)
    if to_date:
        query = query.where(Trade.created_at <= to_date)

    query = query.limit(limit).offset(offset)

    result = await db.execute(query)
    trades = result.scalars().all()

    return [trade.to_dict() for trade in trades]


@router.get("/{trade_id}", response_model=dict)
async def get_trade(
    trade_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific trade."""
    result = await db.execute(
        select(Trade).where(
            and_(
                Trade.id == trade_id,
                Trade.user_id == user_id
            )
        )
    )
    trade = result.scalar_one_or_none()

    if not trade:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trade not found"
        )

    return trade.to_dict()


@router.patch("/{trade_id}/close")
async def close_trade(
    trade_id: str,
    close_data: Optional[dict] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Close a trade (full or partial)."""
    result = await db.execute(
        select(Trade).where(
            and_(
                Trade.id == trade_id,
                Trade.user_id == user_id
            )
        )
    )
    trade = result.scalar_one_or_none()

    if not trade:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trade not found"
        )

    if not trade.is_open:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Trade is already closed"
        )

    # Check if partial close
    partial_percent = None
    close_reason = close_data.get("reason", "MANUAL") if close_data else "MANUAL"
    if close_data and close_data.get("partial_percent"):
        partial_percent = close_data.get("partial_percent")

    # Close on MT5
    try:
        mt5_result = await mt5_bridge.close_trade({
            'ticket': trade.broker_ticket,
            'partial_percent': partial_percent,
        })

        if not mt5_result.get('success'):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to close trade on MT5: {mt5_result.get('error')}"
            )

        # Update trade record
        if partial_percent:
            # Partial close - update lot size and keep open
            trade.lot_size = trade.lot_size * (1 - partial_percent / 100)
            if trade.partial_closes is None:
                trade.partial_closes = []
            trade.partial_closes.append({
                'percent': partial_percent,
                'price': mt5_result.get('price'),
                'pnl': mt5_result.get('pnl'),
                'closed_at': datetime.utcnow().isoformat()
            })
            trade.status = "MODIFIED"
        else:
            # Full close
            trade.status = "CLOSED"
            trade.closed_price = mt5_result.get('price')
            trade.final_pnl = mt5_result.get('pnl')
            trade.close_reason = close_reason
            trade.closed_at = datetime.utcnow()

        trade.floating_pnl = mt5_result.get('pnl', 0.0)
        trade.commission = mt5_result.get('commission', 0.0)
        trade.swap = mt5_result.get('swap', 0.0)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to close trade: {str(e)}"
        )

    await db.commit()
    await db.refresh(trade)

    return {
        "message": "Trade closed successfully",
        "trade": trade.to_dict()
    }


@router.patch("/{trade_id}/modify")
async def modify_trade(
    trade_id: str,
    modify_data: dict,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Modify trade stop loss and/or take profit."""
    result = await db.execute(
        select(Trade).where(
            and_(
                Trade.id == trade_id,
                Trade.user_id == user_id
            )
        )
    )
    trade = result.scalar_one_or_none()

    if not trade:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trade not found"
        )

    if not trade.is_open:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot modify a closed trade"
        )

    # Store original values if not already stored
    if trade.original_sl is None:
        trade.original_sl = trade.stop_loss
    if trade.original_tp is None:
        trade.original_tp = trade.take_profit

    # Update values
    if "stop_loss" in modify_data:
        trade.stop_loss = modify_data["stop_loss"]
    if "take_profit" in modify_data:
        trade.take_profit = modify_data["take_profit"]
    if "take_profit_2" in modify_data:
        trade.take_profit_2 = modify_data["take_profit_2"]
    if "take_profit_3" in modify_data:
        trade.take_profit_3 = modify_data["take_profit_3"]

    # Modify on MT5
    try:
        mt5_result = await mt5_bridge.modify_trade({
            'ticket': trade.broker_ticket,
            'stop_loss': trade.stop_loss,
            'take_profit': trade.take_profit,
        })

        if not mt5_result.get('success'):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to modify trade on MT5: {mt5_result.get('error')}"
            )

        trade.status = "MODIFIED"

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to modify trade: {str(e)}"
        )

    await db.commit()
    await db.refresh(trade)

    return {
        "message": "Trade modified successfully",
        "trade": trade.to_dict()
    }


@router.post("/close-all")
async def close_all_trades(
    pair: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Close all open trades for current user."""
    query = select(Trade).where(
        and_(
            Trade.user_id == user_id,
            Trade.status == "OPEN"
        )
    )

    if pair:
        query = query.where(Trade.pair == pair.upper())

    result = await db.execute(query)
    trades = result.scalars().all()

    if not trades:
        return {"message": "No open trades found", "closed_count": 0}

    closed_count = 0
    errors = []

    for trade in trades:
        try:
            mt5_result = await mt5_bridge.close_trade({
                'ticket': trade.broker_ticket,
            })

            if mt5_result.get('success'):
                trade.status = "CLOSED"
                trade.closed_price = mt5_result.get('price')
                trade.final_pnl = mt5_result.get('pnl')
                trade.close_reason = "MANUAL"
                trade.closed_at = datetime.utcnow()
                trade.floating_pnl = mt5_result.get('pnl', 0.0)
                closed_count += 1
            else:
                errors.append({
                    'trade_id': trade.id,
                    'error': mt5_result.get('error')
                })
        except Exception as e:
            errors.append({
                'trade_id': trade.id,
                'error': str(e)
            })

    await db.commit()

    return {
        "message": f"Closed {closed_count} trades",
        "closed_count": closed_count,
        "total_count": len(trades),
        "errors": errors if errors else None
    }


@router.get("/{trade_id}/sync")
async def sync_trade(
    trade_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Sync trade data from MT5."""
    result = await db.execute(
        select(Trade).where(
            and_(
                Trade.id == trade_id,
                Trade.user_id == user_id
            )
        )
    )
    trade = result.scalar_one_or_none()

    if not trade:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trade not found"
        )

    try:
        mt5_result = await mt5_bridge.get_position(trade.broker_ticket)

        if mt5_result.get('success'):
            trade.current_price = mt5_result.get('current_price')
            trade.floating_pnl = mt5_result.get('pnl')
            trade.commission = mt5_result.get('commission', 0.0)
            trade.swap = mt5_result.get('swap', 0.0)
            trade.updated_at = datetime.utcnow()
        else:
            # Position might be closed
            if "not found" in mt5_result.get('error', '').lower():
                trade.status = "CLOSED"
                trade.closed_at = datetime.utcnow()
                trade.close_reason = "EXPIRED"

    except Exception as e:
        trade.last_error = str(e)

    await db.commit()
    await db.refresh(trade)

    return trade.to_dict()
