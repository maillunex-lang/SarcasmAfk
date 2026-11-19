-- EQUIPMENT-001: unique equipment instances + transactions (additive).

ALTER TABLE accounts ADD COLUMN IF NOT EXISTS equipment_instances JSONB NOT NULL DEFAULT '{}';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS equipment_pending JSONB NOT NULL DEFAULT '[]';

CREATE TABLE IF NOT EXISTS equipment_instances (
    id                       UUID PRIMARY KEY,
    account_id               TEXT NOT NULL,
    template_id              TEXT NOT NULL,
    upgrade_level            INT NOT NULL DEFAULT 0,
    is_locked                BOOLEAN NOT NULL DEFAULT FALSE,
    equipped_hero_id         TEXT,
    equipped_slot            TEXT,
    acquisition_source       TEXT NOT NULL DEFAULT '',
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version                  INT NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_equipment_instances_account ON equipment_instances(account_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_equipment_one_per_hero_slot
    ON equipment_instances(account_id, equipped_hero_id, equipped_slot)
    WHERE equipped_hero_id IS NOT NULL AND equipped_slot IS NOT NULL;

CREATE TABLE IF NOT EXISTS equipment_transactions (
    id           BIGSERIAL PRIMARY KEY,
    account_id   TEXT NOT NULL,
    request_id   TEXT NOT NULL,
    action       TEXT NOT NULL,
    instance_id  TEXT NOT NULL DEFAULT '',
    before_state JSONB NOT NULL DEFAULT '{}',
    after_state  JSONB NOT NULL DEFAULT '{}',
    cost         JSONB NOT NULL DEFAULT '{}',
    reward       JSONB NOT NULL DEFAULT '{}',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (account_id, request_id)
);

CREATE TABLE IF NOT EXISTS equipment_pending_rewards (
    id           BIGSERIAL PRIMARY KEY,
    account_id   TEXT NOT NULL,
    source_key   TEXT NOT NULL,
    template_id  TEXT NOT NULL,
    meta         JSONB NOT NULL DEFAULT '{}',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    claimed_at   TIMESTAMPTZ,
    UNIQUE (account_id, source_key)
);
