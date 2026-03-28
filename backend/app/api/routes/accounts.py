from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from cryptography.fernet import Fernet

from app.db.base import get_db
from app.core.security import get_current_user_id
from app.core.config import settings
from app.models.trading_account import TradingAccount
from app.schemas.account import (
    TradingAccountCreate,
    TradingAccountResponse,
    TradingAccountUpdate
)
from app.services.mt5_bridge import mt5_bridge

router = APIRouter()

# Encryption key for passwords (should be stored securely in production)
encryption_key = Fernet.generate_key()
cipher_suite = Fernet(encryption_key)


@router.get("", response_model=List[TradingAccountResponse])
async def get_accounts(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get all trading accounts for current user."""
    result = await db.execute(
        select(TradingAccount).where(TradingAccount.user_id == user_id)
    )
    accounts = result.scalars().all()
    return [account.to_dict() for account in accounts]


@router.post("/connect", response_model=TradingAccountResponse)
async def connect_account(
    account_data: TradingAccountCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Connect a new trading account."""
    # Check if account already exists
    result = await db.execute(
        select(TradingAccount).where(
            and_(
                TradingAccount.user_id == user_id,
                TradingAccount.login == account_data.login,
                TradingAccount.broker == account_data.broker
            )
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Account already connected"
        )
    
    # Encrypt password
    encrypted_password = cipher_suite.encrypt(account_data.password.encode()).decode()
    
    # Create account
    account = TradingAccount(
        user_id=user_id,
        broker=account_data.broker,
        account_type=account_data.account_type,
        platform=account_data.platform,
        login=account_data.login,
        encrypted_password=encrypted_password,
        server=account_data.server,
        leverage=account_data.leverage,
        is_demo=account_data.is_demo,
    )
    
    # Try to connect and sync
    try:
        # Test connection
        mt5_result = await mt5_bridge.get_account_info()
        if mt5_result.get('success'):
            account.balance = mt5_result.get('balance', 0)
            account.equity = mt5_result.get('equity', 0)
            account.margin = mt5_result.get('margin', 0)
            account.free_margin = mt5_result.get('free_margin', 0)
            account.margin_level = mt5_result.get('margin_level', 0)
            account.is_connected = True
            account.last_synced = datetime.utcnow()
    except Exception as e:
        # Account created but not connected
        account.last_error = str(e)
    
    db.add(account)
    await db.commit()
    await db.refresh(account)
    
    return account.to_dict()


@router.get("/{account_id}", response_model=TradingAccountResponse)
async def get_account(
    account_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific trading account."""
    result = await db.execute(
        select(TradingAccount).where(
            and_(
                TradingAccount.id == account_id,
                TradingAccount.user_id == user_id
            )
        )
    )
    account = result.scalar_one_or_none()
    
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )
    
    return account.to_dict()


@router.post("/{account_id}/sync", response_model=TradingAccountResponse)
async def sync_account(
    account_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Sync account data from MT5."""
    result = await db.execute(
        select(TradingAccount).where(
            and_(
                TradingAccount.id == account_id,
                TradingAccount.user_id == user_id
            )
        )
    )
    account = result.scalar_one_or_none()
    
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )
    
    try:
        mt5_result = await mt5_bridge.get_account_info()
        if mt5_result.get('success'):
            account.balance = mt5_result.get('balance', 0)
            account.equity = mt5_result.get('equity', 0)
            account.margin = mt5_result.get('margin', 0)
            account.free_margin = mt5_result.get('free_margin', 0)
            account.margin_level = mt5_result.get('margin_level', 0)
            account.is_connected = True
            account.last_synced = datetime.utcnow()
            account.last_error = None
        else:
            account.is_connected = False
            account.last_error = mt5_result.get('error')
    except Exception as e:
        account.is_connected = False
        account.last_error = str(e)
    
    await db.commit()
    await db.refresh(account)
    
    return account.to_dict()


@router.post("/{account_id}/default")
async def set_default_account(
    account_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Set account as default."""
    # Remove default from all accounts
    await db.execute(
        select(TradingAccount).where(TradingAccount.user_id == user_id)
    )
    
    result = await db.execute(
        select(TradingAccount).where(
            and_(
                TradingAccount.id == account_id,
                TradingAccount.user_id == user_id
            )
        )
    )
    account = result.scalar_one_or_none()
    
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )
    
    # Set as default
    account.is_default = True
    await db.commit()
    
    return {"message": "Account set as default"}


@router.delete("/{account_id}")
async def disconnect_account(
    account_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Disconnect and delete a trading account."""
    result = await db.execute(
        select(TradingAccount).where(
            and_(
                TradingAccount.id == account_id,
                TradingAccount.user_id == user_id
            )
        )
    )
    account = result.scalar_one_or_none()
    
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )
    
    await db.delete(account)
    await db.commit()
    
    return {"message": "Account disconnected"}
