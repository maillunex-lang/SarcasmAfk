package store

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
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

// Pool exposes the pgx pool for companion services (chat, etc.).
func (p *Postgres) Pool() *pgxpool.Pool { return p.pool }

// Redis exposes optional Redis client (may be nil).
func (p *Postgres) Redis() *redis.Client { return p.rdb }

func (p *Postgres) Migrate(sqlPath string) error {
	info, err := os.Stat(sqlPath)
	if err != nil {
		return err
	}
	var files []string
	if info.IsDir() {
		entries, err := os.ReadDir(sqlPath)
		if err != nil {
			return err
		}
		for _, e := range entries {
			if !e.IsDir() && strings.HasSuffix(e.Name(), ".sql") {
				files = append(files, filepath.Join(sqlPath, e.Name()))
			}
		}
	} else {
		files = []string{sqlPath}
	}
	for _, f := range files {
		b, err := os.ReadFile(f)
		if err != nil {
			return err
		}
		if _, err := p.pool.Exec(p.ctx, string(b)); err != nil {
			return fmt.Errorf("%s: %w", f, err)
		}
	}
	return nil
}

func pgID(prefix string) string {
	var b [8]byte
	_, _ = rand.Read(b[:])
	return prefix + hex.EncodeToString(b[:])
}

func (p *Postgres) CreateAnonymous() (token string, progress AccountProgress) {
	acc := AccountProgress{
		AccountID:     pgID("acc_"),
		CommanderXP:   0,
		SoftCurrency:  StartingSoftDraft,
		HardCurrency:  0,
		SummonTickets: 10,
		PartyIDs:      []string{"H01", "H04", "H02", "H03", "H07"},
		QuestFlags:    map[string]bool{},
		ClaimedRewards: map[string]bool{},
		OwnedHeroes: map[string]bool{
			"H01": true, "H02": true, "H03": true, "H04": true, "H07": true,
		},
		HeroInstances:  map[string]*HeroInstance{},
		Inventory:      map[string]int{"mat_hero_exp": 500},
		PityCounters:   map[string]int{},
		Sidequests:     map[string]*SidequestState{},
		POIProgress:    map[string]*POIProgress{},
		JournalFlags:   map[string]bool{},
		AFKClaimedUnix: time.Now().Unix(),
		UpdatedAt:      time.Now().UTC().Format(time.RFC3339),
	}
	EnsureHeroInstances(&acc)
	EnsureExpansion(&acc)
	tok := pgID("tok_")
	party, _ := json.Marshal(acc.PartyIDs)
	qf, _ := json.Marshal(acc.QuestFlags)
	cr, _ := json.Marshal(acc.ClaimedRewards)
	oh, _ := json.Marshal(acc.OwnedHeroes)
	hi, _ := json.Marshal(acc.HeroInstances)
	inv, _ := json.Marshal(acc.Inventory)
	pity, _ := json.Marshal(acc.PityCounters)
	sq, _ := json.Marshal(acc.Sidequests)
	poi, _ := json.Marshal(acc.POIProgress)
	jf, _ := json.Marshal(acc.JournalFlags)

	tx, err := p.pool.Begin(p.ctx)
	if err != nil {
		return "", AccountProgress{}
	}
	defer tx.Rollback(p.ctx)

	_, err = tx.Exec(p.ctx, `
		INSERT INTO accounts(
			account_id, commander_xp, soft_currency, hard_currency, summon_tickets,
			party_ids, quest_flags, claimed_rewards, owned_heroes, afk_claimed_unix,
			hero_instances, inventory, vip_points, vip_level, pity_counters, guild_id,
			sidequest_progress, poi_progress, journal_flags, updated_at
		) VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb,$8::jsonb,$9::jsonb,$10,
			$11::jsonb,$12::jsonb,0,0,$13::jsonb,'',$14::jsonb,$15::jsonb,$16::jsonb,NOW())`,
		acc.AccountID, acc.CommanderXP, acc.SoftCurrency, acc.HardCurrency, acc.SummonTickets,
		party, qf, cr, oh, acc.AFKClaimedUnix, hi, inv, pity, sq, poi, jf,
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
	var party, qf, cr, oh, cmds, hi, inv, pity, gh, sq, poi, jf, eqi, eqp []byte
	var updated time.Time
	err := p.pool.QueryRow(p.ctx, `
		SELECT account_id, commander_xp, soft_currency, hard_currency, summon_tickets,
			party_ids, quest_flags, claimed_rewards, owned_heroes, afk_claimed_unix,
			active_battle_id, battle_seed, COALESCE(balance_version,''), COALESCE(battle_commands,'[]'::jsonb),
			COALESCE(battle_tick_approx,0),
			COALESCE(hero_instances,'{}'::jsonb), COALESCE(inventory,'{}'::jsonb),
			COALESCE(vip_points,0), COALESCE(vip_level,0), COALESCE(pity_counters,'{}'::jsonb),
			COALESCE(guild_id,''),
			COALESCE(gacha_history,'[]'::jsonb), COALESCE(test_purchase_day,''),
			COALESCE(test_purchases_day,0), COALESCE(test_hard_day,0), COALESCE(test_vip_day,0),
			COALESCE(vip_daily_claimed,''),
			COALESCE(sidequest_progress,'{}'::jsonb), COALESCE(poi_progress,'{}'::jsonb),
			COALESCE(journal_flags,'{}'::jsonb),
			COALESCE(equipment_instances,'{}'::jsonb), COALESCE(equipment_pending,'[]'::jsonb),
			updated_at
		FROM accounts WHERE account_id=$1`, accountID).Scan(
		&acc.AccountID, &acc.CommanderXP, &acc.SoftCurrency, &acc.HardCurrency, &acc.SummonTickets,
		&party, &qf, &cr, &oh, &acc.AFKClaimedUnix, &acc.ActiveBattleID, &acc.BattleSeed,
		&acc.BalanceVersion, &cmds, &acc.BattleTickApprox,
		&hi, &inv, &acc.VipPoints, &acc.VipLevel, &pity, &acc.GuildID,
		&gh, &acc.TestPurchaseDay, &acc.TestPurchasesDay, &acc.TestHardDay, &acc.TestVipDay,
		&acc.VipDailyClaimed, &sq, &poi, &jf, &eqi, &eqp, &updated,
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
	_ = json.Unmarshal(cmds, &acc.BattleCommands)
	_ = json.Unmarshal(hi, &acc.HeroInstances)
	_ = json.Unmarshal(inv, &acc.Inventory)
	_ = json.Unmarshal(pity, &acc.PityCounters)
	_ = json.Unmarshal(gh, &acc.GachaHistory)
	_ = json.Unmarshal(sq, &acc.Sidequests)
	_ = json.Unmarshal(poi, &acc.POIProgress)
	_ = json.Unmarshal(jf, &acc.JournalFlags)
	_ = json.Unmarshal(eqi, &acc.EquipmentBag)
	_ = json.Unmarshal(eqp, &acc.EquipmentPending)
	if acc.QuestFlags == nil {
		acc.QuestFlags = map[string]bool{}
	}
	if acc.ClaimedRewards == nil {
		acc.ClaimedRewards = map[string]bool{}
	}
	if acc.OwnedHeroes == nil {
		acc.OwnedHeroes = map[string]bool{}
	}
	EnsureHeroInstances(&acc)
	EnsureExpansion(&acc)
	EnsureEquipment(&acc)
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
	EnsureHeroInstances(acc)
	EnsureExpansion(acc)
	party, _ := json.Marshal(acc.PartyIDs)
	qf, _ := json.Marshal(acc.QuestFlags)
	cr, _ := json.Marshal(acc.ClaimedRewards)
	oh, _ := json.Marshal(acc.OwnedHeroes)
	cmds, _ := json.Marshal(acc.BattleCommands)
	hi, _ := json.Marshal(acc.HeroInstances)
	inv, _ := json.Marshal(acc.Inventory)
	pity, _ := json.Marshal(acc.PityCounters)
	gh, _ := json.Marshal(acc.GachaHistory)
	sq, _ := json.Marshal(acc.Sidequests)
	poi, _ := json.Marshal(acc.POIProgress)
	jf, _ := json.Marshal(acc.JournalFlags)
	eqi, _ := json.Marshal(acc.EquipmentBag)
	eqp, _ := json.Marshal(acc.EquipmentPending)
	if cmds == nil {
		cmds = []byte("[]")
	}
	if gh == nil {
		gh = []byte("[]")
	}
	if eqi == nil {
		eqi = []byte("{}")
	}
	if eqp == nil {
		eqp = []byte("[]")
	}
	_, err := p.pool.Exec(p.ctx, `
		UPDATE accounts SET
			commander_xp=$2, soft_currency=$3, hard_currency=$4, summon_tickets=$5,
			party_ids=$6::jsonb, quest_flags=$7::jsonb, claimed_rewards=$8::jsonb, owned_heroes=$9::jsonb,
			afk_claimed_unix=$10, active_battle_id=$11, battle_seed=$12,
			balance_version=$13, battle_commands=$14::jsonb, battle_tick_approx=$15,
			hero_instances=$16::jsonb, inventory=$17::jsonb, vip_points=$18, vip_level=$19,
			pity_counters=$20::jsonb, guild_id=$21,
			gacha_history=$22::jsonb, test_purchase_day=$23, test_purchases_day=$24,
			test_hard_day=$25, test_vip_day=$26, vip_daily_claimed=$27,
			sidequest_progress=$28::jsonb, poi_progress=$29::jsonb, journal_flags=$30::jsonb,
			equipment_instances=$31::jsonb, equipment_pending=$32::jsonb,
			updated_at=NOW()
		WHERE account_id=$1`,
		acc.AccountID, acc.CommanderXP, acc.SoftCurrency, acc.HardCurrency, acc.SummonTickets,
		party, qf, cr, oh, acc.AFKClaimedUnix, acc.ActiveBattleID, acc.BattleSeed,
		acc.BalanceVersion, cmds, acc.BattleTickApprox,
		hi, inv, acc.VipPoints, acc.VipLevel, pity, acc.GuildID,
		gh, acc.TestPurchaseDay, acc.TestPurchasesDay, acc.TestHardDay, acc.TestVipDay, acc.VipDailyClaimed,
		sq, poi, jf, eqi, eqp,
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
		idx := CryptoPick(len(heroPool))
		heroID = heroPool[idx]
		EnsureHeroInstances(acc)
		newly = !acc.OwnedHeroes[heroID]
		acc.OwnedHeroes[heroID] = true
		if newly {
			acc.HeroInstances[heroID] = NewHeroInstance(heroID)
		} else {
			inst := acc.HeroInstances[heroID]
			if inst == nil {
				inst = NewHeroInstance(heroID)
				acc.HeroInstances[heroID] = inst
			}
			inst.Fragments++
			acc.SoftCurrency += DuplicateSoftRefund
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
		acc.BalanceVersion = "2026.11.19-monsters1"
		acc.BattleCommands = nil
		acc.BattleTickApprox = 0
		return nil
	})
	return
}

func (p *Postgres) AppendBattleCommand(token, battleID string, cmd BattleCommand) (*AccountProgress, error) {
	if cmd.Op != "ultimate" || cmd.UnitID == "" {
		return nil, ErrValidation
	}
	return p.mutate(token, func(acc *AccountProgress) error {
		if acc.ActiveBattleID == "" || acc.ActiveBattleID != battleID {
			return ErrNoActiveBattle
		}
		owned := false
		for _, id := range acc.PartyIDs {
			if id == cmd.UnitID {
				owned = true
				break
			}
		}
		if !owned {
			return ErrInvalidParty
		}
		if cmd.AtTick <= 0 {
			acc.BattleTickApprox++
			cmd.AtTick = acc.BattleTickApprox * 20
		} else if cmd.AtTick > acc.BattleTickApprox {
			acc.BattleTickApprox = cmd.AtTick
		}
		acc.BattleCommands = append(acc.BattleCommands, cmd)
		return nil
	})
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
		acc.BalanceVersion = ""
		acc.BattleCommands = nil
		acc.BattleTickApprox = 0
		return nil
	})
}

