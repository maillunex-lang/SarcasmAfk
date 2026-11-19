package store_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func TestPersistSessionsSurviveReload(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "accounts.json")
	m1 := store.NewMemory(path)
	tok, prog := m1.CreateAnonymous()
	if tok == "" || prog.AccountID == "" {
		t.Fatal("empty auth")
	}
	if _, err := os.Stat(path); err != nil {
		t.Fatalf("persist file missing: %v", err)
	}

	m2 := store.NewMemory(path)
	got, err := m2.AccountByToken(tok)
	if err != nil {
		t.Fatalf("token not restored: %v", err)
	}
	if got.AccountID != prog.AccountID {
		t.Fatalf("account mismatch %s vs %s", got.AccountID, prog.AccountID)
	}
}

func TestFinishRequiresStart(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	_, err := m.FinishBattle(tok, "B01", true)
	if err != store.ErrNoActiveBattle {
		t.Fatalf("expected ErrNoActiveBattle, got %v", err)
	}
	if _, err := m.StartBattle(tok, "B01", nil); err != nil {
		t.Fatal(err)
	}
	if _, err := m.FinishBattle(tok, "B01", true); err != nil {
		t.Fatalf("finish after start: %v", err)
	}
	_, err = m.FinishBattle(tok, "B01", true)
	if err != store.ErrNoActiveBattle {
		t.Fatalf("second finish should fail: %v", err)
	}
}
