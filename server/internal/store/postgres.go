package store

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

// Postgres is a PostgreSQL-backed Store with optional Redis sessions/idempotency.
type Postgres struct {
	pool  *pgxpool.Pool
	rdb   *redis.Client // optional; nil = sessions in PG only
	ctx   context.Context
}

func OpenPostgres(ctx context.Context, databaseURL, redisAddr string) (*Postgres, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	p := &Postgres{pool: pool, ctx: ctx}
	if redisAddr != "" {
		rdb := redis.NewClient(&redis.Options{Addr: redisAddr})
		if err := rdb.Ping(ctx).Err(); err != nil {
			pool.Close()
			return nil, fmt.Errorf("redis: %w", err)
		}
		p.rdb = rdb
	}
	return p, nil
}

func (p *Postgres) Close() {
	if p.rdb != nil {
		_ = p.rdb.Close()
	}
	p.pool.Close()
}

func (p *Postgres) Migrate(sqlPath string) error {
	b, err := os.ReadFile(sqlPath)
	if err != nil {
		return err
	}
	_, err = p.pool.Exec(p.ctx, string(b))
	return err
}

func pgID(prefix string) string {
	var b [8]byte
	_, _ = rand.Read(b[:])
	return prefix + hex.EncodeToString(b[:])
}

func (p *Postgres) CreateAnonymous() (token string, progress AccountProgress) {
	acc := AccountProgress{
		AccountID:      pgID("acc_"),
		CommanderXP:    0,
		SoftCurrency:   0,
		HardCurrency:   0,
		SummonTickets:  10,
		PartyIDs:       []string{"H01", "H04", "H02", "H03", "H07"},
		QuestFlags:     map[string]bool{},
		ClaimedRewards: map[string]bool{},
		OwnedHeroes: map[string]bool{
			"H01": true, "H02": true, "H03": true, "H04": true, "H07": true,
		},
		AFKClaimedUnix: time.Now().Unix(),
		UpdatedAt:      time.Now().UTC().Format(time.RFC3339),
	}
	tok := pgID("tok_")
	party, _ := json.Marshal(acc.PartyIDs)
	qf, _ := json.Marshal(acc.QuestFlags)
	cr, _ := json.Marshal(acc.ClaimedRewards)
	oh, _ := json.Marshal(acc.OwnedHeroes)

	tx, err := p.pool.Begin(p.ctx)
	if err != nil {
		return "", AccountProgress{}
	}
	defer tx.Rollback(p.ctx)

	_, err = tx.Exec(p.ctx, `
		INSERT INTO accounts(
			account_id, commander_xp, soft_currency, hard_currency, summon_tickets,
			party_ids, quest_flags, claimed_rewards, owned_heroes, afk_claimed_unix, updated_at
		) VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb,$8::jsonb,$9::jsonb,$10,NOW())`,
		acc.AccountID, acc.CommanderXP, acc.SoftCurrency, acc.HardCurrency, acc.SummonTickets,
		party, qf, cr, oh, acc.AFKClaimedUnix,
	)
	if err != nil {
		return "", AccountProgress{}
	}
	if err := p.putSession(tx, tok, acc.AccountID); err != nil {
		return "", AccountProgress{}
	}
	if err := tx.Commit(p.ctx); err != nil {
		return "", AccountProgress{}
	}
	return tok, acc
}

func (p *Postgres) putSession(tx pgx.Tx, token, accountID string) error {
	if p.rdb != nil {
		key := "sess:" + token
		if err := p.rdb.Set(p.ctx, key, accountID, 30*24*time.Hour).Err(); err != nil {
			return err
		}
	}
	_, err := tx.Exec(p.ctx, `INSERT INTO sessions(token, account_id) VALUES ($1,$2)`, token, accountID)
	return err
}

