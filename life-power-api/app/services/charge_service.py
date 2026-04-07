from typing import Optional
from datetime import datetime, date
from sqlalchemy.orm import Session
from app.models.charge import ManualChargeRecord
from app.models.energy import EnergySnapshot
from app.schemas.charge_schema import ChargeResponse


class ChargeService:
    @staticmethod
    def manual_charge(db: Session, user_id: int, method: str = "manual") -> ChargeResponse:
        """
        手动充电，每天限制3次，每次+1%
        """
        # 检查今天的充电次数
        today = date.today()
        today_charges = db.query(ManualChargeRecord).filter(
            ManualChargeRecord.user_id == user_id,
            ManualChargeRecord.created_at >= datetime.combine(today, datetime.min.time())
        ).count()
        
        if today_charges >= 3:
            return ChargeResponse(
                message="Daily charge limit reached (3 times)",
                current_energy=0,
                daily_charges=today_charges,
                remaining_charges=0
            )
        
        # 获取当前能量状态
        current_energy = db.query(EnergySnapshot).filter(
            EnergySnapshot.user_id == user_id
        ).order_by(EnergySnapshot.created_at.desc()).first()
        
        if not current_energy:
            return ChargeResponse(
                message="No energy data found",
                current_energy=0,
                daily_charges=today_charges,
                remaining_charges=3 - today_charges
            )
        
        # 计算新的能量值
        new_score = min(current_energy.score + 1, 100)
        
        # 创建充电记录
        charge_record = ManualChargeRecord(
            user_id=user_id,
            amount=1,
            method=method
        )
        db.add(charge_record)
        
        # 创建新的能量快照
        new_energy = EnergySnapshot(
            user_id=user_id,
            score=new_score,
            level=current_energy.level,
            trend="increasing",
            confidence=current_energy.confidence
        )
        # 更新等级
        if new_score >= 70:
            new_energy.level = "high"
        elif new_score >= 40:
            new_energy.level = "medium"
        else:
            new_energy.level = "low"
        
        db.add(new_energy)
        db.commit()
        
        return ChargeResponse(
            message="Charge successful",
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
            ManualChargeRecord.created_at >= datetime.combine(today, datetime.min.time())
        ).count()
