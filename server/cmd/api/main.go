package main

import (
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
	persist := flag.String("persist", "", "optional JSON persist path for accounts")
	flag.Parse()

	root := *contentRoot
	if root == "" {
		// default: ../client/data relative to server/
		wd, _ := os.Getwd()
		root = filepath.Clean(filepath.Join(wd, "..", "client", "data"))
		if _, err := os.Stat(root); err != nil {
			root = filepath.Clean(filepath.Join(wd, "..", "..", "client", "data"))
		}
	}

	st := store.NewMemory(*persist)
	cl := content.New(root)
	api := httpapi.New(st, cl)

	log.Printf("bashlegends-api listening on %s content=%s", *addr, root)
	if err := http.ListenAndServe(*addr, api.Handler()); err != nil {
		log.Fatal(err)
	}
}
