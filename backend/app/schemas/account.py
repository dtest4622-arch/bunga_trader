from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class TradingAccountBase(BaseModel):
    broker: str = Field(..., min_length=1)
    account_type: str = "STANDARD"
    platform: str = "MT5"
    login: str = Field(..., min_length=1)
    server: str = Field(..., min_length=1)
    leverage: int = 100
    is_demo: bool = False


class TradingAccountCreate(TradingAccountBase):
    password: str = Field(..., min_length=1)


class TradingAccountUpdate(BaseModel):
    is_active: Optional[bool] = None
    is_default: Optional[bool] = None


class TradingAccountResponse(BaseModel):
    id: str
    user_id: str
    broker: str
    account_type: str
    platform: str
    login: str
    server: str
    leverage: int
    account_currency: str
    balance: float
    equity: float
    margin: float
    free_margin: float
    margin_level: float
    is_active: bool
    is_demo: bool
    is_default: bool
    is_connected: bool
    created_at: datetime
    last_synced: Optional[datetime]
    
    class Config:
        from_attributes = True
