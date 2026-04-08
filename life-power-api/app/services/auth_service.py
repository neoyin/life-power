from typing import Optional
from sqlalchemy.orm import Session
from app.models.user import User, UserAuthIdentity, UserSettings
from app.schemas.user_schema import UserCreate, UserAuth, Token, UserUpdate, UserSettingsUpdate
from app.utils.security import verify_password, get_password_hash, create_access_token, create_refresh_token


class AuthService:
    @staticmethod
    def register_user(db: Session, user_data: UserCreate) -> User:
        # 检查用户是否已存在
        existing_user = db.query(User).filter(
            (User.email == user_data.email) | (User.username == user_data.username)
        ).first()
        
        if existing_user:
            raise ValueError("User already exists")
        
        # 创建新用户
        new_user = User(
            username=user_data.username,
            email=user_data.email,
            full_name=user_data.full_name
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        # 创建认证身份
        auth_identity = UserAuthIdentity(
            user_id=new_user.id,
            provider="email",
            provider_id=user_data.email,
            password_hash=get_password_hash(user_data.password)
        )
        db.add(auth_identity)
        
        # 创建用户设置
        user_settings = UserSettings(user_id=new_user.id)
        db.add(user_settings)
        
        db.commit()
        return new_user
    
    @staticmethod
    def login_user(db: Session, auth_data: UserAuth) -> Optional[tuple]:
        # 查找用户
        auth_identity = db.query(UserAuthIdentity).filter(
            UserAuthIdentity.provider == "email",
            UserAuthIdentity.provider_id == auth_data.email
        ).first()
        
        if not auth_identity or not verify_password(auth_data.password, auth_identity.password_hash):
            return None
        
        # 获取用户
        user = db.query(User).filter(User.id == auth_identity.user_id).first()
        
        # 创建令牌
        access_token = create_access_token(data={"sub": str(auth_identity.user_id)})
        refresh_token = create_refresh_token(data={"sub": str(auth_identity.user_id)})
        
        token = Token(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer"
        )
        
        return (token, user)
    
    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
        return db.query(User).filter(User.id == user_id).first()
    
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> Optional[User]:
        auth_identity = db.query(UserAuthIdentity).filter(
            UserAuthIdentity.provider == "email",
            UserAuthIdentity.provider_id == email
        ).first()
        
        if not auth_identity:
            return None
        
        return auth_identity.user

    @staticmethod
    def update_user(db: Session, user_id: int, user_update: UserUpdate) -> Optional[User]:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return None
        
        if user_update.full_name is not None:
            user.full_name = user_update.full_name
        if user_update.avatar_url is not None:
            user.avatar_url = user_update.avatar_url
        
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def get_user_settings(db: Session, user_id: int) -> Optional[UserSettings]:
        return db.query(UserSettings).filter(UserSettings.user_id == user_id).first()

    @staticmethod
    def update_user_settings(db: Session, user_id: int, settings_update: UserSettingsUpdate) -> Optional[UserSettings]:
        settings = db.query(UserSettings).filter(UserSettings.user_id == user_id).first()
        if not settings:
            return None
        
        if settings_update.low_energy_threshold is not None:
            settings.low_energy_threshold = settings_update.low_energy_threshold
        if settings_update.enable_notifications is not None:
            settings.enable_notifications = settings_update.enable_notifications
        if settings_update.share_energy_data is not None:
            settings.share_energy_data = settings_update.share_energy_data
        
        db.commit()
        db.refresh(settings)
        return settings
