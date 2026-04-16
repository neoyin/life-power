# LifePower API Railway 部署指南

## 一、Railway 简介

Railway 是一个现代化的云平台，原生支持：
- Python (自动检测 FastAPI/Django/Flask)
- PostgreSQL（自带免费额度）
- 自动 HTTPS
- 环保部署

**免费额度：**
- 500 小时/月（相当于 24/7 运行）
- 1GB 内存
- 共享 CPU

---

## 二、快速部署步骤

### 2.1 安装 Railway CLI

```bash
npm install -g @railway/cli
```

### 2.2 登录 Railway

```bash
railway login
```

浏览器会打开授权页面，点击授权。

### 2.3 初始化项目

```bash
cd life-power-api
railway init
```

按照提示创建新项目。

### 2.4 添加 PostgreSQL 数据库

```bash
railway add -d postgres
```

Railway 会自动创建 PostgreSQL 数据库并设置 `DATABASE_URL` 环境变量。

### 2.5 设置环境变量

在 Railway Dashboard 中设置：

| 变量名 | 值 |
|--------|-----|
| `SECRET_KEY` | 你的随机密钥（用于 JWT） |
| `DEPLOYMENT` | `railway` |
| `R2_ACCOUNT_ID` | Cloudflare R2 账户 ID |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 Access Key ID |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 Secret Access Key |
| `R2_BUCKET_NAME` | R2 Bucket 名称（如 `avatars`） |
| `R2_PUBLIC_URL` | R2 公共访问 URL（如 `https://avatars.your-domain.com`） |

**注意**：R2 环境变量必须正确配置，否则头像上传功能将返回 500 错误。

本地开发环境的 `.env` 文件示例：
```env
DATABASE_URL=postgresql://user:password@localhost:5432/lifepower
SECRET_KEY=your-secret-key-here
R2_ACCOUNT_ID=your-r2-account-id
R2_ACCESS_KEY_ID=your-r2-access-key-id
R2_SECRET_ACCESS_KEY=your-r2-secret-access-key
R2_BUCKET_NAME=avatars
R2_PUBLIC_URL=https://avatars.your-domain.com
```

Railway 会自动设置 `DATABASE_URL`，只需添加 `SECRET_KEY` 和 R2 相关变量。

### 2.6 部署

```bash
railway up
```

部署完成后，Railway 会返回 API 地址，如：
```
https://life-power-api.up.railway.app
```

---

## 三、数据库迁移

### 3.1 运行迁移

```bash
railway run alembic upgrade head
```

### 3.2 或者直接连接数据库执行 SQL

Railway 提供 PostgreSQL 连接字符串，可以在本地用 `psql` 连接执行迁移。

---

## 四、常用命令

```bash
# 部署更新
railway up

# 查看日志
railway logs

# 打开 Railway Dashboard
railway open

# 添加环境变量
railway variables set SECRET_KEY=your-key

# 连接到数据库（本地）
railway connect postgresql
```

---

## 五、连接前端

部署成功后，将 API 地址配置到 Flutter 前端：

```dart
// lib/core/config.dart 或 lib/data/services/api_service.dart
const String baseUrl = 'https://life-power-api.up.railway.app';
```

---

## 六、更新已部署的应用

```bash
cd life-power-api
railway up
```

Railway 会自动检测代码变更并重新部署。

---

## 七、故障排查

### 7.1 查看日志
```bash
railway logs
```

### 7.2 常见问题

**Q: 部署失败**
- 检查 `requirements.txt` 是否完整
- 检查是否缺少依赖

**Q: 数据库连接失败**
- 确认 `DATABASE_URL` 环境变量已设置
- Railway 的 PostgreSQL 可能需要片刻初始化

**Q: 如何重新部署？**
```bash
railway up --detach
```

**Q: 头像上传返回 500 错误？**
- 检查 Railway 环境变量是否包含所有 R2 配置（R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME, R2_PUBLIC_URL）
- 运行 `railway logs` 查看详细错误日志
- 确保 R2 bucket 存在且有正确的权限配置

---

## 八、成本说明

| 资源 | 免费额度 | 收费 |
|------|----------|------|
| 计算时间 | 500 小时/月 | $0.001/分钟 |
| PostgreSQL | 1GB 存储 | $0.015/GB/月 |
| 带宽 | 100GB/月 | $0.10/GB |

**小型应用预估月费：$0**
