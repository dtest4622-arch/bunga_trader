from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class SignalBase(BaseModel):
    pair: str
    direction: str  # BUY or SELL
    entry_price: Optional[float] = None
    stop_loss: Optional[float] = None
    take_profit: Optional[float] = None


class SignalCreate(SignalBase):
    group_id: str
    group_name: str
    raw_message: str


class SignalExecute(BaseModel):
    account_id: str
    auto_execute: bool = False


class SignalFilter(BaseModel):
    status: Optional[str] = None
    pair: Optional[str] = None
    direction: Optional[str] = None
    min_confidence: Optional[int] = None


class SignalResponse(BaseModel):
    id: str
    group_id: str
    group_name: str
    pair: str
    direction: str
    time_frame: Optional[str]
    entry_price: Optional[float]
    stop_loss: Optional[float]
    take_profit: Optional[float]
    take_profit_2: Optional[float]
    take_profit_3: Optional[float]
    ai_lot_size: float
    ai_stop_loss: float
    ai_take_profit: float
    risk_percent: float
    rr_ratio: Optional[float]
    confidence_score: int
    analysis: Optional[str]
    reasoning: Optional[str]
    warning: Optional[str]
    status: str
    rejection_reason: Optional[str]
    executed_at: Optional[datetime]
    trade_id: Optional[str]
    expires_at: Optional[datetime]
    created_at: datetime
    
    class Config:
        from_attributes = True
