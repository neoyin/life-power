from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float
from sqlalchemy.orm import relationship
from app.base import Base
from datetime import datetime


class EnergySnapshot(Base):
    __tablename__ = "energy_snapshots"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    score = Column(Integer, nullable=False)  # 0-100
    level = Column(String, nullable=False)  # high/medium/low
    trend = Column(String, nullable=False)  # increasing/decreasing/stable
    confidence = Column(Float, nullable=False)  # 0.0-1.0
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationship
    user = relationship("User", back_populates="energy_snapshots")


class SignalFeatureDaily(Base):
    __tablename__ = "signal_feature_daily"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(DateTime, nullable=False)
    steps = Column(Integer, nullable=True)
    sleep_hours = Column(Float, nullable=True)
    active_minutes = Column(Integer, nullable=True)
    water_intake = Column(Integer, nullable=True)  # in ml
    mood_score = Column(Integer, nullable=True)  # 1-10
    breathing_sessions = Column(Integer, default=0) # count of breathing cycles
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    user = relationship("User", back_populates="signal_features")