func (p *Postgres) resolveAccountID(token string) (string, error) {
	if token == "" {
		return "", ErrUnauthorized
	}
	if p.rdb != nil {
		if id, err := p.rdb.Get(p.ctx, "sess:"+token).Result(); err == nil && id != "" {
			return id, nil
		}
	}
	var id string
	err := p.pool.QueryRow(p.ctx, `SELECT account_id FROM sessions WHERE token=$1`, token).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrUnauthorized
	}
	if err != nil {
		return "", err
	}
	if p.rdb != nil {
		_ = p.rdb.Set(p.ctx, "sess:"+token, id, 30*24*time.Hour).Err()
	}
	return id, nil
}

func (p *Postgres) loadAccount(accountID string) (*AccountProgress, error) {
	var acc AccountProgress
	var party, qf, cr, oh []byte
	var updated time.Time
	err := p.pool.QueryRow(p.ctx, `
		SELECT account_id, commander_xp, soft_currency, hard_currency, summon_tickets,
			party_ids, quest_flags, claimed_rewards, owned_heroes, afk_claimed_unix,
			active_battle_id, battle_seed, updated_at
		FROM accounts WHERE account_id=$1`, accountID).Scan(
		&acc.AccountID, &acc.CommanderXP, &acc.SoftCurrency, &acc.HardCurrency, &acc.SummonTickets,
		&party, &qf, &cr, &oh, &acc.AFKClaimedUnix, &acc.ActiveBattleID, &acc.BattleSeed, &updated,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrUnauthorized
	}
	if err != nil {
		return nil, err
	}
	_ = json.Unmarshal(party, &acc.PartyIDs)
	_ = json.Unmarshal(qf, &acc.QuestFlags)
	_ = json.Unmarshal(cr, &acc.ClaimedRewards)
	_ = json.Unmarshal(oh, &acc.OwnedHeroes)
	if acc.QuestFlags == nil {
		acc.QuestFlags = map[string]bool{}
	}
	if acc.ClaimedRewards == nil {
		acc.ClaimedRewards = map[string]bool{}
	}
	if acc.OwnedHeroes == nil {
		acc.OwnedHeroes = map[string]bool{}
	}
	acc.UpdatedAt = updated.UTC().Format(time.RFC3339)
	return &acc, nil
}

func (p *Postgres) AccountByToken(token string) (*AccountProgress, error) {
	id, err := p.resolveAccountID(token)
	if err != nil {
		return nil, err
	}
	return p.loadAccount(id)
}

func (p *Postgres) saveAccount(acc *AccountProgress) error {
	party, _ := json.Marshal(acc.PartyIDs)
	qf, _ := json.Marshal(acc.QuestFlags)
	cr, _ := json.Marshal(acc.ClaimedRewards)
	oh, _ := json.Marshal(acc.OwnedHeroes)
	_, err := p.pool.Exec(p.ctx, `
		UPDATE accounts SET
			commander_xp=$2, soft_currency=$3, hard_currency=$4, summon_tickets=$5,
			party_ids=$6::jsonb, quest_flags=$7::jsonb, claimed_rewards=$8::jsonb, owned_heroes=$9::jsonb,
			afk_claimed_unix=$10, active_battle_id=$11, battle_seed=$12, updated_at=NOW()
		WHERE account_id=$1`,
		acc.AccountID, acc.CommanderXP, acc.SoftCurrency, acc.HardCurrency, acc.SummonTickets,
		party, qf, cr, oh, acc.AFKClaimedUnix, acc.ActiveBattleID, acc.BattleSeed,
	)
	return err
}

func (p *Postgres) mutate(token string, fn func(*AccountProgress) error) (*AccountProgress, error) {
	id, err := p.resolveAccountID(token)
	if err != nil {
		return nil, err
	}
	acc, err := p.loadAccount(id)
	if err != nil {
		return nil, err
	}
	if err := fn(acc); err != nil {
		return nil, err
	}
	acc.UpdatedAt = time.Now().UTC().Format(time.RFC3339)
	if err := p.saveAccount(acc); err != nil {
		return nil, err
	}
	return acc, nil
}

