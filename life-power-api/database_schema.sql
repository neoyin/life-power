-- LifePower 数据库 schema

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 用户认证身份表
CREATE TABLE IF NOT EXISTS user_auth_identities (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_id VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 用户设置表
CREATE TABLE IF NOT EXISTS user_settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    low_energy_threshold INTEGER DEFAULT 30,
    enable_notifications BOOLEAN DEFAULT TRUE,
    share_energy_data BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 能量快照表
CREATE TABLE IF NOT EXISTS energy_snapshots (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    level VARCHAR(20) NOT NULL,
    trend VARCHAR(20) NOT NULL,
    confidence FLOAT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 信号特征表
CREATE TABLE IF NOT EXISTS signal_feature_daily (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date TIMESTAMP NOT NULL,
    steps INTEGER,
    sleep_hours FLOAT,
    active_minutes INTEGER,
    water_intake INTEGER,
    mood_score INTEGER,
    breathing_sessions INTEGER DEFAULT 0,  -- 每日呼吸训练次数
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_signal_user_date UNIQUE (user_id, date)  -- 每用户每天只有一条记录
);

-- 守望者关系表
CREATE TABLE IF NOT EXISTS watcher_relations (
    id SERIAL PRIMARY KEY,
    watcher_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 关怀消息表
CREATE TABLE IF NOT EXISTS care_messages (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    emoji_response VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 告警事件表
CREATE TABLE IF NOT EXISTS alert_events (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    energy_score INTEGER NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- 告警接收者表
CREATE TABLE IF NOT EXISTS alert_recipients (
    id SERIAL PRIMARY KEY,
    alert_id INTEGER NOT NULL REFERENCES alert_events(id) ON DELETE CASCADE,
    recipient_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 手动充电记录表
CREATE TABLE IF NOT EXISTS manual_charge_records (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    method VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_user_auth_identities_user_id ON user_auth_identities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_energy_snapshots_user_id ON energy_snapshots(user_id);
CREATE INDEX IF NOT EXISTS idx_signal_feature_daily_user_id ON signal_feature_daily(user_id);
CREATE INDEX IF NOT EXISTS idx_watcher_relations_watcher_id ON watcher_relations(watcher_id);
CREATE INDEX IF NOT EXISTS idx_watcher_relations_target_id ON watcher_relations(target_id);
CREATE INDEX IF NOT EXISTS idx_care_messages_sender_id ON care_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_care_messages_recipient_id ON care_messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_alert_events_user_id ON alert_events(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_recipients_alert_id ON alert_recipients(alert_id);
CREATE INDEX IF NOT EXISTS idx_manual_charge_records_user_id ON manual_charge_records(user_id);
