from pydantic import BaseModel
from typing import Dict, Optional


class PresignedUrlRequest(BaseModel):
    content_type: str = "image/jpeg"


class PresignedUrlResponse(BaseModel):
    presigned_url: str
    public_url: str
    fields: Dict[str, str]


class AvatarUpdateRequest(BaseModel):
    avatar_url: str
