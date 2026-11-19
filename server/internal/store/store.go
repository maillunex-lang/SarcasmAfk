package store

// Store is the account/progress backend (memory, postgres, …).
type Store interface {
	CreateAnonymous() (token string, progress AccountProgress)
	AccountByToken(token string) (*AccountProgress, error)
	SetParty(token string, party []string) (*AccountProgress, error)
	ClaimReward(token, bundleID string, soft, xp int) (softDelta, xpDelta int, already bool, err error)
	ClaimAFK(token string, softPerHour, xpPerHour int) (hours float64, soft, xp int, err error)
	Summon(token string, heroPool []string) (heroID string, newly bool, err error)
	StartBattle(token, battleID string, party []string) (seed int64, err error)
	AppendBattleCommand(token, battleID string, cmd BattleCommand) (*AccountProgress, error)
	FinishBattle(token, battleID string, victory bool) (*AccountProgress, error)
}

// Ensure implementations satisfy the interface at compile time.
var (
	_ Store = (*Memory)(nil)
)
