from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user_schema import User, UserCreate, UserAuth, LoginResponse, UserUpdate
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


@router.get("/me", response_model=User)
def get_current_user_info(current_user: UserModel = Depends(get_current_user)):
    return current_user


@router.put("/me", response_model=User)
def update_current_user_info(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    updated_user = AuthService.update_user(db, current_user.id, user_update)
    return updated_user
