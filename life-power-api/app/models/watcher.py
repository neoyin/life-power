from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Text
from sqlalchemy.orm import relationship
from app.base import Base
from datetime import datetime


class WatcherRelation(Base):
    __tablename__ = "watcher_relations"
    
    id = Column(Integer, primary_key=True, index=True)
    watcher_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    target_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String, nullable=False)  # pending/accepted/rejected
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    watcher = relationship("User", foreign_keys=[watcher_id], back_populates="watcher_relations_as_watcher")
    target = relationship("User", foreign_keys=[target_id], back_populates="watcher_relations_as_target")


class CareMessage(Base):
    __tablename__ = "care_messages"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    emoji_response = Column(String, nullable=True)
    energy_boosted = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    sender = relationship("User", foreign_keys=[sender_id])
    recipient = relationship("User", foreign_keys=[recipient_id])