func (p *Postgres) LevelUpHero(token, heroID string, levels int, base HeroBaseStats) (*AccountProgress, *HeroInstance, error) {
	if heroID == "" || levels < 1 || levels > 10 {
		return nil, nil, ErrValidation
	}
	var out *HeroInstance
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		EnsureHeroInstances(acc)
		if !acc.OwnedHeroes[heroID] {
			return ErrNotOwned
		}
		inst := acc.HeroInstances[heroID]
		if inst == nil {
			inst = NewHeroInstance(heroID)
			acc.HeroInstances[heroID] = inst
		}
		cap := LevelCap(inst.AwakenRank)
		for i := 0; i < levels; i++ {
			if inst.Level >= cap {
				return ErrLevelCap
			}
			cost := SoftCostForLevel(inst.Level)
			if acc.SoftCurrency < cost {
				return ErrInsufficient
			}
			acc.SoftCurrency -= cost
			inst.Level++
		}
		inst.Power = ComputePower(base.HP, base.Atk, base.Defense, base.Speed, inst.Level, inst.Stars, inst.AwakenRank)
		cp := *inst
		out = &cp
		return nil
	})
	return prog, out, err
}

func (p *Postgres) StarUpHero(token, heroID string, base HeroBaseStats) (*AccountProgress, *HeroInstance, error) {
	if heroID == "" {
		return nil, nil, ErrValidation
	}
	var out *HeroInstance
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		EnsureHeroInstances(acc)
		if !acc.OwnedHeroes[heroID] {
			return ErrNotOwned
		}
		inst := acc.HeroInstances[heroID]
		if inst == nil {
			return ErrNotOwned
		}
		if inst.Stars >= MaxStarsDraft {
			return ErrStarCap
		}
		need := FragmentsPerStarDraft[inst.Stars]
		if inst.Fragments < need {
			return ErrInsufficient
		}
		inst.Fragments -= need
		inst.Stars++
		inst.Power = ComputePower(base.HP, base.Atk, base.Defense, base.Speed, inst.Level, inst.Stars, inst.AwakenRank)
		cp := *inst
		out = &cp
		return nil
	})
	return prog, out, err
}

