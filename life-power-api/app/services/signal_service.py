from typing import Optional
from datetime import datetime, date
from sqlalchemy.orm import Session
from app.models.energy import SignalFeatureDaily
from app.schemas.energy_schema import SignalFeatureCreate, SignalFeatureUpdate


class SignalService:
    @staticmethod
    def create_signal(db: Session, user_id: int, signal_data: SignalFeatureCreate) -> SignalFeatureDaily:
        """
        创建信号特征
        """
        # 强制将日期归一化为当天零点的 naive datetime
        # signal_data.date 可能是 aware datetime, 我们取其 date 部分然后再构造一个 naive datetime
        d = signal_data.date.date() if hasattr(signal_data.date, 'date') else signal_data.date
        target_date = datetime(d.year, d.month, d.day)
        
        print(f"DEBUG: Creating/Updating signal for user {user_id} on {target_date}")
        
        # 检查是否已存在当天的信号
        existing_signal = db.query(SignalFeatureDaily).filter(
            SignalFeatureDaily.user_id == user_id,
            SignalFeatureDaily.date == target_date
        ).first()
        
        if existing_signal:
            print(f"DEBUG: Found existing signal {existing_signal.id}. Updating...")
            # 更新现有信号
            for key, value in signal_data.model_dump().items():
                if key != 'date' and value is not None:
                    print(f"DEBUG: Updating {key} to {value}")
                    setattr(existing_signal, key, value)
            db.commit()
            db.refresh(existing_signal)
            return existing_signal
        else:
            print(f"DEBUG: No existing signal found. Creating new...")
            # 创建新信号
            signal_dict = signal_data.model_dump()
            signal_dict['date'] = target_date # 使用归一化的日期
            new_signal = SignalFeatureDaily(
                user_id=user_id,
                **signal_dict
            )
            db.add(new_signal)
            db.commit()
            db.refresh(new_signal)
            return new_signal
    
    @staticmethod
    def get_signal_by_date(db: Session, user_id: int, target_date: datetime) -> Optional[SignalFeatureDaily]:
        """
        根据日期获取信号特征
        """
        # 确保 target_date 也是归一化的
        d = target_date.date() if hasattr(target_date, 'date') else target_date
        normalized_date = datetime(d.year, d.month, d.day)
        
        return db.query(SignalFeatureDaily).filter(
            SignalFeatureDaily.user_id == user_id,
            SignalFeatureDaily.date == normalized_date
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
