你是一名资深全栈架构师 + 技术负责人，请基于以下产品、API和数据结构规范，设计并实现一个完整可运行的 MVP 应用。

技术要求：
- 后端：Python（FastAPI + PostgreSQL + SQLAlchemy）
- 前端：Flutter（支持 iOS / Android）
- 架构：清晰分层、可扩展、生产级代码结构
- 输出：完整代码结构 + 核心代码 + 可运行说明

目标产品：LifePower（守望电量）
核心理念：通过“电量”量化用户状态，在低电量时触发守望者关怀机制

【后端技术栈 Python】
目录 lifeix-power-api/
├── app/
│   ├── main.py                 # FastAPI入口
│   ├── config.py               # 配置管理
│   ├── database.py             # DB连接+Session
│   ├── models/                 # SQLAlchemy模型
│   │   ├── user.py            # User, UserAuthIdentity, UserSettings
│   │   ├── energy.py          # EnergySnapshot, SignalFeatureDaily
│   │   ├── watcher.py         # WatcherRelation, CareMessage
│   │   ├── alert.py           # AlertEvent, AlertRecipient
│   │   └── charge.py          # ManualChargeRecord
│   ├── schemas/               # Pydantic请求/响应模型
│   ├── services/              # 核心业务逻辑层
│   │   ├── auth_service.py
│   │   ├── energy_engine.py   # 电量计算核心引擎
│   │   ├── signal_service.py
│   │   ├── watcher_service.py
│   │   ├── alert_service.py
│   │   └── charge_service.py
│   ├── api/                   # 路由层（仅转发）
│   │   ├── auth.py
│   │   ├── energy.py
│   │   ├── watchers.py
│   │   ├── care.py
│   │   └── settings.py
│   └── utils/                 # 工具函数
│       ├── security.py        # JWT工具
│       └── energy_calc.py     # 电量算法
├── alembic/                   # 数据库迁移
├── tests/
├── requirements.txt
├── .env.example
└── README.md


【必须实现的模块】
1️⃣ 用户系统
- 登录（支持 mock 第三方登录）
- JWT + refresh token
- 用户信息获取

2️⃣ Energy Engine（核心）
实现：
- energy计算函数（根据 SignalFeature）
- score范围：0-100
- 输出：
  - score
  - level（high/medium/low）
  - trend
  - confidence

3️⃣ SignalFeature API
- POST /signals/daily
- 存储并触发 recalculation

4️⃣ Energy API
- GET /energy/current
- GET /energy/history

5️⃣ Watcher系统
- 邀请 / 接受
- 建立关系
- 权限控制

6️⃣ Alert系统
- 自动触发低电量事件
- 状态流转：
  pending → triggered → sent → resolved

7️⃣ CareMessage
- 发送关怀消息
- emoji回复

8️⃣ 手动充电
- 每日限制3次
- 每次+1%

【重要约束】
- watcher接口只能返回 energyBand，不返回 score
- 所有业务逻辑在 service 层实现
- API 层仅做请求转发

【额外要求】
- 提供数据库 schema
- 提供示例数据
- 提供启动脚本


【前端技术栈 Flutter App】
【架构】
- Clean Architecture
- 状态管理：Riverpod 或 Bloc
- 网络层：Dio
life-power-client
├── lib/
│   ├── core/
│   │   ├── constants.dart
│   │   ├── theme.dart         # 深色主题
│   │   └── router.dart
│   ├── data/
│   │   ├── models/           # 数据模型
│   │   ├── repositories/     # 数据仓库
│   │   └── services/         # API服务(Dio)
│   ├── presentation/
│   │   ├── pages/cd
│   │   │   ├── home/         # 首页-电量环
│   │   │   ├── charge/       # 充电页
│   │   │   ├── watchers/     # 守望页
│   │   │   ├── care/         # 关怀页
│   │   │   └── settings/     # 设置页
│   │   ├── widgets/          # 通用组件
│   │   │   ├── energy_ring.dart  # 电量环组件
│   │   │   └── breathing_animation.dart
│   │   └── providers/        # Riverpod状态管理
│   └── utils/
├── test/
├── pubspec.yaml
└── README.md


【页面结构】

1️⃣ 首页（核心）
- 电量环（圆形进度）
- 显示：
  - 电量 %
  - 状态颜色（绿/黄/红）
  - “X人正在守望你”

2️⃣ 充电页
- 今日行为数据列表：
  - 步数
  - 睡眠
- 按钮：开始呼吸（15秒动画）
- 显示充电次数

3️⃣ 守望页
- 我守望的人（列表）
  - 显示 energyBand（文字）
- 守望我的人

4️⃣ 关怀功能
- 发送预设消息
- emoji回复

5️⃣ 设置页
- 阈值设置
- 数据权限开关
- 守望者管理

【UI要求】
- 极简风（类似 Calm + Apple Health）
- 深色模式优先
- 动效：电量环动画

【API集成】
- 对接后端 REST API
- 实现 token 自动刷新

【本地能力】
- 模拟健康数据（MVP阶段）