func (p *Postgres) EquipHero(token, heroID, slot, itemID string, base HeroBaseStats) (*AccountProgress, *HeroInstance, error) {
	valid := map[string]bool{"weapon": true, "armor": true, "accessory": true, "relic": true}
	if heroID == "" || !valid[slot] {
		return nil, nil, ErrValidation
	}
	var out *HeroInstance
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		EnsureHeroInstances(acc)
		if !acc.OwnedHeroes[heroID] {
			return ErrNotOwned
		}
		inst := acc.HeroInstances[heroID]
		if inst == nil {
			inst = NewHeroInstance(heroID)
			acc.HeroInstances[heroID] = inst
		}
		if inst.Equipment == nil {
			inst.Equipment = map[string]string{}
		}
		if itemID != "" {
			if acc.Inventory[itemID] <= 0 && itemID != "starter_blade" && itemID != "starter_mail" && itemID != "starter_charm" {
				return ErrInsufficient
			}
		}
		inst.Equipment[slot] = itemID
		inst.Power = ComputePower(base.HP, base.Atk, base.Defense, base.Speed, inst.Level, inst.Stars, inst.AwakenRank)
		cp := *inst
		out = &cp
		return nil
	})
	return prog, out, err
}

var _ Store = (*Postgres)(nil)

