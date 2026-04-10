from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.user_schema import User, UserCreate, UserAuth, LoginResponse, UserUpdate, UserSettings, UserSettingsUpdate, RefreshTokenRequest, Token
from app.services.auth_service import AuthService
from app.api.deps import get_current_user
from app.models.user import User as UserModel

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=User)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    try:
        user = AuthService.register_user(db, user_data)
        return user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/login")
def login(auth_data: UserAuth, db: Session = Depends(get_db)):
    result = AuthService.login_user(db, auth_data)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token, user = result
    return LoginResponse(
        access_token=token.access_token,
        refresh_token=token.refresh_token,
        token_type=token.token_type,
        id=user.id,
        username=user.username,
        email=user.email,
        full_name=user.full_name,
    )


@router.post("/refresh", response_model=Token)
def refresh_token(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    token = AuthService.refresh_access_token(db, request.refresh_token)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return token


@router.get("/me", response_model=User)
def get_current_user_info(current_user: UserModel = Depends(get_current_user)):
    return current_user


@router.get("/search", response_model=List[User])
def search_users(
    query: str,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    users = db.query(UserModel).filter(
        (UserModel.username.contains(query)) | (UserModel.full_name.contains(query))
    ).filter(UserModel.id != current_user.id).limit(10).all()
    return users


@router.put("/me", response_model=User)
def update_current_user_info(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    updated_user = AuthService.update_user(db, current_user.id, user_update)
    return updated_user


@router.get("/settings", response_model=UserSettings)
def get_user_settings(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    settings = AuthService.get_user_settings(db, current_user.id)
    if not settings:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User settings not found"
        )
    return settings


@router.put("/settings", response_model=UserSettings)
def update_user_settings(
    settings_update: UserSettingsUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    updated_settings = AuthService.update_user_settings(db, current_user.id, settings_update)
    if not updated_settings:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User settings not found"
        )
    return updated_settings
