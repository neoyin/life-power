from typing import Optional, List
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.models.energy import EnergySnapshot, SignalFeatureDaily
from app.utils.energy_calc import calculate_energy_score


class EnergyEngine:
    @staticmethod
    def calculate_energy(signal: SignalFeatureDaily) -> EnergySnapshot:
        """
        根据信号特征计算能量分数
        """
        score, level, trend, confidence = calculate_energy_score(signal)
        
        energy_snapshot = EnergySnapshot(
            user_id=signal.user_id,
            score=score,
            level=level,
            trend=trend,
            confidence=confidence
        )
        
        return energy_snapshot
    
    @staticmethod
    def get_current_energy(db: Session, user_id: int) -> Optional[EnergySnapshot]:
        """
        获取用户当前能量状态
        """
        return db.query(EnergySnapshot).filter(
            EnergySnapshot.user_id == user_id
        ).order_by(EnergySnapshot.created_at.desc()).first()
    
    @staticmethod
    def get_energy_history(db: Session, user_id: int, days: int = 7) -> List[EnergySnapshot]:
        """
        获取用户能量历史
        """
        start_date = datetime.utcnow() - timedelta(days=days)
        return db.query(EnergySnapshot).filter(
            EnergySnapshot.user_id == user_id,
            EnergySnapshot.created_at >= start_date
        ).order_by(EnergySnapshot.created_at.desc()).all()
    
    @staticmethod
    def update_energy_from_signal(db: Session, signal: SignalFeatureDaily) -> EnergySnapshot:
        """
        根据信号更新能量状态
        """
        energy_snapshot = EnergyEngine.calculate_energy(signal)
        db.add(energy_snapshot)
        db.commit()
        db.refresh(energy_snapshot)
        return energy_snapshot
