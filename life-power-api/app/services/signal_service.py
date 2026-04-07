from typing import Optional
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.energy import SignalFeatureDaily
from app.schemas.energy_schema import SignalFeatureCreate, SignalFeatureUpdate


class SignalService:
    @staticmethod
    def create_signal(db: Session, user_id: int, signal_data: SignalFeatureCreate) -> SignalFeatureDaily:
        """
        创建信号特征
        """
        # 检查是否已存在当天的信号
        existing_signal = db.query(SignalFeatureDaily).filter(
            SignalFeatureDaily.user_id == user_id,
            SignalFeatureDaily.date == signal_data.date
        ).first()
        
        if existing_signal:
            # 更新现有信号
            for key, value in signal_data.model_dump().items():
                if value is not None:
                    setattr(existing_signal, key, value)
            db.commit()
            db.refresh(existing_signal)
            return existing_signal
        else:
            # 创建新信号
            new_signal = SignalFeatureDaily(
                user_id=user_id,
                **signal_data.model_dump()
            )
            db.add(new_signal)
            db.commit()
            db.refresh(new_signal)
            return new_signal
    
    @staticmethod
    def get_signal_by_date(db: Session, user_id: int, date: datetime) -> Optional[SignalFeatureDaily]:
        """
        根据日期获取信号特征
        """
        return db.query(SignalFeatureDaily).filter(
            SignalFeatureDaily.user_id == user_id,
            SignalFeatureDaily.date == date
        ).first()
    
    @staticmethod
    def update_signal(db: Session, signal_id: int, signal_data: SignalFeatureUpdate) -> Optional[SignalFeatureDaily]:
        """
        更新信号特征
        """
        signal = db.query(SignalFeatureDaily).filter(
            SignalFeatureDaily.id == signal_id
        ).first()
        
        if not signal:
            return None
        
        for key, value in signal_data.model_dump().items():
            if value is not None:
                setattr(signal, key, value)
        
        db.commit()
        db.refresh(signal)
        return signal
