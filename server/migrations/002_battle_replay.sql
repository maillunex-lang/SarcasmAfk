-- Battle replay session fields (P0 authoritative combat)
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS balance_version TEXT NOT NULL DEFAULT '';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS battle_commands JSONB NOT NULL DEFAULT '[]';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS battle_tick_approx INT NOT NULL DEFAULT 0;
