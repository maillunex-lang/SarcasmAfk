package battleverify

// BalanceVersion pins content/sim formula for replays (bump when combat math changes).
const BalanceVersion = "2026.11.19-monsters1"

// Command is a validated player input in a battle replay.
type Command struct {
	Op     string `json:"op"` // ultimate
	UnitID string `json:"unit_id"`
	AtTick int    `json:"at_tick"`
}

// ReplayInput is the full authoritative battle package.
type ReplayInput struct {
	Seed           int64            `json:"seed"`
	BalanceVersion string           `json:"balance_version"`
	PartyIDs       []string         `json:"party_ids"`
	Heroes         []map[string]any `json:"heroes"`
	Enemies        []map[string]any `json:"enemies"`
	Commands       []Command        `json:"commands"`
	AutoCast       bool             `json:"auto_cast"` // default true (D-COMBAT-02)
	DurationMS     int              `json:"duration_ms"`
}

// ReplayResult extends SimResult with replay metadata.
type ReplayResult struct {
	SimResult
	BalanceVersion string    `json:"balance_version"`
	PartyIDs       []string  `json:"party_ids"`
	Commands       []Command `json:"commands"`
	AutoCast       bool      `json:"auto_cast"`
}

// SimulateReplay runs deterministic ATB with optional manual ultimate commands.
// AutoCast=true (default): cast when energy full unless a pending command for that unit fires first when ready.
func SimulateReplay(in ReplayInput) ReplayResult {
	auto := in.AutoCast
	if !in.AutoCast && len(in.Commands) == 0 {
		// empty commands + explicit false → still auto for safety baseline
		auto = true
	}
	if in.BalanceVersion == "" {
		in.BalanceVersion = BalanceVersion
	}
	res := simulateATB(in.Seed, in.Heroes, in.Enemies, auto, in.Commands)
	return ReplayResult{
		SimResult:      res,
		BalanceVersion: in.BalanceVersion,
		PartyIDs:       append([]string{}, in.PartyIDs...),
		Commands:       append([]Command{}, in.Commands...),
		AutoCast:       auto,
	}
}

// CheckFinishReplay validates duration then runs authoritative replay (ignores client victory).
func CheckFinishReplay(in ReplayInput) (ReplayResult, string) {
	if in.DurationMS < MinDurationMS {
		return ReplayResult{}, "BATTLE_TOO_FAST"
	}
	if in.BalanceVersion != "" && in.BalanceVersion != BalanceVersion {
		return ReplayResult{}, "BALANCE_VERSION_MISMATCH"
	}
	in.BalanceVersion = BalanceVersion
	if !in.AutoCast && len(in.Commands) == 0 {
		in.AutoCast = true
	}
	return SimulateReplay(in), ""
}
