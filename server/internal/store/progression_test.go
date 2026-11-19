package store_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func TestLevelUpSpendsSoftAndRaisesPower(t *testing.T) {
	m := store.NewMemory("")
	tok, prog := m.CreateAnonymous()
	if prog.SoftCurrency < store.StartingSoftDraft {
		t.Fatalf("expected starting soft %d got %d", store.StartingSoftDraft, prog.SoftCurrency)
	}
	base := store.HeroBaseStats{HP: 1200, Atk: 180, Defense: 90, Speed: 110}
	before := prog.SoftCurrency
	out, inst, err := m.LevelUpHero(tok, "H01", 1, base)
	if err != nil {
		t.Fatal(err)
	}
	if inst.Level != 2 {
		t.Fatalf("level=%d", inst.Level)
	}
	cost := store.SoftCostForLevel(1)
	if out.SoftCurrency != before-cost {
		t.Fatalf("soft %d want %d", out.SoftCurrency, before-cost)
	}
	if inst.Power <= 0 {
		t.Fatal("power not computed")
	}
}

func TestLevelUpRejectsUnowned(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	_, _, err := m.LevelUpHero(tok, "H99", 1, store.HeroBaseStats{})
	if err != store.ErrNotOwned {
		t.Fatalf("got %v", err)
	}
}

func TestCryptoPickInRange(t *testing.T) {
	for i := 0; i < 50; i++ {
		v := store.CryptoPick(7)
		if v < 0 || v >= 7 {
			t.Fatalf("out of range %d", v)
		}
	}
}

func TestChatSanitizeAndRate(t *testing.T) {
	h := store.NewChatHub()
	msg, err := h.Post("global", "acc1", "A", "<script>x</script> hello", 1)
	if err != nil {
		t.Fatal(err)
	}
	if containsAngle(msg.Body) {
		t.Fatalf("html not stripped: %q", msg.Body)
	}
	_, err = h.Post("global", "acc1", "A", "second", 1)
	if err == nil {
		t.Fatal("expected rate limit")
	}
}

func containsAngle(s string) bool {
	for _, r := range s {
		if r == '<' || r == '>' {
			return true
		}
	}
	return false
}

func TestGuildCreateJoin(t *testing.T) {
	h := store.NewGuildHub()
	g, err := h.Create("acc_leader", "Тестовая", "TST", "desc")
	if err != nil {
		t.Fatal(err)
	}
	if g.Tag != "TST" {
		t.Fatalf("tag %s", g.Tag)
	}
	if _, err := h.Join("acc2", g.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := h.Create("acc2", "Other", "OTH", ""); err == nil {
		t.Fatal("member cannot create another")
	}
}