func (p *Postgres) SpendSoft(token string, amount int) (*AccountProgress, error) {
	if amount < 0 {
		return nil, ErrValidation
	}
	return p.mutate(token, func(acc *AccountProgress) error {
		if acc.SoftCurrency < amount {
			return ErrInsufficient
		}
		acc.SoftCurrency -= amount
		return nil
	})
}

func (p *Postgres) ApplySimulatedPurchase(token, sku string, soft, hard, tickets int, inventory map[string]int) (*AccountProgress, bool, error) {
	if sku == "" {
		return nil, false, ErrValidation
	}
	already := false
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		key := "shop_sim:" + sku
		if acc.ClaimedRewards[key] {
			already = true
			return nil
		}
		acc.ClaimedRewards[key] = true
		acc.SoftCurrency += soft
		acc.HardCurrency += hard
		acc.SummonTickets += tickets
		EnsureHeroInstances(acc)
		for k, v := range inventory {
			acc.Inventory[k] += v
		}
		return nil
	})
	return prog, already, err
}

func (p *Postgres) SummonBanner(token, bannerID string, count int, poolByRarity map[string][]string) (*AccountProgress, []GachaPullResult, error) {
	if count != 1 && count != 10 {
		return nil, nil, ErrValidation
	}
	rates := StandardRates
	softEvery, hardEvery := 0, 0
	pityKey := ""
	switch bannerID {
	case BannerStandard:
		rates = StandardRates
	case BannerAdvanced:
		rates = AdvancedRates
		softEvery, hardEvery = PitySoftSREvery, PityHardSSREvery
		pityKey = "advanced"
	default:
		return nil, nil, ErrValidation
	}
	var results []GachaPullResult
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		if acc.SummonTickets < count {
			return ErrNoTickets
		}
		acc.SummonTickets -= count
		EnsureHeroInstances(acc)
		if acc.PityCounters == nil {
			acc.PityCounters = map[string]int{}
		}
		soft := acc.PityCounters[pityKey+"_soft"]
		hard := acc.PityCounters[pityKey+"_hard"]
		for i := 0; i < count; i++ {
			rarity := RollRarity(rates)
			forced := ""
			if pityKey != "" {
				rarity, forced, soft, hard = ApplyPity(rarity, soft, hard, softEvery, hardEvery)
			}
			heroID := PickHeroByRarity(poolByRarity, rarity)
			if heroID == "" {
				return ErrValidation
			}
			newly := !acc.OwnedHeroes[heroID]
			acc.OwnedHeroes[heroID] = true
			if newly {
				acc.HeroInstances[heroID] = NewHeroInstance(heroID)
			} else {
				inst := acc.HeroInstances[heroID]
				if inst == nil {
					inst = NewHeroInstance(heroID)
					acc.HeroInstances[heroID] = inst
				}
				inst.Fragments++
				acc.SoftCurrency += DuplicateSoftRefund
			}
			results = append(results, GachaPullResult{HeroID: heroID, Rarity: rarity, NewlyOwned: newly, PityForced: forced})
			acc.GachaHistory = append(acc.GachaHistory, GachaHistoryEntry{
				BannerID: bannerID, HeroID: heroID, Rarity: rarity, NewlyOwned: newly, At: time.Now().UTC().Format(time.RFC3339),
			})
			if len(acc.GachaHistory) > 100 {
				acc.GachaHistory = acc.GachaHistory[len(acc.GachaHistory)-100:]
			}
		}
		if pityKey != "" {
			acc.PityCounters[pityKey+"_soft"] = soft
			acc.PityCounters[pityKey+"_hard"] = hard
		}
		return nil
	})
	return prog, results, err
}

