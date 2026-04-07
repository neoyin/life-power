from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.base import Base
from datetime import datetime


class AlertEvent(Base):
    __tablename__ = "alert_events"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String, nullable=False)  # low_energy
    status = Column(String, nullable=False)  # pending/triggered/sent/resolved
    energy_score = Column(Integer, nullable=False)
    message = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)
    
    # Relationship
    user = relationship("User", back_populates="alert_events")
    recipients = relationship("AlertRecipient", back_populates="alert")


class AlertRecipient(Base):
    __tablename__ = "alert_recipients"
    
    id = Column(Integer, primary_key=True, index=True)
    alert_id = Column(Integer, ForeignKey("alert_events.id"), nullable=False)
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String, nullable=False)  # pending/sent/delivered
    sent_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationship
    alert = relationship("AlertEvent", back_populates="recipients")
    recipient = relationship("User")
