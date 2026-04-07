from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.watcher import WatcherRelation
from app.models.user import User
from app.schemas.watcher_schema import WatcherRelationCreate, WatcherRelationUpdate, WatcherInfo
from app.services.energy_engine import EnergyEngine


class WatcherService:
    @staticmethod
    def create_watcher_relation(db: Session, watcher_id: int, target_id: int) -> WatcherRelation:
        """
        创建守望者关系
        """
        # 检查关系是否已存在
        existing_relation = db.query(WatcherRelation).filter(
            WatcherRelation.watcher_id == watcher_id,
            WatcherRelation.target_id == target_id
        ).first()
        
        if existing_relation:
            return existing_relation
        
        # 创建新关系
        new_relation = WatcherRelation(
            watcher_id=watcher_id,
            target_id=target_id,
            status="pending"
        )
        db.add(new_relation)
        db.commit()
        db.refresh(new_relation)
        return new_relation
    
    @staticmethod
    def update_watcher_relation(db: Session, relation_id: int, update_data: WatcherRelationUpdate) -> Optional[WatcherRelation]:
        """
        更新守望者关系状态
        """
        relation = db.query(WatcherRelation).filter(
            WatcherRelation.id == relation_id
        ).first()
        
        if not relation:
            return None
        
        relation.status = update_data.status
        db.commit()
        db.refresh(relation)
        return relation
    
    @staticmethod
    def get_watcher_relations_as_watcher(db: Session, user_id: int) -> List[WatcherRelation]:
        """
        获取用户作为守望者的关系
        """
        return db.query(WatcherRelation).filter(
            WatcherRelation.watcher_id == user_id,
            WatcherRelation.status == "accepted"
        ).all()
    
    @staticmethod
    def get_watcher_relations_as_target(db: Session, user_id: int) -> List[WatcherRelation]:
        """
        获取用户作为被守望者的关系
        """
        return db.query(WatcherRelation).filter(
            WatcherRelation.target_id == user_id,
            WatcherRelation.status == "accepted"
        ).all()
    
    @staticmethod
    def get_pending_relations(db: Session, user_id: int) -> List[WatcherRelation]:
        """
        获取待处理的守望请求
        """
        return db.query(WatcherRelation).filter(
            WatcherRelation.target_id == user_id,
            WatcherRelation.status == "pending"
        ).all()
    
    @staticmethod
    def get_watcher_info(db: Session, user_id: int) -> List[WatcherInfo]:
        """
        获取守望者信息，包括能量带
        """
        # 获取用户作为守望者的关系
        relations = WatcherService.get_watcher_relations_as_watcher(db, user_id)
        
        watcher_infos = []
        for relation in relations:
            # 获取目标用户信息
            target = db.query(User).filter(User.id == relation.target_id).first()
            if target:
                # 获取目标用户的能量状态
                energy = EnergyEngine.get_current_energy(db, target.id)
                energy_band = energy.level if energy else "medium"
                
                watcher_info = WatcherInfo(
                    user_id=target.id,
                    username=target.username,
                    full_name=target.full_name,
                    energy_score=energy.score if energy else 50,
                    energy_level=energy.level if energy else "medium",
                    status=relation.status
                )
                watcher_infos.append(watcher_info)
        
        return watcher_infos
