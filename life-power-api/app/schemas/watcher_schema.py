from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class WatcherRelationBase(BaseModel):
    target_id: int
    status: str


class WatcherRelationCreate(WatcherRelationBase):
    pass


class WatcherRelationUpdate(BaseModel):
    status: str


class WatcherRelation(WatcherRelationBase):
    id: int
    watcher_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class CareMessageBase(BaseModel):
    recipient_id: int
    content: str
    emoji_response: Optional[str] = None


class CareMessageCreate(CareMessageBase):
    pass


class CareMessageUpdate(BaseModel):
    emoji_response: str


class CareMessage(CareMessageBase):
    id: int
    sender_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class WatcherInfo(BaseModel):
    user_id: int
    username: str
    full_name: Optional[str] = None
    energy_score: int
    energy_level: str
    status: str
