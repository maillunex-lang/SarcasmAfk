package battleverify_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/battleverify"
)

func heroStub() map[string]any {
	return map[string]any{
		"id": "H01", "name": "Kaeron", "hp": 1200, "atk": 180, "defense": 90, "speed": 110,
		"row": "front", "energy_max": 100, "ultimate_id": "rulebreak",
	}
}

func TestEnemyMarkAndDeterministicReplay(t *testing.T) {
	heroes := []map[string]any{heroStub()}
	enemies := []map[string]any{{
		"id": "E01", "name": "Ticket", "hp": 400, "atk": 80, "defense": 20, "speed": 100, "row": "front",
		"archetype": "SWARM",
		"basic":     map[string]any{"kind": "atk_front", "multiplier": 1.05},
		"special":   map[string]any{"kind": "MARK", "value": 0.20, "cooldown_actions": 2, "proc_chance": 1.0},
	}}
	a := battleverify.SimulateATB(42, heroes, enemies)
	b := battleverify.SimulateATB(42, heroes, enemies)
	if a.Victory != b.Victory || a.Ticks != b.Ticks {
		t.Fatalf("nondeterministic a=%+v b=%+v", a, b)
	}
}

func TestBossE20PhaseOnce(t *testing.T) {
	heroes := []map[string]any{
		heroStub(),
		{"id": "H04", "name": "Tank", "hp": 2000, "atk": 100, "defense": 150, "speed": 90, "row": "front", "energy_max": 100},
		{"id": "H02", "name": "Heal", "hp": 1100, "atk": 80, "defense": 70, "speed": 100, "row": "back", "energy_max": 100, "ultimate_id": "emergency_repair"},
	}
	enemies := []map[string]any{{
		"id": "E20", "name": "Boss", "hp": 3000, "atk": 140, "defense": 100, "speed": 95, "row": "front",
		"special": map[string]any{"kind": "BOSS_E20", "proc_chance": 1.0},
	}}
	r1 := battleverify.SimulateATB(7, heroes, enemies)
	r2 := battleverify.SimulateATB(7, heroes, enemies)
	if r1.Ticks != r2.Ticks || r1.Victory != r2.Victory {
		t.Fatalf("boss nondeterministic %+v %+v", r1, r2)
	}
}

func TestBossE30Deterministic(t *testing.T) {
	heroes := []map[string]any{heroStub(), {
		"id": "H03", "name": "Mage", "hp": 1000, "atk": 200, "defense": 60, "speed": 115,
		"row": "back", "energy_max": 100, "ultimate_id": "paragraph_oblivion",
	}}
	enemies := []map[string]any{{
		"id": "E30", "name": "Final", "hp": 5000, "atk": 160, "defense": 120, "speed": 90, "row": "front",
		"special": map[string]any{"kind": "BOSS_E30"},
	}}
	a := battleverify.SimulateATB(99, heroes, enemies)
	b := battleverify.SimulateATB(99, heroes, enemies)
	if a.Ticks != b.Ticks || a.Victory != b.Victory {
		t.Fatalf("E30 nondeterministic")
	}
}
