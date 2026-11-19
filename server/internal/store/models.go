package store

import "time"

// AccountProgress matches docs/PHASE0_SPEC.md §3.1 (extended for Phase 2 mocks).
type AccountProgress struct {
	AccountID       string          `json:"account_id"`
	CommanderXP     int             `json:"commander_xp"`
	SoftCurrency    int             `json:"soft_currency"`
	HardCurrency    int             `json:"hard_currency"`
	SummonTickets   int             `json:"summon_tickets"`
	PartyIDs        []string        `json:"party_ids"`
	QuestFlags      map[string]bool `json:"quest_flags"`
	ClaimedRewards  map[string]bool `json:"claimed_rewards"`
	OwnedHeroes     map[string]bool `json:"owned_heroes"`
	AFKClaimedUnix  int64           `json:"afk_claimed_unix"`
	ActiveBattleID  string          `json:"active_battle_id,omitempty"`
	BattleSeed      int64           `json:"battle_seed,omitempty"`
	UpdatedAt       string          `json:"updated_at"`
}

type Session struct {
	Token     string    `json:"token"`
	AccountID string    `json:"account_id"`
	CreatedAt time.Time `json:"created_at"`
}

type GuildStub struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Role    string `json:"role"`
	Members int    `json:"members"`
	Cap     int    `json:"cap"`
}

type ArenaStub struct {
	Rank   string `json:"rank"`
	Points int    `json:"points"`
	Rival  string `json:"rival"`
}

type EventStub struct {
	ID     string `json:"id"`
	Title  string `json:"title"`
	City   string `json:"city"`
	Status string `json:"status"`
	Tone   string `json:"tone"`
}
