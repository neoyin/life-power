from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class SignalFeatureBase(BaseModel):
    steps: Optional[int] = None
    sleep_hours: Optional[float] = None
    active_minutes: Optional[int] = None
    water_intake: Optional[int] = None
    mood_score: Optional[int] = None


class SignalFeatureCreate(SignalFeatureBase):
    date: datetime


class SignalFeatureUpdate(SignalFeatureBase):
    date: Optional[datetime] = None


class SignalFeature(SignalFeatureBase):
    id: int
    user_id: int
    date: datetime
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class EnergySnapshotBase(BaseModel):
    score: int
    level: str
    trend: str
    confidence: float


class EnergySnapshot(EnergySnapshotBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class EnergyCurrent(EnergySnapshotBase):
    watcher_count: int


class EnergyHistory(BaseModel):
    snapshots: List[EnergySnapshot]
