from typing import Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User as UserModel
from app.models.watcher import WatcherRelation
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
    signal = SignalService.create_signal(db, current_user.id, signal_data)
    EnergyEngine.update_energy_from_signal(db, signal)
    return signal


@router.get("/signals/daily", response_model=Optional[SignalFeature])
def get_daily_signal(
    date: Optional[datetime] = None,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if date is None:
        date = datetime.utcnow()
    target_date = datetime(date.year, date.month, date.day)
    signal = SignalService.get_signal_by_date(db, current_user.id, target_date)
    return signal


@router.get("/current", response_model=Optional[EnergyCurrent])
def get_current_energy(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    energy = EnergyEngine.get_current_energy(db, current_user.id)

    if not energy:
        return None

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
    user_id: Optional[int] = None,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if user_id is None:
        target_user_id = current_user.id
    else:
        target_user_id = user_id
        if target_user_id != current_user.id:
            watching_relation = db.query(WatcherRelation).filter(
                WatcherRelation.watcher_id == current_user.id,
                WatcherRelation.target_id == target_user_id
            ).first()

            watched_by_relation = db.query(WatcherRelation).filter(
                WatcherRelation.watcher_id == target_user_id,
                WatcherRelation.target_id == current_user.id
            ).first()

            if not watching_relation or not watched_by_relation:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You can only view energy history of mutual watchers"
                )

    snapshots = EnergyEngine.get_energy_history(db, target_user_id, days)
    return EnergyHistory(snapshots=snapshots)
