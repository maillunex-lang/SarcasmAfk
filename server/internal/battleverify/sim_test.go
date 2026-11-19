package battleverify_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/battleverify"
)

func TestSimulateATBDeterministic(t *testing.T) {
	heroes := []map[string]any{
		{"id": "H01", "name": "A", "row": "front", "hp": 1200, "atk": 180, "defense": 90, "speed": 110},
		{"id": "H02", "name": "B", "row": "back", "hp": 900, "atk": 120, "defense": 70, "speed": 100},
	}
	enemies := []map[string]any{
		{"id": "E1", "name": "X", "row": "front", "hp": 1200, "atk": 95, "defense": 25, "speed": 120},
		{"id": "E2", "name": "Y", "row": "front", "hp": 1200, "atk": 95, "defense": 25, "speed": 121},
	}
	a := battleverify.SimulateATB(42, heroes, enemies)
	b := battleverify.SimulateATB(42, heroes, enemies)
	if a.Victory != b.Victory || a.Ticks != b.Ticks {
		t.Fatalf("non-deterministic: %#v vs %#v", a, b)
	}
	if a.Ticks <= 0 {
		t.Fatal("expected ticks")
	}
	// Strong party should win B01-like trash
	if !a.Victory {
		t.Fatalf("expected victory got %#v", a)
	}
}

func TestCheckFinishSimTooFast(t *testing.T) {
	_, code := battleverify.CheckFinishSim(1, 10, nil, nil, true)
	if code != "BATTLE_TOO_FAST" {
		t.Fatalf("got %s", code)
	}
}
