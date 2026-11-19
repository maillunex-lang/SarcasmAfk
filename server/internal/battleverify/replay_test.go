package battleverify_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/battleverify"
)

func TestReplayIgnoresEmptyAndIsDeterministic(t *testing.T) {
	heroes := []map[string]any{
		{"id": "H01", "name": "A", "row": "front", "hp": 1200, "atk": 180, "defense": 90, "speed": 110, "ultimate_id": "rulebreak", "energy_max": 100},
	}
	enemies := []map[string]any{
		{"id": "E1", "name": "X", "row": "front", "hp": 200, "atk": 40, "defense": 10, "speed": 80},
	}
	in := battleverify.ReplayInput{
		Seed: 99, BalanceVersion: battleverify.BalanceVersion,
		PartyIDs: []string{"H01"}, Heroes: heroes, Enemies: enemies,
		AutoCast: true, DurationMS: 1000,
	}
	a := battleverify.SimulateReplay(in)
	b := battleverify.SimulateReplay(in)
	if a.Victory != b.Victory || a.Ticks != b.Ticks {
		t.Fatalf("nondeterministic %#v %#v", a, b)
	}
	if !a.Victory {
		t.Fatalf("expected win %#v", a)
	}
}

func TestFinishReplayTooFast(t *testing.T) {
	_, code := battleverify.CheckFinishReplay(battleverify.ReplayInput{DurationMS: 10})
	if code != "BATTLE_TOO_FAST" {
		t.Fatalf("got %s", code)
	}
}
