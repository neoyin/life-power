from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User as UserModel
from app.schemas.user_schema import User
from app.schemas.watcher_schema import WatcherRelation, WatcherRelationCreate, WatcherRelationUpdate, WatcherInfo
from app.services.watcher_service import WatcherService

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
    relation = db.query(WatcherRelation).filter(
        WatcherRelation.id == relation_id,
        WatcherRelation.target_id == current_user.id
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
