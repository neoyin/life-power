from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.api import auth_router, energy_router, watchers_router, care_router, charge_router
import os

app = FastAPI(
    title=settings.APP_NAME,
    debug=settings.DEBUG
)

# 配置 CORS - 允许所有本地开发服务器端口
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth_router.router)
app.include_router(energy_router.router)
app.include_router(watchers_router.router)
app.include_router(care_router.router)
app.include_router(charge_router.router)

@app.get("/")
def read_root():
    return {"message": "LifePower API is running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
