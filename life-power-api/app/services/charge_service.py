from typing import Optional
from datetime import datetime, date
from sqlalchemy.orm import Session
from app.models.charge import ManualChargeRecord
from app.models.energy import EnergySnapshot, SignalFeatureDaily
from app.schemas.charge_schema import ChargeResponse
from app.services.energy_engine import EnergyEngine
from app.services.signal_service import SignalService
from app.schemas.energy_schema import SignalFeatureCreate


class ChargeService:
    @staticmethod
    def manual_charge(db: Session, user_id: int, method: str = "manual") -> ChargeResponse:
        """
        手动充电，每天限制3次
        通过信号系统持久化，确保能量提升不会被后续同步覆盖
        """
        # 检查今天的充电次数
        today = date.today()
        today_charges = db.query(ManualChargeRecord).filter(
            ManualChargeRecord.user_id == user_id,
            ManualChargeRecord.method == "manual",
            ManualChargeRecord.created_at >= datetime.combine(today, datetime.min.time())
        ).count()
        
        if today_charges >= 3:
            return ChargeResponse(
                message="daily_charge_limit_reached",
                current_energy=0,
                daily_charges=today_charges,
                remaining_charges=0
            )
        
        # 创建充电记录（用于每日限制追踪）
        charge_record = ManualChargeRecord(
            user_id=user_id,
            amount=1,
            method=method
        )
        db.add(charge_record)
        db.commit()
        
        # 通过信号系统更新能量（持久化，不会被覆盖）
        target_date = datetime(today.year, today.month, today.day)
        existing_signal = db.query(SignalFeatureDaily).filter(
            SignalFeatureDaily.user_id == user_id,
            SignalFeatureDaily.date == target_date
        ).first()
        
        if existing_signal:
            # 累加手动充电次数到呼吸训练（与呼吸共享正念加成）
            current_breathing = existing_signal.breathing_sessions or 0
            existing_signal.breathing_sessions = current_breathing + 1
            db.commit()
            db.refresh(existing_signal)
            # 重新计算能量
            EnergyEngine.update_energy_from_signal(db, existing_signal)
        else:
            # 创建新的信号记录
            signal_data = SignalFeatureCreate(
                date=datetime.now(),
                breathing_sessions=1
            )
            signal = SignalService.create_signal(db, user_id, signal_data)
            EnergyEngine.update_energy_from_signal(db, signal)
        
        # 获取最新能量分数
        latest_energy = db.query(EnergySnapshot).filter(
            EnergySnapshot.user_id == user_id
        ).order_by(EnergySnapshot.created_at.desc()).first()
        
        new_score = latest_energy.score if latest_energy else 0
        
        return ChargeResponse(
            message="charge_successful",
            current_energy=new_score,
            daily_charges=today_charges + 1,
            remaining_charges=3 - (today_charges + 1)
        )
    
    @staticmethod
    def get_daily_charges(db: Session, user_id: int) -> int:
        """
        获取今日充电次数
        """
        today = date.today()
        return db.query(ManualChargeRecord).filter(
            ManualChargeRecord.user_id == user_id,
            ManualChargeRecord.method == "manual",
            ManualChargeRecord.created_at >= datetime.combine(today, datetime.min.time())
        ).count()
