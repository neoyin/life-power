from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.alert import AlertEvent, AlertRecipient
from app.models.user import User
from app.schemas.alert import AlertEventCreate, AlertEventUpdate
from app.services.watcher_service import WatcherService


class AlertService:
    @staticmethod
    def create_low_energy_alert(db: Session, user_id: int, energy_score: int) -> AlertEvent:
        """
        创建低电量告警
        """
        # 创建告警事件
        alert_event = AlertEvent(
            user_id=user_id,
            type="low_energy",
            status="pending",
            energy_score=energy_score,
            message=f"用户能量值过低：{energy_score}%"
        )
        db.add(alert_event)
        db.commit()
        db.refresh(alert_event)
        
        # 获取用户的守望者
        watcher_relations = WatcherService.get_watcher_relations_as_target(db, user_id)
        
        # 为每个守望者创建告警接收记录
        for relation in watcher_relations:
            alert_recipient = AlertRecipient(
                alert_id=alert_event.id,
                recipient_id=relation.watcher_id,
                status="pending"
            )
            db.add(alert_recipient)
        
        db.commit()
        
        # 更新告警状态为 triggered
        alert_event.status = "triggered"
        db.commit()
        db.refresh(alert_event)
        
        return alert_event
    
    @staticmethod
    def update_alert_status(db: Session, alert_id: int, update_data: AlertEventUpdate) -> Optional[AlertEvent]:
        """
        更新告警状态
        """
        alert = db.query(AlertEvent).filter(
            AlertEvent.id == alert_id
        ).first()
        
        if not alert:
            return None
        
        if update_data.status:
            alert.status = update_data.status
        
        if update_data.resolved_at:
            alert.resolved_at = update_data.resolved_at
        
        db.commit()
        db.refresh(alert)
        return alert
    
    @staticmethod
    def get_user_alerts(db: Session, user_id: int) -> List[AlertEvent]:
        """
        获取用户的告警事件
        """
        return db.query(AlertEvent).filter(
            AlertEvent.user_id == user_id
        ).order_by(AlertEvent.created_at.desc()).all()
    
    @staticmethod
    def get_watcher_alerts(db: Session, user_id: int) -> List[AlertEvent]:
        """
        获取用户作为守望者的告警事件
        """
        # 获取用户作为接收者的告警记录
        alert_recipients = db.query(AlertRecipient).filter(
            AlertRecipient.recipient_id == user_id
        ).all()
        
        alert_ids = [recipient.alert_id for recipient in alert_recipients]
        
        return db.query(AlertEvent).filter(
            AlertEvent.id.in_(alert_ids)
        ).order_by(AlertEvent.created_at.desc()).all()
    
    @staticmethod
    def check_low_energy_alerts(db: Session, user_id: int, energy_score: int, threshold: int = 30) -> Optional[AlertEvent]:
        """
        检查是否需要创建低电量告警
        """
        if energy_score < threshold:
            # 检查是否已有未解决的低电量告警
            existing_alert = db.query(AlertEvent).filter(
                AlertEvent.user_id == user_id,
                AlertEvent.type == "low_energy",
                AlertEvent.status.in_(["pending", "triggered", "sent"])
            ).first()
            
            if not existing_alert:
                return AlertService.create_low_energy_alert(db, user_id, energy_score)
        
        return None
