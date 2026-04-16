from app.config import settings
from botocore.exceptions import ClientError, NoCredentialsError
from typing import Tuple, Optional
import logging

logger = logging.getLogger(__name__)


class UploadService:
    @staticmethod
    def _is_r2_configured() -> bool:
        """检查 R2 是否正确配置"""
        return bool(
            settings.R2_ACCOUNT_ID and
            settings.R2_ACCESS_KEY_ID and
            settings.R2_SECRET_ACCESS_KEY and
            settings.R2_BUCKET_NAME
        )

    @staticmethod
    def generate_presigned_put_url(
        filename: str,
        content_type: str,
        max_size_mb: int = 5
    ) -> Tuple[str, str]:
        """生成预签名 PUT URL（兼容 Web CORS）"""
        if not UploadService._is_r2_configured():
            raise ValueError("R2 is not configured")

        import boto3
        from botocore.config import Config

        r2_endpoint = f"https://{settings.R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

        s3_client = boto3.client(
            's3',
            endpoint_url=r2_endpoint,
            aws_access_key_id=settings.R2_ACCESS_KEY_ID,
            aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
            region_name="auto",
            config=Config(signature_version='s3v4')
        )

        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': settings.R2_BUCKET_NAME,
                'Key': filename,
                'ContentType': content_type,
            },
            ExpiresIn=300
        )

        public_url = f"{settings.R2_PUBLIC_URL}/{filename}"
        return presigned_url, public_url

    @staticmethod
    def upload_file(filename: str, content: bytes, content_type: str) -> str:
        """后端直接上传文件到 R2（绕过浏览器证书问题）"""
        if not UploadService._is_r2_configured():
            raise ValueError("R2 is not configured")

        client = settings.r2_client

        try:
            client.put_object(
                Bucket=settings.R2_BUCKET_NAME,
                Key=filename,
                Body=content,
                ContentType=content_type,
                ACL='public-read',
            )
        except Exception as e:
            logger.error(f"Upload to R2 failed: {e}")
            raise

        public_url = f"{settings.R2_PUBLIC_URL}/{filename}"
        return public_url

    @staticmethod
    def delete_file(filename: str) -> bool:
        client = settings.r2_client
        try:
            client.delete_object(Bucket=settings.R2_BUCKET_NAME, Key=filename)
            return True
        except ClientError:
            return False

    @staticmethod
    def extract_key_from_url(url: str) -> Optional[str]:
        if settings.R2_PUBLIC_URL and url.startswith(settings.R2_PUBLIC_URL):
            return url[len(settings.R2_PUBLIC_URL) + 1:]
        return None
