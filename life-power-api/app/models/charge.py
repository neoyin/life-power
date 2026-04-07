from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.base import Base
from datetime import datetime


class ManualChargeRecord(Base):
    __tablename__ = "manual_charge_records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Integer, nullable=False)  # 充电量，通常为1%
    method = Column(String, nullable=False)  # breathing/manual
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationship
    user = relationship("User", back_populates="charge_records")
