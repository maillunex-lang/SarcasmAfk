package battleverify_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/battleverify"
)

func TestEstimateVictory(t *testing.T) {
	if !battleverify.EstimateVictory(0, 1000, 100) {
		t.Fatal("strong party should win")
	}
	if battleverify.EstimateVictory(0, 10, 10000) {
		t.Fatal("weak party should lose")
	}
}

func TestCheckFinish(t *testing.T) {
	_, code := battleverify.CheckFinish(1, 100, 1000, 100, true)
	if code != "BATTLE_TOO_FAST" {
		t.Fatalf("expected BATTLE_TOO_FAST got %s", code)
	}
	v, code := battleverify.CheckFinish(1, 500, 1000, 100, true)
	if code != "" || !v {
		t.Fatalf("expected ok victory got v=%v code=%s", v, code)
	}
	_, code = battleverify.CheckFinish(1, 500, 10, 10000, true)
	if code != "RESULT_MISMATCH" {
		t.Fatalf("expected RESULT_MISMATCH got %s", code)
	}
}
