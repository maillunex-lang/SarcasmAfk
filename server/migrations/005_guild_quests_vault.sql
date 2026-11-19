-- Guild quests / vault hooks (P3). Wars/bosses reserved, not implemented.
ALTER TABLE guilds ADD COLUMN IF NOT EXISTS vault_soft INT NOT NULL DEFAULT 0;
ALTER TABLE guilds ADD COLUMN IF NOT EXISTS quests JSONB NOT NULL DEFAULT '[]';

CREATE TABLE IF NOT EXISTS guild_contributions (
    guild_id     TEXT NOT NULL,
    account_id   TEXT NOT NULL,
    contrib_xp   INT NOT NULL DEFAULT 0,
    donated_soft INT NOT NULL DEFAULT 0,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (guild_id, account_id)
);

-- Future hooks (empty tables / flags only)
CREATE TABLE IF NOT EXISTS guild_boss_hooks (
    guild_id   TEXT PRIMARY KEY,
    enabled    BOOLEAN NOT NULL DEFAULT false,
    note       TEXT NOT NULL DEFAULT 'rules pending owner approval'
);

CREATE TABLE IF NOT EXISTS guild_war_hooks (
    id         BIGSERIAL PRIMARY KEY,
    enabled    BOOLEAN NOT NULL DEFAULT false,
    note       TEXT NOT NULL DEFAULT 'wars not implemented until rules approved'
);
