from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User as UserModel
from app.models.watcher import WatcherRelation as WatcherRelationModel, CareMessage
from app.schemas.user_schema import User
from app.schemas.watcher_schema import WatcherRelation, WatcherRelationCreate, WatcherRelationUpdate, WatcherInfo, UserDetailResponse, CareStats
from app.services.watcher_service import WatcherService
from app.services.energy_engine import EnergyEngine
from datetime import datetime

router = APIRouter(prefix="/watchers", tags=["watchers"])


@router.post("/invite", response_model=WatcherRelation)
def invite_watcher(
    watcher_data: WatcherRelationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 创建守望者关系
    relation = WatcherService.create_watcher_relation(db, current_user.id, watcher_data.target_id)
    return relation


@router.put("/response/{relation_id}", response_model=WatcherRelation)
def respond_to_watcher_request(
    relation_id: int,
    response_data: WatcherRelationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 获取关系
    relation = db.query(WatcherRelationModel).filter(
        WatcherRelationModel.id == relation_id,
        WatcherRelationModel.target_id == current_user.id
    ).first()
    
    if not relation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Watcher relation not found"
        )
    
    # 更新关系状态
    updated_relation = WatcherService.update_watcher_relation(db, relation_id, response_data)
    return updated_relation


@router.get("/my-watchers", response_model=List[User])
def get_my_watchers(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 获取守望我的人
    relations = WatcherService.get_watcher_relations_as_target(db, current_user.id)
    watchers = []
    for relation in relations:
        watcher = db.query(UserModel).filter(UserModel.id == relation.watcher_id).first()
        if watcher:
            # 转换为 Pydantic 模式
            watchers.append(User.model_validate(watcher))
    return watchers


@router.get("/watching", response_model=List[WatcherInfo])
def get_watching(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 获取我守望的人
    watcher_infos = WatcherService.get_watcher_info(db, current_user.id)
    return watcher_infos


@router.get("/pending", response_model=List[WatcherRelation])
def get_pending_requests(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 获取待处理的守望请求
    pending_relations = WatcherService.get_pending_relations(db, current_user.id)
    return pending_relations


@router.get("/user/{user_id}", response_model=UserDetailResponse)
def get_user_detail(
    user_id: int,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    获取用户详情，包括用户信息、能量状态、关系状态和关怀统计
    """
    # 获取目标用户
    target_user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # 获取能量状态
    energy = EnergyEngine.get_current_energy(db, user_id)
    
    # 获取关系状态
    relation_status = "none"
    relation_id = None
    relation_created_at = None
    
    # 检查是否互相关注
    watching_relation = db.query(WatcherRelationModel).filter(
        WatcherRelationModel.watcher_id == current_user.id,
        WatcherRelationModel.target_id == user_id
    ).first()

    watched_by_relation = db.query(WatcherRelationModel).filter(
        WatcherRelationModel.watcher_id == user_id,
        WatcherRelationModel.target_id == current_user.id
    ).first()
    
    if watching_relation and watched_by_relation:
        relation_status = "mutual"
        relation_id = watching_relation.id
        relation_created_at = watching_relation.created_at
    elif watching_relation:
        relation_status = watching_relation.status  # "pending" or "accepted"
        relation_id = watching_relation.id
        relation_created_at = watching_relation.created_at
    elif watched_by_relation:
        relation_status = "watching"  # 对方在关注我
    else:
        relation_status = "none"
    
    # 获取关怀统计
    sent_count = db.query(CareMessage).filter(
        CareMessage.sender_id == current_user.id,
        CareMessage.recipient_id == user_id
    ).count()
    
    received_count = db.query(CareMessage).filter(
        CareMessage.sender_id == user_id,
        CareMessage.recipient_id == current_user.id
    ).count()
    
    # 计算追踪天数
    days_tracking = 0
    if relation_created_at:
        days_tracking = (datetime.now() - relation_created_at).days + 1
    elif relation_created_at is not None:
        days_tracking = (datetime.now() - relation_created_at).days + 1
    
    return UserDetailResponse(
        user_id=target_user.id,
        username=target_user.username,
        full_name=target_user.full_name,
        avatar_url=target_user.avatar_url,
        energy_score=energy.score if energy else 50,
        energy_level=energy.level if energy else "medium",
        relation_status=relation_status,
        relation_id=relation_id,
        relation_created_at=relation_created_at,
        care_stats=CareStats(sent_count=sent_count, received_count=received_count),
        days_tracking=days_tracking
    )
