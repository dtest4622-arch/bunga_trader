import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base


class Signal(Base):
    __tablename__ = "signals"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Source Info
    group_id = Column(String(100), nullable=False, index=True)
    group_name = Column(String(255), nullable=False)
    raw_message = Column(Text, nullable=False)
    message_id = Column(String(100), nullable=True)
    
    # Signal Details
    pair = Column(String(20), nullable=False, index=True)
    direction = Column(String(10), nullable=False)  # BUY, SELL
    time_frame = Column(String(10), nullable=True)  # M1, M5, M15, H1, H4, D1
    
    # Prices (from signal provider)
    entry_price = Column(Float, nullable=True)
    stop_loss = Column(Float, nullable=True)
    take_profit = Column(Float, nullable=True)
    take_profit_2 = Column(Float, nullable=True)
    take_profit_3 = Column(Float, nullable=True)
    
    # AI Calculated Values
    ai_lot_size = Column(Float, nullable=False, default=0.01)
    ai_stop_loss = Column(Float, nullable=False)
    ai_take_profit = Column(Float, nullable=False)
    risk_percent = Column(Float, nullable=False, default=1.0)
    rr_ratio = Column(Float, nullable=True)
    
    # Analysis
    confidence_score = Column(Integer, nullable=False, default=50)  # 0-100
    analysis = Column(Text, nullable=True)
    reasoning = Column(Text, nullable=True)
    warning = Column(String(500), nullable=True)
    
    # Status
    status = Column(String(20), nullable=False, default="PENDING")  # PENDING, EXECUTED, REJECTED, EXPIRED, CLOSED
    rejection_reason = Column(String(500), nullable=True)
    
    # Execution
    executed_by = Column(String(36), ForeignKey("users.id"), nullable=True)
    executed_at = Column(DateTime, nullable=True)
    
    # Expiry
    expires_at = Column(DateTime, nullable=True)
    expired_at = Column(DateTime, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships (Trade.signal_id -> Signal.id)
    trades = relationship("Trade", back_populates="signal", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Signal(id={self.id}, pair={self.pair}, direction={self.direction})>"

    
    def __repr__(self):
        return f"<Signal(id={self.id}, pair={self.pair}, direction={self.direction})>"
    
    def to_dict(self):
        return {
            "id": self.id,
            "group_id": self.group_id,
            "group_name": self.group_name,
            "raw_message": self.raw_message,
            "pair": self.pair,
            "direction": self.direction,
            "time_frame": self.time_frame,
            "entry_price": self.entry_price,
            "stop_loss": self.stop_loss,
            "take_profit": self.take_profit,
            "take_profit_2": self.take_profit_2,
            "take_profit_3": self.take_profit_3,
            "ai_lot_size": self.ai_lot_size,
            "ai_sl": self.ai_stop_loss,
            "ai_tp": self.ai_take_profit,
            "risk_percent": self.risk_percent,
            "rr_ratio": self.rr_ratio,
            "confidence_score": self.confidence_score,
            "analysis": self.analysis,
            "reasoning": self.reasoning,
            "warning": self.warning,
            "status": self.status,
            "rejection_reason": self.rejection_reason,
            "executed_at": self.executed_at.isoformat() if self.executed_at else None,
            "trade_id": self.trade_id,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
    
    @property
    def is_pending(self):
        return self.status == "PENDING"
    
    @property
    def is_executed(self):
        return self.status == "EXECUTED"
    
    @property
    def is_expired(self):
        return self.status == "EXPIRED"
    
    @property
    def is_high_confidence(self):
        return self.confidence_score >= 75
    
    @property
    def formatted_pair(self):
        if len(self.pair) > 6:
            return self.pair
        return f"{self.pair[:3]}/{self.pair[3:]}"
