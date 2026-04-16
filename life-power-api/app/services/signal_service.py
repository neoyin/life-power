from typing import Optional
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session
from app.models.energy import SignalFeatureDaily
from app.schemas.energy_schema import SignalFeatureCreate, SignalFeatureUpdate
from app.utils.debug_utils import format_datetime, debug_datetime_list, object_to_dict, debug_log


class SignalService:
    @staticmethod
    def create_signal(db: Session, user_id: int, signal_data: SignalFeatureCreate) -> SignalFeatureDaily:
        """
        创建信号特征
        """
        d = signal_data.date.date() if hasattr(signal_data.date, 'date') else signal_data.date
        target_date = datetime(d.year, d.month, d.day)
        start_of_day = target_date
        end_of_day = target_date + timedelta(days=1)

        print(debug_log(f"create_signal user_id={user_id}, target_date={format_datetime(target_date)}", signal_data.model_dump()))

        # 使用范围查询检查是否已存在当天的信号
        existing_signal = db.query(SignalFeatureDaily).filter(
            SignalFeatureDaily.user_id == user_id,
            SignalFeatureDaily.date >= start_of_day,
            SignalFeatureDaily.date < end_of_day
        ).first()

        print(debug_log(f"existing_signal found", existing_signal))

        if existing_signal:
            for key, value in signal_data.model_dump().items():
                if key != 'date' and value is not None:
                    setattr(existing_signal, key, value)
            db.commit()
            db.refresh(existing_signal)
            print(debug_log(f"Updated existing signal", existing_signal))
            return existing_signal
        else:
            print(debug_log(f"Creating new signal for user_id={user_id}"))
            signal_dict = signal_data.model_dump()
            signal_dict['date'] = target_date
            new_signal = SignalFeatureDaily(
                user_id=user_id,
                **signal_dict
            )
            db.add(new_signal)
            db.commit()
            db.refresh(new_signal)
            print(debug_log(f"Created new signal", new_signal))
            return new_signal
    
    @staticmethod
    def get_signal_by_date(db: Session, user_id: int, target_date: datetime) -> Optional[SignalFeatureDaily]:
        """
        根据日期获取信号特征
        """
        start_of_day = datetime(target_date.year, target_date.month, target_date.day)
        end_of_day = start_of_day + timedelta(days=1)

        print(debug_log(f"get_signal_by_date user_id={user_id}, target={format_datetime(target_date)}, range=[{format_datetime(start_of_day)}, {format_datetime(end_of_day)})"))

        # 先查看数据库中该用户所有记录的日期
        all_user_signals = db.query(SignalFeatureDaily.date).filter(
            SignalFeatureDaily.user_id == user_id
        ).order_by(SignalFeatureDaily.date.desc()).limit(5).all()

        dates = [s.date for s in all_user_signals]
        print(debug_log(f"Last 5 dates in DB", dates))

        result = db.query(SignalFeatureDaily).filter(
            SignalFeatureDaily.user_id == user_id,
            SignalFeatureDaily.date >= start_of_day,
            SignalFeatureDaily.date < end_of_day
        ).first()

        print(debug_log(f"Query result", result))
        return result
    
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
