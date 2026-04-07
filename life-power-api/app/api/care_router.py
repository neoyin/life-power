from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User as UserModel
from app.models.watcher import CareMessage as CareMessageModel
from app.schemas.watcher_schema import CareMessage, CareMessageCreate, CareMessageUpdate
from app.services.care_service import CareService

router = APIRouter(prefix="/care", tags=["care"])


@router.post("/messages", response_model=CareMessage)
def send_care_message(
    message_data: CareMessageCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 发送关怀消息
    message = CareService.send_care_message(db, current_user.id, message_data)
    return message


@router.put("/messages/{message_id}", response_model=CareMessage)
def update_care_message(
    message_id: int,
    update_data: CareMessageUpdate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 检查消息是否存在且是发给当前用户的
    message = db.query(CareMessageModel).filter(
        CareMessageModel.id == message_id,
        CareMessageModel.recipient_id == current_user.id
    ).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    # 更新消息
    updated_message = CareService.update_care_message(db, message_id, update_data)
    return updated_message


@router.get("/messages", response_model=List[CareMessage])
def get_care_messages(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 获取用户收到的消息
    messages = CareService.get_user_messages(db, current_user.id)
    return messages


@router.get("/messages/sent", response_model=List[CareMessage])
def get_sent_messages(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 获取用户发送的消息
    messages = CareService.get_sent_messages(db, current_user.id)
    return messages
