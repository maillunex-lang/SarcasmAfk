package store_test

import (
	"context"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func TestPostgresRedisRoundTrip(t *testing.T) {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		t.Skip("DATABASE_URL not set")
	}
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "127.0.0.1:6379"
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	pg, err := store.OpenPostgres(ctx, dsn, redisAddr)
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	defer pg.Close()

	_, file, _, _ := runtime.Caller(0)
	mig := filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "migrations"))
	if err := pg.Migrate(mig); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	tok, prog := pg.CreateAnonymous()
	if tok == "" || prog.AccountID == "" {
		t.Fatal("empty create")
	}
	got, err := pg.AccountByToken(tok)
	if err != nil {
		t.Fatal(err)
	}
	if got.AccountID != prog.AccountID {
		t.Fatalf("account mismatch")
	}
	soft, xp, already, err := pg.ClaimReward(tok, "PG-TEST-BUNDLE", 40, 4)
	if err != nil || already || soft != 40 || xp != 4 {
		t.Fatalf("claim1 soft=%d xp=%d already=%v err=%v", soft, xp, already, err)
	}
	_, _, already, err = pg.ClaimReward(tok, "PG-TEST-BUNDLE", 40, 4)
	if err != nil || !already {
		t.Fatalf("claim2 already=%v err=%v", already, err)
	}
	if _, err := pg.StartBattle(tok, "B01", []string{"H01", "H02", "H03", "H04", "H07"}); err != nil {
		t.Fatal(err)
	}
	if _, err := pg.FinishBattle(tok, "B01", true); err != nil {
		t.Fatal(err)
	}
}
