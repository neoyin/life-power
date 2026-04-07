# LifePower (守望电量)

通过"电量"量化用户状态，在低电量时触发守望者关怀机制的完整应用。

## 项目结构

```
├── life-power-api/    # 后端 API 服务
├── life-power-client/   # 前端 Flutter 应用
└── unified-self-improving/ # 自我进化技能（可选）
```

## 技术栈

### 后端
- Python 3.10+
- FastAPI
- PostgreSQL
- SQLAlchemy
- JWT 认证

### 前端
- Flutter 3.0+
- Riverpod 状态管理
- Dio 网络请求
- 深色主题

## 核心功能

1. **用户系统**
   - 注册/登录
   - JWT 认证
   - 用户信息管理

2. **Energy Engine**
   - 基于信号特征的能量计算
   - 能量等级评估
   - 能量历史记录

3. **SignalFeature API**
   - 日常健康数据提交
   - 能量自动重新计算

4. **Watcher 系统**
   - 守望者邀请/接受
   - 能量状态共享
   - 权限管理

5. **Alert 系统**
   - 低电量自动告警
   - 状态流转管理

6. **CareMessage**
   - 关怀消息发送
   - Emoji 回复

7. **手动充电**
   - 每日限制 3 次
   - 每次 +1% 能量

## 快速开始

### 后端设置

1. **安装依赖**
   ```bash
   cd life-power-api
   pip install -r requirements.txt
   ```

2. **配置环境变量**
   ```bash
   cd life-power-api
   cp .env.example .env
   # 编辑 .env 文件，设置数据库连接和 JWT 密钥
   ```

3. **初始化数据库**
   ```bash
   # 创建数据库
   psql -U postgres -c "CREATE DATABASE lifepower;"
   
   # 执行 schema
   psql -U postgres -d lifepower -f life-power-api/database_schema.sql
   
   # 插入示例数据
   psql -U postgres -d lifepower -f life-power-api/sample_data.sql
   ```

4. **启动服务**
   ```bash
   cd life-power-api
   uvicorn app.main:app --reload
   ```

### 前端设置

1. **安装依赖**
   ```bash
   cd life-power-client
   flutter pub get
   ```

2. **运行应用**
   ```bash
   flutter run
   ```

## API 文档

启动后端服务后，访问 `http://localhost:8000/docs` 查看 API 文档。

## 测试账号

- **用户 1**: user1@example.com / password
- **用户 2**: user2@example.com / password
- **用户 3**: user3@example.com / password

## 项目特点

- **清晰分层**：后端采用分层架构，前端采用 Clean Architecture
- **生产级代码**：完整的错误处理、数据验证和安全措施
- **可扩展性**：模块化设计，易于添加新功能
- **用户体验**：流畅的动画效果和响应式设计

## 注意事项

- 本项目为 MVP 版本，可根据实际需求进行扩展
- 生产环境部署时请修改 JWT 密钥和数据库配置
- 前端 API 地址可在 `constants.dart` 中修改
