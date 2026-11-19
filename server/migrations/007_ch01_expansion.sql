-- CH01 RPG expansion: sidequest/POI/journal progress (additive, backward compatible).

ALTER TABLE accounts ADD COLUMN IF NOT EXISTS sidequest_progress JSONB NOT NULL DEFAULT '{}';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS poi_progress JSONB NOT NULL DEFAULT '{}';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS journal_flags JSONB NOT NULL DEFAULT '{}';

-- Optional normalized tables for unique (account_id, quest_id) and step events.
CREATE TABLE IF NOT EXISTS ch01_sidequest_progress (
    account_id         TEXT NOT NULL,
    quest_id           TEXT NOT NULL,
    state              TEXT NOT NULL DEFAULT 'available',
    completed_step_ids JSONB NOT NULL DEFAULT '[]',
    reward_claimed_at  TIMESTAMPTZ,
    started_at         TIMESTAMPTZ,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version            INT NOT NULL DEFAULT 1,
    PRIMARY KEY (account_id, quest_id)
);

CREATE TABLE IF NOT EXISTS ch01_sidequest_steps (
    account_id   TEXT NOT NULL,
    quest_id     TEXT NOT NULL,
    step_id      TEXT NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (account_id, quest_id, step_id)
);

CREATE TABLE IF NOT EXISTS ch01_poi_events (
    account_id   TEXT NOT NULL,
    poi_id       TEXT NOT NULL,
    action_id    TEXT NOT NULL DEFAULT '',
    state        TEXT NOT NULL DEFAULT 'completed',
    meta         JSONB NOT NULL DEFAULT '{}',
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (account_id, poi_id, action_id)
);

CREATE TABLE IF NOT EXISTS ch01_journal (
    account_id TEXT NOT NULL,
    flag_id    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (account_id, flag_id)
);
