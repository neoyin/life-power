from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class AlertEventBase(BaseModel):
    type: str
    status: str
    energy_score: int
    message: str


class AlertEventCreate(AlertEventBase):
    pass


class AlertEventUpdate(BaseModel):
    status: Optional[str] = None
    resolved_at: Optional[datetime] = None


class AlertEvent(AlertEventBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class AlertRecipientBase(BaseModel):
    recipient_id: int


class AlertRecipientCreate(AlertRecipientBase):
    pass


class AlertRecipientUpdate(BaseModel):
    status: str
    sent_at: Optional[datetime] = None


class AlertRecipient(AlertRecipientBase):
    id: int
    alert_id: int
    status: str
    sent_at: Optional[datetime] = None
    created_at: datetime
    
    class Config:
        from_attributes = True
