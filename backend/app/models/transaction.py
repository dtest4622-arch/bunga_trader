import enum
import uuid
from datetime import datetime

from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Text, ForeignKey, Enum, JSON
from sqlalchemy.orm import relationship

from app.db.base import Base


class TransactionType(str, enum.Enum):
    DEPOSIT = "deposit"
    WITHDRAWAL = "withdrawal"


class TransactionStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    
    # Transaction Type
    type = Column(Enum(TransactionType), nullable=False)
    status = Column(Enum(TransactionStatus), default=TransactionStatus.PENDING, nullable=False)
    
    # Amounts
    amount_kes = Column(Float, nullable=True)  # For M-Pesa
    amount_usd = Column(Float, nullable=True)  # For trading account
    exchange_rate = Column(Float, nullable=True)
    
    # M-Pesa Details
    mpesa_receipt_number = Column(String(100), nullable=True, unique=True)
    phone_number = Column(String(20), nullable=True)
    checkout_request_id = Column(String(100), nullable=True, index=True)
    merchant_request_id = Column(String(100), nullable=True)
    
    # Trading Account (for withdrawals)
    trading_account_id = Column(String(36), ForeignKey("trading_accounts.id"), nullable=True)
    
    # Error/Failure Info
    error_message = Column(String(500), nullable=True)
    failure_reason = Column(String(500), nullable=True)
    
    # Metadata
    description = Column(String(255), nullable=True)
    extra_metadata = Column("metadata", JSON, nullable=True)

    # Callback Data
    callback_data = Column(JSON, nullable=True)
    callback_received_at = Column(DateTime, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    completed_at = Column(DateTime, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="transactions")
    
    def __repr__(self):
        return f"<Transaction(id={self.id}, type={self.type}, status={self.status}, amount_kes={self.amount_kes})>"
    
    def to_dict(self):
        return {
            "id": self.id,
            "type": self.type.value if self.type else None,
            "status": self.status.value if self.status else None,
            "amount_kes": self.amount_kes,
            "amount_usd": self.amount_usd,
            "exchange_rate": self.exchange_rate,
            "mpesa_receipt_number": self.mpesa_receipt_number,
            "phone_number": self.phone_number,
            "checkout_request_id": self.checkout_request_id,
            "description": self.description,
            "metadata": self.extra_metadata,
            "error_message": self.error_message,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
        }
    
    @property
    def is_pending(self):
        return self.status == TransactionStatus.PENDING
    
    @property
    def is_completed(self):
        return self.status == TransactionStatus.COMPLETED
    
    @property
    def is_failed(self):
        return self.status == TransactionStatus.FAILED
