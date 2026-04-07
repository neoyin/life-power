from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.watcher import CareMessage
from app.schemas.watcher_schema import CareMessageCreate, CareMessageUpdate


class CareService:
    @staticmethod
    def send_care_message(db: Session, sender_id: int, message_data: CareMessageCreate) -> CareMessage:
        """
        发送关怀消息
        """
        new_message = CareMessage(
            sender_id=sender_id,
            recipient_id=message_data.recipient_id,
            content=message_data.content
        )
        db.add(new_message)
        db.commit()
        db.refresh(new_message)
        return new_message
    
    @staticmethod
    def update_care_message(db: Session, message_id: int, update_data: CareMessageUpdate) -> Optional[CareMessage]:
        """
        更新关怀消息（添加 emoji 回复）
        """
        message = db.query(CareMessage).filter(
            CareMessage.id == message_id
        ).first()
        
        if not message:
            return None
        
        if update_data.emoji_response:
            message.emoji_response = update_data.emoji_response
        
        db.commit()
        db.refresh(message)
        return message
    
    @staticmethod
    def get_user_messages(db: Session, user_id: int) -> List[CareMessage]:
        """
        获取用户收到的消息
        """
        return db.query(CareMessage).filter(
            CareMessage.recipient_id == user_id
        ).order_by(CareMessage.created_at.desc()).all()
    
    @staticmethod
    def get_sent_messages(db: Session, user_id: int) -> List[CareMessage]:
        """
        获取用户发送的消息
        """
        return db.query(CareMessage).filter(
            CareMessage.sender_id == user_id
        ).order_by(CareMessage.created_at.desc()).all()
