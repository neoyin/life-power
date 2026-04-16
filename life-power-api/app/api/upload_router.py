import logging
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User as UserModel
from app.schemas.upload_schema import PresignedUrlRequest, PresignedUrlResponse
from app.services.upload_service import UploadService
import uuid

router = APIRouter(prefix="/upload", tags=["upload"])
logger = logging.getLogger(__name__)


@router.post("/avatar/presigned-url", response_model=PresignedUrlResponse)
def get_avatar_upload_url(
    request: PresignedUrlRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if request.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid content type. Allowed: image/jpeg, image/png, image/webp"
        )

    file_extension = request.content_type.split('/')[-1]
    filename = f"avatar/{current_user.id}/{uuid.uuid4()}.{file_extension}"

    try:
        presigned_url, public_url = UploadService.generate_presigned_put_url(
            filename=filename,
            content_type=request.content_type,
            max_size_mb=5
        )

        return PresignedUrlResponse(
            presigned_url=presigned_url,
            public_url=public_url,
            fields={}
        )
    except Exception as e:
        logger.error(f"Failed to generate presigned URL: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate upload URL: {str(e)}"
        )


@router.post("/avatar/direct-upload", response_model=dict)
async def upload_avatar_direct(
    file: UploadFile = File(...),
    current_user: UserModel = Depends(get_current_user),
):
    """直接上传头像到 R2（后端中转方式，解决浏览器证书问题）"""
    if file.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid content type"
        )

    content = await file.read()

    file_extension = file.content_type.split('/')[-1]
    filename = f"avatar/{current_user.id}/{uuid.uuid4()}.{file_extension}"

    try:
        public_url = UploadService.upload_file(
            filename=filename,
            content=content,
            content_type=file.content_type
        )

        return {"public_url": public_url}
    except Exception as e:
        logger.error(f"Direct upload failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Upload failed: {str(e)}"
        )
