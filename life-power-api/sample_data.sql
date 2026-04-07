-- LifePower sample data

-- Insert test users
INSERT INTO users (username, email, full_name, avatar_url) VALUES
('user1', 'user1@example.com', 'Test User 1', NULL),
('user2', 'user2@example.com', 'Test User 2', NULL),
('user3', 'user3@example.com', 'Test User 3', NULL);

-- Insert user auth identities (password: 'password123')
INSERT INTO user_auth_identities (user_id, provider, provider_id, password_hash) VALUES
(1, 'email', 'user1@example.com', 'password123'),
(2, 'email', 'user2@example.com', 'password123'),
(3, 'email', 'user3@example.com', 'password123');

-- Insert user settings
INSERT INTO user_settings (user_id, low_energy_threshold) VALUES
(1, 30),
(2, 30),
(3, 30);

-- Insert signal feature data
INSERT INTO signal_feature_daily (user_id, date, steps, sleep_hours, active_minutes, water_intake, mood_score) VALUES
(1, NOW() - INTERVAL '1 day', 8000, 7.5, 30, 2000, 8),
(1, NOW(), 10000, 8.0, 45, 2500, 9),
(2, NOW() - INTERVAL '1 day', 5000, 6.0, 20, 1500, 6),
(2, NOW(), 7000, 7.0, 35, 1800, 7),
(3, NOW() - INTERVAL '1 day', 12000, 8.5, 60, 3000, 10),
(3, NOW(), 9000, 7.5, 40, 2200, 8);

-- Insert energy snapshots
INSERT INTO energy_snapshots (user_id, score, level, trend, confidence) VALUES
(1, 75, 'high', 'increasing', 0.9),
(1, 80, 'high', 'stable', 0.95),
(2, 45, 'medium', 'increasing', 0.8),
(2, 50, 'medium', 'stable', 0.85),
(3, 85, 'high', 'stable', 0.95),
(3, 82, 'high', 'decreasing', 0.9);

-- Insert watcher relations
INSERT INTO watcher_relations (watcher_id, target_id, status) VALUES
(1, 2, 'accepted'),
(2, 1, 'accepted'),
(3, 1, 'pending');

-- Insert care messages
INSERT INTO care_messages (sender_id, recipient_id, content, emoji_response) VALUES
(1, 2, 'How are you feeling today?', 'smile'),
(2, 1, 'I''m fine, thanks for asking!', 'thumbsup'),
(1, 3, 'Welcome to LifePower!', NULL);

-- Insert alert events
INSERT INTO alert_events (user_id, type, status, energy_score, message, resolved_at) VALUES
(2, 'low_energy', 'resolved', 25, 'Energy level too low, please rest', NOW() - INTERVAL '2 hours');

-- Insert alert recipients
INSERT INTO alert_recipients (alert_id, recipient_id, status, sent_at) VALUES
(1, 1, 'delivered', NOW() - INTERVAL '3 hours');

-- Insert manual charge records
INSERT INTO manual_charge_records (user_id, amount, method) VALUES
(2, 1, 'breathing'),
(2, 1, 'manual'),
(1, 1, 'breathing');
