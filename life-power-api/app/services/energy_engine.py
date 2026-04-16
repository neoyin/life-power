from typing import Optional, List
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.models.energy import EnergySnapshot, SignalFeatureDaily
from app.utils.energy_calc import calculate_energy_score
from app.utils.debug_utils import format_datetime, debug_datetime_list, debug_log


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
        print(debug_log(f"get_energy_history user_id={user_id}, days={days}, start={format_datetime(start_date)}"))

        results = db.query(EnergySnapshot).filter(
            EnergySnapshot.user_id == user_id,
            EnergySnapshot.created_at >= start_date
        ).order_by(EnergySnapshot.created_at.desc()).all()

        print(debug_log(f"Found {len(results)} snapshots for user_id={user_id}"))
        return results
    
    @staticmethod
    def save_snapshot(db: Session, snapshot: EnergySnapshot) -> EnergySnapshot:
        """
        保存数据时根据时间做一次聚合 (1小时一个点)
        """
        now = datetime.utcnow()
        # 获取当前小时的开始时间
        hour_start = now.replace(minute=0, second=0, microsecond=0)
        
        # 查找当前小时是否已经有记录
        existing = db.query(EnergySnapshot).filter(
            EnergySnapshot.user_id == snapshot.user_id,
            EnergySnapshot.created_at >= hour_start
        ).order_by(EnergySnapshot.created_at.desc()).first()
        
        if existing:
            # 更新已有记录
            existing.score = snapshot.score
            existing.level = snapshot.level
            existing.trend = snapshot.trend
            existing.confidence = snapshot.confidence
            existing.created_at = now # 更新时间到最新
            db.commit()
            db.refresh(existing)
            return existing
        else:
            # 插入新记录
            db.add(snapshot)
            db.commit()
            db.refresh(snapshot)
            return snapshot

    @staticmethod
    def update_energy_from_signal(db: Session, signal: SignalFeatureDaily) -> EnergySnapshot:
        """
        根据信号更新能量状态
        """
        energy_snapshot = EnergyEngine.calculate_energy(signal)
        return EnergyEngine.save_snapshot(db, energy_snapshot)
