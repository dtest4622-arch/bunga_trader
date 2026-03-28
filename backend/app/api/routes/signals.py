from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc
from datetime import datetime, timedelta

from app.db.base import get_db
from app.core.security import get_current_user_id
from app.core.config import settings
from app.models.signal import Signal
from app.models.trading_account import TradingAccount
from app.schemas.signal import (
    SignalResponse,
    SignalExecute,
    SignalFilter
)
from app.services.groq_ai import ai_risk_manager
from app.services.mt5_bridge import mt5_bridge

router = APIRouter()


@router.get("", response_model=List[SignalResponse])
async def get_signals(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    status: Optional[str] = None,
    pair: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get trading signals."""
    query = select(Signal).order_by(desc(Signal.created_at))
    
    if status:
        query = query.where(Signal.status == status.upper())
    if pair:
        query = query.where(Signal.pair.ilike(f"%{pair}%"))
    
    query = query.limit(limit).offset(offset)
    
    result = await db.execute(query)
    signals = result.scalars().all()
    
    return [signal.to_dict() for signal in signals]


@router.get("/{signal_id}", response_model=SignalResponse)
async def get_signal(
    signal_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific signal."""
    result = await db.execute(
        select(Signal).where(Signal.id == signal_id)
    )
    signal = result.scalar_one_or_none()
    
    if not signal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Signal not found"
        )
    
    return signal.to_dict()


@router.post("/{signal_id}/execute")
async def execute_signal(
    signal_id: str,
    execute_data: SignalExecute,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Execute a trading signal."""
    # Get signal
    result = await db.execute(
        select(Signal).where(Signal.id == signal_id)
    )
    signal = result.scalar_one_or_none()
    
    if not signal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Signal not found"
        )
    
    if not signal.is_pending:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Signal is already {signal.status.lower()}"
        )
    
    if signal.is_expired:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signal has expired"
        )
    
    # Get trading account
    result = await db.execute(
        select(TradingAccount).where(
            and_(
                TradingAccount.id == execute_data.account_id,
                TradingAccount.user_id == user_id
            )
        )
    )
    account = result.scalar_one_or_none()
    
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trading account not found"
        )
    
    # Execute trade on MT5
    trade_result = await mt5_bridge.execute_trade({
        'pair': signal.pair,
        'direction': signal.direction,
        'lot_size': signal.ai_lot_size,
        'stop_loss': signal.ai_stop_loss,
        'take_profit': signal.ai_take_profit,
        'signal_id': signal.id,
    })
    
    if not trade_result.get('success'):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Trade execution failed: {trade_result.get('error')}"
        )
    
    # Update signal
    signal.status = "EXECUTED"
    signal.executed_at = datetime.utcnow()
    signal.executed_by = user_id
    
    # Create trade record
    from app.models.trade import Trade
    trade = Trade(
        signal_id=signal.id,
        account_id=account.id,
        user_id=user_id,
        broker_ticket=trade_result['ticket'],
        pair=signal.pair,
        direction=signal.direction,
        lot_size=signal.ai_lot_size,
        entry_price=trade_result['price'],
        stop_loss=signal.ai_stop_loss,
        take_profit=signal.ai_take_profit,
        opened_at=datetime.utcnow(),
    )
    
    db.add(trade)
    await db.commit()
    await db.refresh(trade)
    
    return {
        "message": "Signal executed successfully",
        "trade": trade.to_dict()
    }


@router.post("/{signal_id}/reject")
async def reject_signal(
    signal_id: str,
    reason: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Reject a trading signal."""
    result = await db.execute(
        select(Signal).where(Signal.id == signal_id)
    )
    signal = result.scalar_one_or_none()
    
    if not signal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Signal not found"
        )
    
    if not signal.is_pending:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signal is not pending"
        )
    
    signal.status = "REJECTED"
    signal.rejection_reason = reason
    
    await db.commit()
    
    return {"message": "Signal rejected"}
