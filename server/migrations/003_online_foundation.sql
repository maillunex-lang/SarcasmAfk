-- Online systems foundation (P1): hero instances, economy ledger hooks, chat, guilds, gacha, shop, VIP.
-- Additive only; preserves existing account columns and IDs.

ALTER TABLE accounts ADD COLUMN IF NOT EXISTS hero_instances JSONB NOT NULL DEFAULT '{}';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS inventory JSONB NOT NULL DEFAULT '{}';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS vip_points INT NOT NULL DEFAULT 0;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS vip_level INT NOT NULL DEFAULT 0;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS pity_counters JSONB NOT NULL DEFAULT '{}';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS guild_id TEXT NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS audit_ledger (
    id           BIGSERIAL PRIMARY KEY,
    account_id   TEXT NOT NULL,
    kind         TEXT NOT NULL,
    ref_id       TEXT NOT NULL DEFAULT '',
    delta_soft   INT NOT NULL DEFAULT 0,
    delta_hard   INT NOT NULL DEFAULT 0,
    delta_tickets INT NOT NULL DEFAULT 0,
    meta         JSONB NOT NULL DEFAULT '{}',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_ledger_account ON audit_ledger(account_id, created_at DESC);

CREATE TABLE IF NOT EXISTS chat_messages (
    id           BIGSERIAL PRIMARY KEY,
    channel      TEXT NOT NULL,
    account_id   TEXT NOT NULL,
    display_name TEXT NOT NULL DEFAULT '',
    body         TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_chat_channel_time ON chat_messages(channel, id DESC);

CREATE TABLE IF NOT EXISTS chat_blocks (
    account_id   TEXT NOT NULL,
    blocked_id   TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (account_id, blocked_id)
);

CREATE TABLE IF NOT EXISTS chat_reports (
    id           BIGSERIAL PRIMARY KEY,
    reporter_id  TEXT NOT NULL,
    message_id   BIGINT NOT NULL,
    reason       TEXT NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guilds (
    guild_id     TEXT PRIMARY KEY,
    name         TEXT NOT NULL,
    tag          TEXT NOT NULL UNIQUE,
    emblem       TEXT NOT NULL DEFAULT 'lunex://guild/emblem/default',
    description  TEXT NOT NULL DEFAULT '',
    join_mode    TEXT NOT NULL DEFAULT 'open',
    level        INT NOT NULL DEFAULT 1,
    xp           INT NOT NULL DEFAULT 0,
    leader_id    TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guild_members (
    guild_id     TEXT NOT NULL REFERENCES guilds(guild_id) ON DELETE CASCADE,
    account_id   TEXT NOT NULL,
    role         TEXT NOT NULL DEFAULT 'member',
    contrib_xp   INT NOT NULL DEFAULT 0,
    joined_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (guild_id, account_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_guild_members_account ON guild_members(account_id);

CREATE TABLE IF NOT EXISTS guild_log (
    id           BIGSERIAL PRIMARY KEY,
    guild_id     TEXT NOT NULL,
    actor_id     TEXT NOT NULL,
    action       TEXT NOT NULL,
    meta         JSONB NOT NULL DEFAULT '{}',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gacha_history (
    id           BIGSERIAL PRIMARY KEY,
    account_id   TEXT NOT NULL,
    banner_id    TEXT NOT NULL,
    hero_id      TEXT NOT NULL,
    newly_owned  BOOLEAN NOT NULL DEFAULT true,
    cost_tickets INT NOT NULL DEFAULT 0,
    cost_hard    INT NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_gacha_history_account ON gacha_history(account_id, id DESC);

CREATE TABLE IF NOT EXISTS shop_purchases (
    id           BIGSERIAL PRIMARY KEY,
    account_id   TEXT NOT NULL,
    sku          TEXT NOT NULL,
    purchase_mode TEXT NOT NULL DEFAULT 'simulated',
    amount_soft  INT NOT NULL DEFAULT 0,
    amount_hard  INT NOT NULL DEFAULT 0,
    real_money_cents INT NOT NULL DEFAULT 0,
    provider_ref TEXT NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_shop_purchases_account ON shop_purchases(account_id, id DESC);

CREATE TABLE IF NOT EXISTS vip_grants (
    id           BIGSERIAL PRIMARY KEY,
    account_id   TEXT NOT NULL,
    points       INT NOT NULL,
    reason       TEXT NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS config_versions (
    key          TEXT NOT NULL,
    version      INT NOT NULL,
    payload      JSONB NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (key, version)
);