func (p *Postgres) SetParty(token string, party []string) (*AccountProgress, error) {
	if len(party) == 0 || len(party) > 5 {
		return nil, ErrInvalidParty
	}
	seen := map[string]bool{}
	for _, id := range party {
		if id == "" || seen[id] {
			return nil, ErrInvalidParty
		}
		seen[id] = true
	}
	return p.mutate(token, func(acc *AccountProgress) error {
		for _, id := range party {
			if !acc.OwnedHeroes[id] {
				return ErrInvalidParty
			}
		}
		acc.PartyIDs = append([]string{}, party...)
		return nil
	})
}

func (p *Postgres) ClaimReward(token, bundleID string, soft, xp int) (softDelta, xpDelta int, already bool, err error) {
	if bundleID == "" {
		return 0, 0, false, ErrValidation
	}
	// Redis idempotency hint (best-effort); source of truth remains claimed_rewards in PG.
	if p.rdb != nil {
		key := "claim:" + token + ":" + bundleID
		ok, rerr := p.rdb.SetNX(p.ctx, key, "1", 24*time.Hour).Result()
		if rerr == nil && !ok {
			// may already be claimed — fall through to PG for authoritative already flag
		}
	}
	_, err = p.mutate(token, func(acc *AccountProgress) error {
		if acc.ClaimedRewards[bundleID] {
			already = true
			softDelta, xpDelta = 0, 0
			return nil
		}
		acc.ClaimedRewards[bundleID] = true
		acc.SoftCurrency += soft
		acc.CommanderXP += xp
		softDelta, xpDelta = soft, xp
		already = false
		return nil
	})
	return
}

func (p *Postgres) ClaimAFK(token string, softPerHour, xpPerHour int) (hours float64, soft, xp int, err error) {
	_, err = p.mutate(token, func(acc *AccountProgress) error {
		now := time.Now().Unix()
		elapsed := float64(now - acc.AFKClaimedUnix)
		if elapsed < 0 {
			elapsed = 0
		}
		hours = elapsed / 3600.0
		if hours > AFKMaxHours {
			hours = AFKMaxHours
		}
		soft = int(float64(softPerHour) * hours)
		xp = int(float64(xpPerHour) * hours)
		if soft <= 0 && xp <= 0 {
			return ErrValidation
		}
		acc.SoftCurrency += soft
		acc.CommanderXP += xp
		acc.AFKClaimedUnix = now
		return nil
	})
	return
}

func (p *Postgres) Summon(token string, heroPool []string) (heroID string, newly bool, err error) {
	if len(heroPool) == 0 {
		return "", false, ErrValidation
	}
	_, err = p.mutate(token, func(acc *AccountProgress) error {
		if acc.SummonTickets <= 0 {
			return ErrNoTickets
		}
		acc.SummonTickets--
		idx := int(time.Now().UnixNano() % int64(len(heroPool)))
		heroID = heroPool[idx]
		newly = !acc.OwnedHeroes[heroID]
		acc.OwnedHeroes[heroID] = true
		if !newly {
			acc.SoftCurrency += 50
		}
		return nil
	})
	return
}

func (p *Postgres) StartBattle(token, battleID string, party []string) (seed int64, err error) {
	_, err = p.mutate(token, func(acc *AccountProgress) error {
		if battleID == "" {
			return ErrValidation
		}
		if len(party) > 0 {
			for _, id := range party {
				if !acc.OwnedHeroes[id] {
					return ErrInvalidParty
				}
			}
			acc.PartyIDs = append([]string{}, party...)
		}
		seed = time.Now().UnixNano()
		acc.ActiveBattleID = battleID
		acc.BattleSeed = seed
		return nil
	})
	return
}

func (p *Postgres) FinishBattle(token, battleID string, victory bool) (*AccountProgress, error) {
	return p.mutate(token, func(acc *AccountProgress) error {
		if battleID == "" {
			return ErrValidation
		}
		if acc.ActiveBattleID == "" || acc.ActiveBattleID != battleID {
			return ErrNoActiveBattle
		}
		if victory {
			acc.QuestFlags["battle:"+battleID] = true
		}
		acc.ActiveBattleID = ""
		acc.BattleSeed = 0
		return nil
	})
}

var _ Store = (*Postgres)(nil)
