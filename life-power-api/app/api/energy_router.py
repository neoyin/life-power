from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User as UserModel
from app.schemas.energy_schema import SignalFeature, SignalFeatureCreate, EnergyCurrent, EnergyHistory
from app.services.signal_service import SignalService
from app.services.energy_engine import EnergyEngine

router = APIRouter(prefix="/energy", tags=["energy"])


@router.post("/signals/daily", response_model=SignalFeature)
def create_daily_signal(
    signal_data: SignalFeatureCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 创建信号特征
    signal = SignalService.create_signal(db, current_user.id, signal_data)
    
    # 更新能量状态
    EnergyEngine.update_energy_from_signal(db, signal)
    
    return signal


@router.get("/current", response_model=EnergyCurrent)
def get_current_energy(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 获取当前能量状态
    energy = EnergyEngine.get_current_energy(db, current_user.id)
    
    if not energy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No energy data found"
        )
    
    # 计算守望者数量
    watcher_count = len(current_user.watcher_relations_as_target)
    
    return EnergyCurrent(
        score=energy.score,
        level=energy.level,
        trend=energy.trend,
        confidence=energy.confidence,
        watcher_count=watcher_count
    )


@router.get("/history", response_model=EnergyHistory)
def get_energy_history(
    days: int = 7,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 获取能量历史
    snapshots = EnergyEngine.get_energy_history(db, current_user.id, days)
    
    return EnergyHistory(snapshots=snapshots)
