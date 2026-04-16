from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.watcher import CareMessage
from app.schemas.watcher_schema import CareMessageCreate, CareMessageUpdate
from app.services.energy_engine import EnergyEngine


class CareService:
    @staticmethod
    def can_boost_energy_for_recipient(db: Session, sender_id: int, recipient_id: int) -> bool:
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        existing_boosted = db.query(CareMessage).filter(
            CareMessage.sender_id == sender_id,
            CareMessage.recipient_id == recipient_id,
            CareMessage.energy_boosted == True,
            CareMessage.created_at >= today_start
        ).first()
        return existing_boosted is None

    @staticmethod
    def boost_sender_energy(db: Session, sender_id: int, boost_value: int = 5) -> Optional:
        current_energy = EnergyEngine.get_current_energy(db, sender_id)
        if current_energy:
            new_score = min(current_energy.score + boost_value, 100)
            current_energy.score = new_score
            current_energy.trend = 'increasing'
            db.commit()
            db.refresh(current_energy)
            return current_energy
        return None

    @staticmethod
    def send_care_message(db: Session, sender_id: int, message_data: CareMessageCreate) -> CareMessage:
        can_boost = CareService.can_boost_energy_for_recipient(db, sender_id, message_data.recipient_id)

        new_message = CareMessage(
            sender_id=sender_id,
            recipient_id=message_data.recipient_id,
            content=message_data.content,
            energy_boosted=can_boost
        )
        db.add(new_message)
        db.commit()
        db.refresh(new_message)

        if can_boost:
            CareService.boost_sender_energy(db, sender_id, boost_value=5)

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
