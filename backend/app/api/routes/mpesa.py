from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc
from datetime import datetime

from app.db.base import get_db
from app.core.security import get_current_user_id
from app.models.transaction import Transaction, TransactionType, TransactionStatus
from app.models.trading_account import TradingAccount
from app.services.mpesa_gateway import mpesa_gateway

router = APIRouter()


@router.get("/deposits", response_model=List[dict])
async def get_deposits(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    status_filter: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get deposit transactions for current user."""
    query = select(Transaction).where(
        and_(
            Transaction.user_id == user_id,
            Transaction.type == TransactionType.DEPOSIT
        )
    ).order_by(desc(Transaction.created_at))

    if status_filter:
        query = query.where(Transaction.status == TransactionStatus(status_filter.upper()))

    query = query.limit(limit).offset(offset)

    result = await db.execute(query)
    transactions = result.scalars().all()

    return [tx.to_dict() for tx in transactions]


@router.get("/withdrawals", response_model=List[dict])
async def get_withdrawals(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    status_filter: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get withdrawal transactions for current user."""
    query = select(Transaction).where(
        and_(
            Transaction.user_id == user_id,
            Transaction.type == TransactionType.WITHDRAWAL
        )
    ).order_by(desc(Transaction.created_at))

    if status_filter:
        query = query.where(Transaction.status == TransactionStatus(status_filter.upper()))

    query = query.limit(limit).offset(offset)

    result = await db.execute(query)
    transactions = result.scalars().all()

    return [tx.to_dict() for tx in transactions]


@router.get("/transactions", response_model=List[dict])
async def get_transaction_history(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    transaction_type: Optional[str] = None,
    status_filter: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get all transactions (deposits and withdrawals) for current user."""
    query = select(Transaction).where(Transaction.user_id == user_id)

    if transaction_type:
        query = query.where(Transaction.type == TransactionType(transaction_type.lower()))
    if status_filter:
        query = query.where(Transaction.status == TransactionStatus(status_filter.upper()))

    query = query.order_by(desc(Transaction.created_at)).limit(limit).offset(offset)

    result = await db.execute(query)
    transactions = result.scalars().all()

    return [tx.to_dict() for tx in transactions]


@router.get("/transaction/{transaction_id}", response_model=dict)
async def get_transaction(
    transaction_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific transaction."""
    result = await db.execute(
        select(Transaction).where(
            and_(
                Transaction.id == transaction_id,
                Transaction.user_id == user_id
            )
        )
    )
    transaction = result.scalar_one_or_none()

    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found"
        )

    return transaction.to_dict()


@router.post("/deposit/initiate")
async def initiate_deposit(
    deposit_data: dict,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Initiate M-Pesa deposit (STK push)."""
    amount_kes = deposit_data.get("amount_kes")
    phone_number = deposit_data.get("phone_number")

    if not amount_kes or amount_kes <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid amount"
        )

    if not phone_number:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number is required"
        )

    # Create pending transaction record
    transaction = Transaction(
        user_id=user_id,
        type=TransactionType.DEPOSIT,
        status=TransactionStatus.PENDING,
        amount_kes=amount_kes,
        amount_usd=mpesa_gateway.kes_to_usd(amount_kes),
        phone_number=phone_number,
        description=f"M-Pesa Deposit of KES {amount_kes}",
    )

    db.add(transaction)
    await db.commit()
    await db.refresh(transaction)

    # Initiate STK push
    try:
        stk_response = mpesa_gateway.initiate_stk_push(
            phone_number=phone_number,
            amount=int(amount_kes),
            account_reference=user_id,
            description=f"Bunga Trader Deposit - {transaction.id}"
        )

        # Update transaction with M-Pesa response data
        transaction.checkout_request_id = stk_response.get("CheckoutRequestID")
        transaction.merchant_request_id = stk_response.get("MerchantRequestID")
        transaction.status = TransactionStatus.PROCESSING
        transaction.metadata = stk_response

        await db.commit()
        await db.refresh(transaction)

        return {
            "message": "STK push initiated successfully",
            "transaction": transaction.to_dict(),
            "mpesa_response": stk_response
        }

    except Exception as e:
        transaction.status = TransactionStatus.FAILED
        transaction.error_message = str(e)
        await db.commit()

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to initiate deposit: {str(e)}"
        )


@router.get("/deposit/status/{checkout_request_id}")
async def check_deposit_status(
    checkout_request_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Check M-Pesa deposit status."""
    result = await db.execute(
        select(Transaction).where(
            and_(
                Transaction.user_id == user_id,
                Transaction.checkout_request_id == checkout_request_id,
                Transaction.type == TransactionType.DEPOSIT
            )
        )
    )
    transaction = result.scalar_one_or_none()

    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Deposit transaction not found"
        )

    # Query M-Pesa for latest status
    try:
        mpesa_status = mpesa_gateway.query_stk_status(checkout_request_id)

        # Update transaction based on M-Pesa response
        result_code = mpesa_status.get("ResultCode")

        if result_code == 0:
            # Success
            transaction.status = TransactionStatus.COMPLETED
            transaction.mpesa_receipt_number = mpesa_status.get("ReceiptNumber")
            transaction.completed_at = datetime.utcnow()
        elif result_code is not None:
            # Failed
            transaction.status = TransactionStatus.FAILED
            transaction.error_message = mpesa_status.get("ResultDesc")

        await db.commit()
        await db.refresh(transaction)

        return {
            "transaction": transaction.to_dict(),
            "mpesa_status": mpesa_status
        }

    except Exception as e:
        # Return cached status if M-Pesa query fails
        return {
            "transaction": transaction.to_dict(),
            "error": str(e)
        }


@router.post("/withdrawal/request")
async def request_withdrawal(
    withdrawal_data: dict,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Request M-Pesa withdrawal."""
    amount_usd = withdrawal_data.get("amount_usd")
    phone_number = withdrawal_data.get("phone_number")
    trading_account_id = withdrawal_data.get("trading_account_id")

    if not amount_usd or amount_usd <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid amount"
        )

    if not phone_number:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number is required"
        )

    # Get user's phone number from transaction history or require it
    # For now, use provided phone number

    # Calculate KES amount
    amount_kes = mpesa_gateway.usd_to_kes(amount_usd)

    # Create pending withdrawal transaction
    transaction = Transaction(
        user_id=user_id,
        type=TransactionType.WITHDRAWAL,
        status=TransactionStatus.PENDING,
        amount_kes=amount_kes,
        amount_usd=amount_usd,
        phone_number=phone_number,
        trading_account_id=trading_account_id,
        description=f"M-Pesa Withdrawal of USD {amount_usd} (KES {amount_kes})",
    )

    db.add(transaction)
    await db.commit()
    await db.refresh(transaction)

    # Initiate B2C payment
    try:
        b2c_response = mpesa_gateway.initiate_b2c_payment(
            phone_number=phone_number,
            amount=int(amount_kes),
            occasion="Withdrawal",
            remarks=f"Bunga Trader Withdrawal - {transaction.id}"
        )

        # Update transaction with M-Pesa response data
        transaction.metadata = b2c_response
        transaction.status = TransactionStatus.PROCESSING

        await db.commit()
        await db.refresh(transaction)

        return {
            "message": "Withdrawal request submitted successfully",
            "transaction": transaction.to_dict(),
            "mpesa_response": b2c_response
        }

    except Exception as e:
        transaction.status = TransactionStatus.FAILED
        transaction.error_message = str(e)
        await db.commit()

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process withdrawal: {str(e)}"
        )


@router.get("/withdrawal/{withdrawal_id}/status")
async def check_withdrawal_status(
    withdrawal_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Check withdrawal status."""
    result = await db.execute(
        select(Transaction).where(
            and_(
                Transaction.id == withdrawal_id,
                Transaction.user_id == user_id,
                Transaction.type == TransactionType.WITHDRAWAL
            )
        )
    )
    transaction = result.scalar_one_or_none()

    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Withdrawal transaction not found"
        )

    return {
        "transaction": transaction.to_dict()
    }


@router.post("/callback/mpesa")
async def mpesa_callback(
    callback_data: dict,
    db: AsyncSession = Depends(get_db)
):
    """Handle M-Pesa callback (no auth required - called by M-Pesa)."""
    try:
        # Process callback data
        result = mpesa_gateway.process_callback(callback_data)

        if result.get("success"):
            # Find transaction by checkout_request_id
            checkout_request_id = result.get("checkout_request_id")
            if checkout_request_id:
                query_result = await db.execute(
                    select(Transaction).where(
                        Transaction.checkout_request_id == checkout_request_id
                    )
                )
                transaction = query_result.scalar_one_or_none()

                if transaction:
                    transaction.status = TransactionStatus.COMPLETED
                    transaction.mpesa_receipt_number = result.get("receipt_number")
                    transaction.amount_kes = result.get("amount")
                    transaction.callback_data = callback_data
                    transaction.callback_received_at = datetime.utcnow()
                    transaction.completed_at = datetime.utcnow()

                    if transaction.type == TransactionType.DEPOSIT:
                        transaction.amount_usd = mpesa_gateway.kes_to_usd(result.get("amount", 0))

                    await db.commit()

        else:
            # Handle failed transaction
            checkout_request_id = result.get("checkout_request_id")
            if checkout_request_id:
                query_result = await db.execute(
                    select(Transaction).where(
                        Transaction.checkout_request_id == checkout_request_id
                    )
                )
                transaction = query_result.scalar_one_or_none()

                if transaction:
                    transaction.status = TransactionStatus.FAILED
                    transaction.error_message = result.get("error_message")
                    transaction.callback_data = callback_data
                    transaction.callback_received_at = datetime.utcnow()
                    await db.commit()

        return {"status": "success"}

    except Exception as e:
        # Still return success to M-Pesa to prevent retries
        return {"status": "success", "error": str(e)}


@router.delete("/transaction/{transaction_id}")
async def cancel_transaction(
    transaction_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Cancel a pending transaction."""
    result = await db.execute(
        select(Transaction).where(
            and_(
                Transaction.id == transaction_id,
                Transaction.user_id == user_id
            )
        )
    )
    transaction = result.scalar_one_or_none()

    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found"
        )

    if transaction.status not in [TransactionStatus.PENDING, TransactionStatus.PROCESSING]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only cancel pending or processing transactions"
        )

    transaction.status = TransactionStatus.CANCELLED
    await db.commit()

    return {"message": "Transaction cancelled", "transaction": transaction.to_dict()}