func (p *Postgres) TestPurchase(token, sku string, soft, hard, tickets, vipPoints int, inventory map[string]int) (*AccountProgress, map[string]any, error) {
	if sku == "" {
		return nil, nil, ErrValidation
	}
	meta := map[string]any{}
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		day := time.Now().UTC().Format("2006-01-02")
		if acc.TestPurchaseDay != day {
			acc.TestPurchaseDay = day
			acc.TestPurchasesDay = 0
			acc.TestHardDay = 0
			acc.TestVipDay = 0
		}
		if acc.TestPurchasesDay >= TestMaxPurchasesPerDay {
			return ErrInsufficient
		}
		if acc.TestHardDay+hard > TestMaxHardPerDay {
			return ErrInsufficient
		}
		if acc.TestVipDay+vipPoints > TestMaxVipPerDay {
			return ErrInsufficient
		}
		acc.TestPurchasesDay++
		acc.TestHardDay += hard
		acc.TestVipDay += vipPoints
		acc.SoftCurrency += soft
		acc.HardCurrency += hard
		acc.SummonTickets += tickets
		acc.VipPoints += vipPoints
		acc.VipLevel = ComputeVIPLevel(acc.VipPoints)
		EnsureHeroInstances(acc)
		for k, v := range inventory {
			acc.Inventory[k] += v
		}
		key := "TEST_PURCHASE:" + sku + ":" + day + ":" + strconv.Itoa(acc.TestPurchasesDay)
		acc.ClaimedRewards[key] = true
		meta["transaction_type"] = "TEST_PURCHASE"
		meta["sku"] = sku
		meta["test_purchases_today"] = acc.TestPurchasesDay
		meta["not_real_revenue"] = true
		return nil
	})
	return prog, meta, err
}

