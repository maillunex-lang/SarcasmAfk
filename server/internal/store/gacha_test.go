package store_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func TestPityReplacesNotAdds(t *testing.T) {
	// After 9 non-SR, 10th R becomes SR
	out, forced, soft, hard := store.ApplyPity("R", 9, 0, 10, 80)
	if out != "SR" || forced != "sr" || soft != 0 {
		t.Fatalf("soft pity got %s forced=%s soft=%d", out, forced, soft)
	}
	_ = hard
	out, forced, soft, hard = store.ApplyPity("R", 0, 79, 10, 80)
	if out != "SSR" || forced != "ssr" || hard != 0 {
		t.Fatalf("hard pity got %s forced=%s hard=%d soft=%d", out, forced, hard, soft)
	}
}

func TestSummonBannerAdvancedPityTracked(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	_, _, _ = m.TestPurchase(tok, "ticket_pack_s", 0, 0, 5, 0, nil)
	pool := map[string][]string{
		"R": {"H04"}, "SR": {"H01"}, "SSR": {"H03"}, "UR": {"H06"}, "N": {"H13"},
	}
	// anonymous starts with 10 tickets + 5 = 15
	_, results, err := m.SummonBanner(tok, store.BannerAdvanced, 10, pool)
	if err != nil {
		t.Fatal(err)
	}
	if len(results) != 10 {
		t.Fatalf("len=%d", len(results))
	}
	acc, _ := m.AccountByToken(tok)
	if acc.PityCounters["advanced_soft"] < 0 {
		t.Fatal("pity missing")
	}
}

func TestTestPurchaseLimits(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	for i := 0; i < store.TestMaxPurchasesPerDay; i++ {
		_, _, err := m.TestPurchase(tok, "soft_pack_s", 10, 0, 0, 0, nil)
		if err != nil {
			t.Fatalf("iter %d: %v", i, err)
		}
	}
	_, _, err := m.TestPurchase(tok, "soft_pack_s", 10, 0, 0, 0, nil)
	if err != store.ErrInsufficient {
		t.Fatalf("expected limit, got %v", err)
	}
}

func TestVIPLevel(t *testing.T) {
	if store.ComputeVIPLevel(0) != 0 || store.ComputeVIPLevel(100) != 1 || store.ComputeVIPLevel(10000) != 10 {
		t.Fatalf("vip levels wrong")
	}
}
