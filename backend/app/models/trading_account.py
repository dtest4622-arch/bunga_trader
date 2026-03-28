import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base


class TradingAccount(Base):
    __tablename__ = "trading_accounts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    
    # Broker Info
    broker = Column(String(50), nullable=False)  # exness, xm, hotforex, icmarkets
    account_type = Column(String(20), nullable=False, default="STANDARD")  # CENT, STANDARD, RAW, ZERO, PRO
    platform = Column(String(10), nullable=False, default="MT5")  # MT4, MT5
    
    # Account Credentials (encrypted)
    login = Column(String(50), nullable=False)
    encrypted_password = Column(String(500), nullable=False)
    server = Column(String(100), nullable=False)
    
    # Account Status
    is_active = Column(Boolean, default=True, nullable=False)
    is_demo = Column(Boolean, default=False, nullable=False)
    is_default = Column(Boolean, default=False, nullable=False)
    is_connected = Column(Boolean, default=False, nullable=False)
    
    # Trading Info
    leverage = Column(Integer, default=100, nullable=False)
    account_currency = Column(String(10), default="USD", nullable=False)
    
    # Balance Info (synced from MT5)
    balance = Column(Float, default=0.0, nullable=False)
    equity = Column(Float, default=0.0, nullable=False)
    margin = Column(Float, default=0.0, nullable=False)
    free_margin = Column(Float, default=0.0, nullable=False)
    margin_level = Column(Float, default=0.0, nullable=False)
    
    # Statistics
    total_trades = Column(Integer, default=0, nullable=False)
    winning_trades = Column(Integer, default=0, nullable=False)
    losing_trades = Column(Integer, default=0, nullable=False)
    total_profit = Column(Float, default=0.0, nullable=False)
    total_loss = Column(Float, default=0.0, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    last_synced = Column(DateTime, nullable=True)
    last_error = Column(String(500), nullable=True)
    last_error_at = Column(DateTime, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="trading_accounts")
    trades = relationship("Trade", back_populates="account", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<TradingAccount(id={self.id}, broker={self.broker}, login={self.login})>"
    
    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "broker": self.broker,
            "account_type": self.account_type,
            "platform": self.platform,
            "login": self.login,
            "server": self.server,
            "leverage": self.leverage,
            "account_currency": self.account_currency,
            "balance": self.balance,
            "equity": self.equity,
            "margin": self.margin,
            "free_margin": self.free_margin,
            "margin_level": self.margin_level,
            "is_active": self.is_active,
            "is_demo": self.is_demo,
            "is_default": self.is_default,
            "is_connected": self.is_connected,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_synced": self.last_synced.isoformat() if self.last_synced else None,
        }
    
    @property
    def display_name(self):
        return f"{self.broker.capitalize()} {self.account_type}"
    
    @property
    def win_rate(self):
        if self.total_trades == 0:
            return 0.0
        return (self.winning_trades / self.total_trades) * 100
    
    @property
    def net_profit(self):
        return self.total_profit - abs(self.total_loss)
