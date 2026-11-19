-- P2 online fields: gacha history, test purchase counters, VIP daily claim
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS gacha_history JSONB NOT NULL DEFAULT '[]';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS test_purchase_day TEXT NOT NULL DEFAULT '';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS test_purchases_day INT NOT NULL DEFAULT 0;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS test_hard_day INT NOT NULL DEFAULT 0;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS test_vip_day INT NOT NULL DEFAULT 0;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS vip_daily_claimed TEXT NOT NULL DEFAULT '';
