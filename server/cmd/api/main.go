package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/content"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/httpapi"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func main() {
	addr := flag.String("addr", ":8080", "listen address")
	contentRoot := flag.String("content", "", "path to client/data (heroes/battles/dialogues)")
	persist := flag.String("persist", "", "optional JSON persist path for memory store")
	databaseURL := flag.String("database-url", env("DATABASE_URL", ""), "Postgres DSN; empty = memory store")
	redisAddr := flag.String("redis", env("REDIS_ADDR", ""), "Redis host:port for sessions (optional with Postgres)")
	migrate := flag.String("migrate", "", "path to SQL migration file (Postgres only)")
	flag.Parse()

	root := *contentRoot
	if root == "" {
		wd, _ := os.Getwd()
		root = filepath.Clean(filepath.Join(wd, "..", "client", "data"))
		if _, err := os.Stat(root); err != nil {
			root = filepath.Clean(filepath.Join(wd, "..", "..", "client", "data"))
		}
	}

	cl := content.New(root)
	var st store.Store
	var chat store.ChatService = store.NewChatHub()
	backend := "memory"
	if *databaseURL != "" {
		ctx := context.Background()
		pg, err := store.OpenPostgres(ctx, *databaseURL, *redisAddr)
		if err != nil {
			log.Fatalf("postgres: %v", err)
		}
		mig := *migrate
		if mig == "" {
			wd, _ := os.Getwd()
			cand := filepath.Join(wd, "migrations")
			if _, err := os.Stat(cand); err != nil {
				cand = filepath.Join(wd, "..", "migrations")
			}
			mig = cand
		}
		if err := pg.Migrate(mig); err != nil {
			log.Fatalf("migrate: %v", err)
		}
		st = pg
		chat = store.NewPostgresChat(ctx, pg.Pool(), pg.Redis())
		backend = "postgres"
		if *redisAddr != "" {
			backend = "postgres+redis"
		}
	} else {
		st = store.NewMemory(*persist)
	}

	api := httpapi.New(st, cl).WithBackend(backend).WithChat(chat)
	log.Printf("bashlegends-api listening on %s content=%s backend=%s", *addr, root, backend)
	if err := http.ListenAndServe(*addr, api.Handler()); err != nil {
		log.Fatal(err)
	}
}

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
