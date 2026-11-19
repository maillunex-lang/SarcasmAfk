package battleverify

// Draft status effects for MONSTERS-CH01-001 (balance_version gated).
// Values are Draft for testing; tune via EnemyBalance.

type statusKind string

const (
	stGuard  statusKind = "GUARD"
	stMark   statusKind = "MARK"
	stSlow   statusKind = "SLOW"
	stWeaken statusKind = "WEAKEN"
	stShield statusKind = "SHIELD"
	stBurn   statusKind = "BURN"
)

type statusEffect struct {
	Kind     statusKind
	Actions  int // remaining actions of the affected unit
	ShieldHP int // for SHIELD
	Source   string
}

// EnemyBalance holds Draft knobs (public for tests/docs).
type EnemyBalance struct {
	GuardDEFBonus      float64
	MarkIncomingBonus  float64
	SlowSpeedPenalty   float64
	WeakenATKPenalty   float64
	ShieldMaxHPFrac    float64
	BurnMaxHPFrac      float64
	BurnTickCap        float64
	HealMaxHPFrac      float64
	DisruptEnergyFrac  float64
	SpecialProcNormal  float64
	SpecialProcElite   float64
	SpecialCooldown     int
}

func defaultEnemyBalance() EnemyBalance {
	return EnemyBalance{
		GuardDEFBonus: 0.20, MarkIncomingBonus: 0.12, SlowSpeedPenalty: 0.15,
		WeakenATKPenalty: 0.12, ShieldMaxHPFrac: 0.12, BurnMaxHPFrac: 0.03,
		BurnTickCap: 0.04, HealMaxHPFrac: 0.10, DisruptEnergyFrac: 0.15,
		SpecialProcNormal: 0.25, SpecialProcElite: 0.35, SpecialCooldown: 3,
	}
}

func (u *unit) addStatus(kind statusKind, actions int, shieldHP int, source string) {
	// Non-stacking same kind: refresh
	for i := range u.statuses {
		if u.statuses[i].Kind == kind {
			u.statuses[i].Actions = actions
			if kind == stShield {
				u.statuses[i].ShieldHP = shieldHP
			}
			u.statuses[i].Source = source
			return
		}
	}
	u.statuses = append(u.statuses, statusEffect{Kind: kind, Actions: actions, ShieldHP: shieldHP, Source: source})
}

func (u *unit) hasStatus(kind statusKind) bool {
	for _, s := range u.statuses {
		if s.Kind == kind && s.Actions > 0 {
			return true
		}
	}
	return false
}

func (u *unit) tickStatusesAfterAction() {
	out := u.statuses[:0]
	for _, s := range u.statuses {
		s.Actions--
		if s.Actions > 0 {
			out = append(out, s)
		}
	}
	u.statuses = out
}

func (u *unit) effectiveATK(bal EnemyBalance) int {
	atk := float64(u.atk)
	if u.hasStatus(stWeaken) {
		atk *= (1.0 - bal.WeakenATKPenalty)
	}
	if u.nextStrikeBonus > 0 {
		atk *= (1.0 + u.nextStrikeBonus)
	}
	v := int(atk)
	if v < 1 {
		v = 1
	}
	return v
}

func (u *unit) effectiveDEF(bal EnemyBalance) int {
	def := float64(u.def)
	if u.hasStatus(stGuard) {
		def *= (1.0 + bal.GuardDEFBonus)
	}
	return int(def)
}

func (u *unit) effectiveSpeed(bal EnemyBalance) int {
	spd := float64(u.speed)
	if u.hasStatus(stSlow) {
		spd *= (1.0 - bal.SlowSpeedPenalty)
	}
	v := int(spd)
	if v < 1 {
		v = 1
	}
	return v
}

func applyBurnTicks(pool []*unit, bal EnemyBalance) {
	for _, u := range pool {
		if !u.alive || !u.hasStatus(stBurn) {
			continue
		}
		frac := bal.BurnMaxHPFrac
		if frac > bal.BurnTickCap {
			frac = bal.BurnTickCap
		}
		dmg := int(float64(u.maxHP) * frac)
		if dmg < 1 {
			dmg = 1
		}
		// burn bypasses shield lightly but still reduces HP
		u.hp -= dmg
		if u.hp <= 0 {
			u.hp = 0
			u.alive = false
		}
	}
}

func takeDamageBalanced(u *unit, raw int, bal EnemyBalance) {
	if u.hasStatus(stMark) {
		raw = int(float64(raw) * (1.0 + bal.MarkIncomingBonus))
	}
	mitigated := raw - int(float64(u.effectiveDEF(bal))*0.35)
	if mitigated < 1 {
		mitigated = 1
	}
	// Absorb into SHIELD first
	for i := range u.statuses {
		if u.statuses[i].Kind == stShield && u.statuses[i].ShieldHP > 0 {
			if mitigated <= u.statuses[i].ShieldHP {
				u.statuses[i].ShieldHP -= mitigated
				mitigated = 0
			} else {
				mitigated -= u.statuses[i].ShieldHP
				u.statuses[i].ShieldHP = 0
				u.statuses[i].Actions = 0
			}
			break
		}
	}
	if mitigated <= 0 {
		return
	}
	u.hp -= mitigated
	if u.hp <= 0 {
		u.hp = 0
		u.alive = false
		u.energy = 0
	}
}

func healUnit(u *unit, frac float64) {
	if !u.alive {
		return
	}
	heal := int(float64(u.maxHP) * frac)
	u.hp += heal
	if u.hp > u.maxHP {
		u.hp = u.maxHP
	}
}

func lowestHP(pool []*unit) *unit {
	var best *unit
	for _, u := range pool {
		if !u.alive {
			continue
		}
		if best == nil || float64(u.hp)/float64(u.maxHP) < float64(best.hp)/float64(best.maxHP) {
			best = u
		}
	}
	return best
}

func pickBack(pool []*unit, rng interface{ Intn(int) int }) *unit {
	var back, any []*unit
	for _, u := range pool {
		if !u.alive {
			continue
		}
		any = append(any, u)
		if u.row == "back" {
			back = append(back, u)
		}
	}
	choices := back
	if len(choices) == 0 {
		choices = any
	}
	if len(choices) == 0 {
		return nil
	}
	return choices[rng.Intn(len(choices))]
}
