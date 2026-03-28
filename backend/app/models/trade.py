import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.db.base import Base


class Trade(Base):
    __tablename__ = "trades"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Relations
    signal_id = Column(String(36), ForeignKey("signals.id"), nullable=True, index=True)
    account_id = Column(String(36), ForeignKey("trading_accounts.id"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    
    # Broker Info
    broker_ticket = Column(Integer, nullable=False, unique=True)
    
    # Trade Details
    pair = Column(String(20), nullable=False, index=True)
    direction = Column(String(10), nullable=False)  # BUY, SELL
    
    # Position Size
    lot_size = Column(Float, nullable=False)
    
    # Prices
    entry_price = Column(Float, nullable=False)
    stop_loss = Column(Float, nullable=False)
    take_profit = Column(Float, nullable=False)
    take_profit_2 = Column(Float, nullable=True)
    take_profit_3 = Column(Float, nullable=True)
    
    # Original values (for tracking modifications)
    original_sl = Column(Float, nullable=True)
    original_tp = Column(Float, nullable=True)
    
    # Current Status
    current_price = Column(Float, nullable=True)
    floating_pnl = Column(Float, default=0.0, nullable=False)
    
    # Status
    status = Column(String(20), nullable=False, default="OPEN")  # OPEN, CLOSED, MODIFIED
    
    # Close Details
    closed_price = Column(Float, nullable=True)
    final_pnl = Column(Float, nullable=True)
    close_reason = Column(String(50), nullable=True)  # TP, SL, MANUAL, PARTIAL, EXPIRED
    
    # Partial Closes
    partial_closes = Column(JSON, nullable=True, default=list)
    
    # Costs
    commission = Column(Float, default=0.0, nullable=False)
    swap = Column(Float, default=0.0, nullable=False)
    
    # Additional Info
    comment = Column(String(255), nullable=True)
    magic_number = Column(Integer, nullable=True)
    
    # Timestamps
    opened_at = Column(DateTime, nullable=False)
    closed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    signal = relationship("Signal", back_populates="trades")
    account = relationship("TradingAccount", back_populates="trades")
    
    def __repr__(self):
        return f"<Trade(id={self.id}, pair={self.pair}, direction={self.direction}, status={self.status})>"
    
    def to_dict(self):
        return {
            "id": self.id,
            "signal_id": self.signal_id,
            "account_id": self.account_id,
            "broker_ticket": self.broker_ticket,
            "pair": self.pair,
            "direction": self.direction,
            "lot_size": self.lot_size,
            "entry_price": self.entry_price,
            "stop_loss": self.stop_loss,
            "take_profit": self.take_profit,
            "take_profit_2": self.take_profit_2,
            "take_profit_3": self.take_profit_3,
            "original_sl": self.original_sl,
            "original_tp": self.original_tp,
            "current_price": self.current_price,
            "floating_pnl": self.floating_pnl,
            "status": self.status,
            "closed_price": self.closed_price,
            "final_pnl": self.final_pnl,
            "close_reason": self.close_reason,
            "partial_closes": self.partial_closes,
            "commission": self.commission,
            "swap": self.swap,
            "comment": self.comment,
            "opened_at": self.opened_at.isoformat() if self.opened_at else None,
            "closed_at": self.closed_at.isoformat() if self.closed_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
    
    @property
    def is_open(self):
        return self.status == "OPEN"
    
    @property
    def is_closed(self):
        return self.status == "CLOSED"
    
    @property
    def is_profit(self):
        if self.is_open:
            return self.floating_pnl > 0
        return (self.final_pnl or 0) > 0
    
    @property
    def is_loss(self):
        if self.is_open:
            return self.floating_pnl < 0
        return (self.final_pnl or 0) < 0
    
    @property
    def total_cost(self):
        return self.commission + self.swap
    
    @property
    def net_pnl(self):
        if self.is_open:
            return self.floating_pnl - self.total_cost
        return (self.final_pnl or 0) - self.total_cost
    
    @property
    def duration(self):
        end_time = self.closed_at or datetime.utcnow()
        return end_time - self.opened_at
    
    @property
    def formatted_pair(self):
        if len(self.pair) > 6:
            return self.pair
        return f"{self.pair[:3]}/{self.pair[3:]}"
    
    @property
    def pips_distance(self):
        if self.current_price is None:
            return 0.0
        if self.direction == "BUY":
            return self.current_price - self.entry_price
        return self.entry_price - self.current_price
    
    @property
    def progress_to_tp(self):
        if self.current_price is None:
            return 0.0
        total_distance = abs(self.take_profit - self.entry_price)
        if total_distance == 0:
            return 0.0
        current_distance = abs(self.current_price - self.entry_price)
        return min(current_distance / total_distance, 1.0)
