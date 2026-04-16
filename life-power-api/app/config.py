from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str

    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    APP_NAME: str = "LifePower API"
    DEBUG: bool = True

    R2_ACCOUNT_ID: str = ""
    R2_ACCESS_KEY_ID: str = ""
    R2_SECRET_ACCESS_KEY: str = ""
    R2_BUCKET_NAME: str = "avatars"
    R2_PUBLIC_URL: str = ""

    @property
    def r2_client(self):
        import boto3
        from botocore.config import Config
        return boto3.client(
            's3',
            endpoint_url=f"https://{self.R2_ACCOUNT_ID}.r2.cloudflarestorage.com",
            aws_access_key_id=self.R2_ACCESS_KEY_ID,
            aws_secret_access_key=self.R2_SECRET_ACCESS_KEY,
            region_name="auto",
            config=Config(signature_version='s3v4')
        )

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
