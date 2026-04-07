from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User as UserModel
from app.schemas.charge_schema import ChargeResponse
from app.services.charge_service import ChargeService

router = APIRouter(prefix="/charge", tags=["charge"])


@router.post("/manual", response_model=ChargeResponse)
def manual_charge(
    method: str = "manual",
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 执行手动充电
    response = ChargeService.manual_charge(db, current_user.id, method)
    return response


@router.get("/daily-limit")
def get_daily_charge_limit(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 获取今日充电次数
    daily_charges = ChargeService.get_daily_charges(db, current_user.id)
    return {
        "daily_charges": daily_charges,
        "remaining_charges": 3 - daily_charges
    }