func (p *Postgres) ClaimVIPDaily(token string, soft, tickets int) (*AccountProgress, bool, error) {
	already := false
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		day := time.Now().UTC().Format("2006-01-02")
		if acc.VipDailyClaimed == day {
			already = true
			return nil
		}
		acc.VipDailyClaimed = day
		acc.SoftCurrency += soft
		acc.SummonTickets += tickets
		return nil
	})
	return prog, already, err
}

func (p *Postgres) SkillUpHero(token, heroID, skillID string, base HeroBaseStats, defs map[string]EquipmentDef) (*AccountProgress, *HeroInstance, error) {
	var out *HeroInstance
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		bonus := map[string]int{}
		if inst := acc.HeroInstances[heroID]; inst != nil {
			bonus = GearBonusForHero(inst, defs)
		}
		inst, e := ApplySkillUp(acc, heroID, skillID, base, bonus)
		out = inst
		return e
	})
	return prog, out, err
}

func (p *Postgres) EquipHeroUnique(token, heroID, slot, itemID string, base HeroBaseStats, defs map[string]EquipmentDef) (*AccountProgress, *HeroInstance, error) {
	var out *HeroInstance
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		inst, e := ApplyEquipUnique(acc, heroID, slot, itemID, base, defs)
		out = inst
		return e
	})
	return prog, out, err
}

func (p *Postgres) StartSidequest(token, questID, requiredMain string) (*AccountProgress, error) {
	return p.mutate(token, func(acc *AccountProgress) error {
		return ApplySidequestStart(acc, questID, requiredMain, func(q string) bool {
			return acc.QuestFlags[q]
		})
	})
}

func (p *Postgres) InteractPOI(token, poiID, actionID, stepID, sidequestID string, sequence []string, completionFlag string, oneTime bool, rewardBundle *ExpansionRewardBundle, equipmentDefs map[string]EquipmentDef) (*AccountProgress, bool, map[string]any, error) {
	reset := false
	var granted map[string]any
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		r, g, e := ApplyPOIInteract(acc, poiID, actionID, stepID, sidequestID, sequence, completionFlag, oneTime, rewardBundle, equipmentDefs)
		reset = r
		granted = g
		return e
	})
	return prog, reset, granted, err
}

func (p *Postgres) ClaimSidequest(token, questID string, requiredSteps []string, bundle ExpansionRewardBundle, defs map[string]EquipmentDef, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, bool, map[string]any, error) {
	already := false
	var granted map[string]any
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		a, g, e := ApplySidequestClaim(acc, questID, requiredSteps, bundle, defs, templates, bal)
		already = a
		granted = g
		return e
	})
	return prog, already, granted, err
}

func (p *Postgres) idempotent(acc *AccountProgress, requestID string, action func() (map[string]any, error)) (map[string]any, error) {
	EnsureEquipment(acc)
	if requestID == "" {
		return action()
	}
	if prev, ok := acc.Idempotency[requestID]; ok {
		return prev, nil
	}
	out, err := action()
	if err != nil {
		return nil, err
	}
	acc.Idempotency[requestID] = out
	return out, nil
}

func (p *Postgres) EquipInstance(token, instanceID, heroID, slot string, confirmTransfer bool, expectedVersion int, requestID string, base HeroBaseStats, heroClass string, templates map[string]EquipmentTemplate, sets map[string]EquipmentSetDef, bal EquipmentBalance) (*AccountProgress, *EquipmentInstance, map[string]any, error) {
	var outInst *EquipmentInstance
	var extras map[string]any
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		EnsureEquipment(acc)
		MigrateLegacyEquipment(acc, templates, bal.Aliases, bal.InventoryCapacity)
		payload, e := p.idempotent(acc, requestID, func() (map[string]any, error) {
			lvl := 1
			if hi := acc.HeroInstances[heroID]; hi != nil {
				lvl = hi.Level
			}
			eq, err2 := EquipInstance(acc, instanceID, heroID, slot, confirmTransfer, expectedVersion, lvl, heroClass, templates)
			if err2 != nil {
				return nil, err2
			}
			flat, pct, counts := ComputeHeroGearFlat(acc, heroID, templates, sets, bal.UpgradeGrowth)
			if hi := acc.HeroInstances[heroID]; hi != nil {
				hi.Power = ComputePowerWithGear(base, hi, flat)
			}
			outInst = eq
			return map[string]any{"instance": eq, "flat": flat, "set_pct": pct, "set_counts": counts}, nil
		})
		extras = payload
		if payload != nil {
			if inst, ok := payload["instance"].(*EquipmentInstance); ok {
				outInst = inst
			}
		}
		return e
	})
	return prog, outInst, extras, err
}

