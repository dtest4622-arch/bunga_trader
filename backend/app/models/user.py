import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    
    # Profile
    full_name = Column(String(255), nullable=True)
    phone_number = Column(String(20), nullable=False)
    mpesa_number = Column(String(20), nullable=False)
    avatar_url = Column(String(500), nullable=True)
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    is_kyc_verified = Column(Boolean, default=False, nullable=False)
    is_email_verified = Column(Boolean, default=False, nullable=False)
    is_phone_verified = Column(Boolean, default=False, nullable=False)
    
    # KYC
    id_document_type = Column(String(50), nullable=True)
    id_document_number = Column(String(100), nullable=True)
    id_document_url = Column(String(500), nullable=True)
    kyc_submitted_at = Column(DateTime, nullable=True)
    kyc_verified_at = Column(DateTime, nullable=True)
    
    # Security
    two_factor_enabled = Column(Boolean, default=False, nullable=False)
    two_factor_secret = Column(String(255), nullable=True)
    failed_login_attempts = Column(Integer, default=0, nullable=False)
    locked_until = Column(DateTime, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    last_login = Column(DateTime, nullable=True)
    
    # Relationships
    trading_accounts = relationship("TradingAccount", back_populates="user", cascade="all, delete-orphan")
    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    settings = relationship("UserSettings", back_populates="user", uselist=False, cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"
    
    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "full_name": self.full_name,
            "phone_number": self.phone_number,
            "mpesa_number": self.mpesa_number,
            "avatar_url": self.avatar_url,
            "is_active": self.is_active,
            "is_kyc_verified": self.is_kyc_verified,
            "is_email_verified": self.is_email_verified,
            "is_phone_verified": self.is_phone_verified,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_login": self.last_login.isoformat() if self.last_login else None,
        }


class UserSettings(Base):
    __tablename__ = "user_settings"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, unique=True)
    
    # Trading Settings
    default_risk_percent = Column(Integer, default=1, nullable=False)
    max_risk_percent = Column(Integer, default=5, nullable=False)
    auto_execute_signals = Column(Boolean, default=False, nullable=False)
    min_confidence_score = Column(Integer, default=70, nullable=False)
    
    # Compounding Settings
    compounding_enabled = Column(Boolean, default=False, nullable=False)
    daily_target_percent = Column(Integer, default=5, nullable=False)
    stop_after_daily_target = Column(Boolean, default=True, nullable=False)
    
    # Notification Settings
    push_notifications_enabled = Column(Boolean, default=True, nullable=False)
    email_notifications_enabled = Column(Boolean, default=True, nullable=False)
    signal_notifications = Column(Boolean, default=True, nullable=False)
    trade_notifications = Column(Boolean, default=True, nullable=False)
    price_alerts = Column(Boolean, default=True, nullable=False)
    
    # Security Settings
    biometric_auth_enabled = Column(Boolean, default=False, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="settings")
    
    def to_dict(self):
        return {
            "default_risk_percent": self.default_risk_percent,
            "max_risk_percent": self.max_risk_percent,
            "auto_execute_signals": self.auto_execute_signals,
            "min_confidence_score": self.min_confidence_score,
            "compounding_enabled": self.compounding_enabled,
            "daily_target_percent": self.daily_target_percent,
            "stop_after_daily_target": self.stop_after_daily_target,
            "push_notifications_enabled": self.push_notifications_enabled,
            "email_notifications_enabled": self.email_notifications_enabled,
            "signal_notifications": self.signal_notifications,
            "trade_notifications": self.trade_notifications,
            "price_alerts": self.price_alerts,
            "biometric_auth_enabled": self.biometric_auth_enabled,
        }
