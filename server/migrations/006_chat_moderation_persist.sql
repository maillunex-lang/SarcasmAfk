-- Chat persistence + moderation columns (T-154)
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS level INT NOT NULL DEFAULT 1;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS avatar TEXT NOT NULL DEFAULT 'lunex://heroes/avatar/default';
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS deleted BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS chat_mutes (
    account_id TEXT PRIMARY KEY,
    muted_until TIMESTAMPTZ NOT NULL,
    reason TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