func (p *Postgres) UnequipInstance(token, instanceID string, expectedVersion int, requestID string) (*AccountProgress, *EquipmentInstance, error) {
	var out *EquipmentInstance
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		_, e := p.idempotent(acc, requestID, func() (map[string]any, error) {
			eq, err2 := UnequipInstance(acc, instanceID, expectedVersion)
			if err2 != nil {
				return nil, err2
			}
			out = eq
			return map[string]any{"instance": eq}, nil
		})
		return e
	})
	return prog, out, err
}

func (p *Postgres) UpgradeInstance(token, instanceID string, expectedVersion int, requestID string, base HeroBaseStats, templates map[string]EquipmentTemplate, sets map[string]EquipmentSetDef, bal EquipmentBalance) (*AccountProgress, *EquipmentInstance, map[string]any, error) {
	var out *EquipmentInstance
	var extras map[string]any
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		payload, e := p.idempotent(acc, requestID, func() (map[string]any, error) {
			eq, cost, err2 := UpgradeInstance(acc, instanceID, expectedVersion, bal, templates)
			if err2 != nil {
				return nil, err2
			}
			if eq.EquippedHeroID != "" {
				if hi := acc.HeroInstances[eq.EquippedHeroID]; hi != nil {
					flat, _, _ := ComputeHeroGearFlat(acc, eq.EquippedHeroID, templates, sets, bal.UpgradeGrowth)
					hi.Power = ComputePowerWithGear(base, hi, flat)
				}
			}
			out = eq
			return map[string]any{"instance": eq, "cost": cost}, nil
		})
		extras = payload
		return e
	})
	return prog, out, extras, err
}

func (p *Postgres) LockInstance(token, instanceID string, locked bool, expectedVersion int, requestID string) (*AccountProgress, *EquipmentInstance, error) {
	var out *EquipmentInstance
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		_, e := p.idempotent(acc, requestID, func() (map[string]any, error) {
			eq, err2 := LockInstance(acc, instanceID, locked, expectedVersion)
			if err2 != nil {
				return nil, err2
			}
			out = eq
			return map[string]any{"instance": eq}, nil
		})
		return e
	})
	return prog, out, err
}

func (p *Postgres) SalvageInstance(token, instanceID string, expectedVersion int, requestID string, confirm bool, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, map[string]any, error) {
	if !confirm {
		return nil, nil, ErrValidation
	}
	var reward map[string]any
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		payload, e := p.idempotent(acc, requestID, func() (map[string]any, error) {
			r, err2 := SalvageInstance(acc, instanceID, expectedVersion, bal, templates)
			if err2 != nil {
				return nil, err2
			}
			return map[string]any{"reward": r}, nil
		})
		if payload != nil {
			if r, ok := payload["reward"].(map[string]any); ok {
				reward = r
			}
		}
		return e
	})
	return prog, reward, err
}

func (p *Postgres) GrantEquipmentReward(token, rewardKey, templateID, source string, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, *EquipmentInstance, error) {
	var out *EquipmentInstance
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		inst, e := GrantEquipmentOnce(acc, rewardKey, templateID, source, templates, bal)
		out = inst
		return e
	})
	return prog, out, err
}

func (p *Postgres) MigrateLegacyEquipment(token string, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, int, error) {
	created := 0
	prog, err := p.mutate(token, func(acc *AccountProgress) error {
		created = MigrateLegacyEquipment(acc, templates, bal.Aliases, bal.InventoryCapacity)
		return nil
	})
	return prog, created, err
}
