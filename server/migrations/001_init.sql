-- BashLegends Phase 2 schema (T-085)
CREATE TABLE IF NOT EXISTS accounts (
    account_id       TEXT PRIMARY KEY,
    commander_xp     INT NOT NULL DEFAULT 0,
    soft_currency    INT NOT NULL DEFAULT 0,
    hard_currency    INT NOT NULL DEFAULT 0,
    summon_tickets   INT NOT NULL DEFAULT 10,
    party_ids        JSONB NOT NULL DEFAULT '[]',
    quest_flags      JSONB NOT NULL DEFAULT '{}',
    claimed_rewards  JSONB NOT NULL DEFAULT '{}',
    owned_heroes     JSONB NOT NULL DEFAULT '{}',
    afk_claimed_unix BIGINT NOT NULL DEFAULT 0,
    active_battle_id TEXT NOT NULL DEFAULT '',
    battle_seed      BIGINT NOT NULL DEFAULT 0,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sessions (
    token      TEXT PRIMARY KEY,
    account_id TEXT NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_account ON sessions(account_id);
