from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.base import Base
from datetime import datetime


class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    full_name = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    auth_identities = relationship("UserAuthIdentity", back_populates="user")
    settings = relationship("UserSettings", back_populates="user", uselist=False)
    energy_snapshots = relationship("EnergySnapshot", back_populates="user")
    signal_features = relationship("SignalFeatureDaily", back_populates="user")
    watcher_relations_as_watcher = relationship("WatcherRelation", foreign_keys="WatcherRelation.watcher_id", back_populates="watcher")
    watcher_relations_as_target = relationship("WatcherRelation", foreign_keys="WatcherRelation.target_id", back_populates="target")
    alert_events = relationship("AlertEvent", back_populates="user")
    charge_records = relationship("ManualChargeRecord", back_populates="user")


class UserAuthIdentity(Base):
    __tablename__ = "user_auth_identities"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider = Column(String, nullable=False)  # e.g., "email", "google", "apple"
    provider_id = Column(String, nullable=False)
    password_hash = Column(String, nullable=True)  # Only for email provider
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationship
    user = relationship("User", back_populates="auth_identities")


class UserSettings(Base):
    __tablename__ = "user_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    low_energy_threshold = Column(Integer, default=30)  # Default 30%
    enable_notifications = Column(Boolean, default=True)
    share_energy_data = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    user = relationship("User", back_populates="settings")
