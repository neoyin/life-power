# 导入所有模型以确保 SQLAlchemy 正确注册
from app.models.user import User, UserAuthIdentity, UserSettings
from app.models.energy import EnergySnapshot, SignalFeatureDaily
from app.models.watcher import WatcherRelation, CareMessage
from app.models.charge import ManualChargeRecord
from app.models.alert import AlertEvent, AlertRecipient

