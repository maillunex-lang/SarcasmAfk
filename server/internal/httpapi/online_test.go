package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/content"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/httpapi"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func onlineContentRoot(t *testing.T) string {
	t.Helper()
	_, file, _, _ := runtime.Caller(0)
	return filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "..", "client", "data"))
}

func TestHeroesCatalogHas36(t *testing.T) {
	st := store.NewMemory("")
	c := content.New(onlineContentRoot(t))
	s := httpapi.New(st, c)
	h := s.Handler()
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodGet, "/v1/content/heroes", nil))
	if rr.Code != 200 {
		t.Fatalf("code %d", rr.Code)
	}
	var body map[string]any
	_ = json.Unmarshal(rr.Body.Bytes(), &body)
	heroes, _ := body["heroes"].([]any)
	if len(heroes) < 36 {
		t.Fatalf("heroes=%d want>=36", len(heroes))
	}
}

func TestLevelUpAndChatAndShop(t *testing.T) {
	st := store.NewMemory("")
	c := content.New(onlineContentRoot(t))
	s := httpapi.New(st, c)
	h := s.Handler()

	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodPost, "/v1/auth/anonymous", nil))
	var auth map[string]any
	_ = json.Unmarshal(rr.Body.Bytes(), &auth)
	tok, _ := auth["token"].(string)
	if tok == "" {
		t.Fatal("no token")
	}

	req := httptest.NewRequest(http.MethodPost, "/v1/heroes/H01/level-up", bytes.NewReader([]byte(`{"levels":1}`)))
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("level-up %d %s", rr.Code, rr.Body.String())
	}

	req = httptest.NewRequest(http.MethodPost, "/v1/chat/global/send", bytes.NewReader([]byte(`{"text":"привет мир","display_name":"T"}`)))
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("chat send %d %s", rr.Code, rr.Body.String())
	}

	req = httptest.NewRequest(http.MethodGet, "/v1/chat/global/history?limit=10", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("chat hist %d", rr.Code)
	}

	req = httptest.NewRequest(http.MethodPost, "/v1/shop/purchase", bytes.NewReader([]byte(`{"sku":"soft_pack_s"}`)))
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("shop %d %s", rr.Code, rr.Body.String())
	}
	var shop map[string]any
	_ = json.Unmarshal(rr.Body.Bytes(), &shop)
	if shop["purchase_mode"] != "simulated" {
		t.Fatalf("mode %v", shop["purchase_mode"])
	}

	req = httptest.NewRequest(http.MethodGet, "/v1/vip/status", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("vip %d", rr.Code)
	}

	req = httptest.NewRequest(http.MethodPost, "/v1/guild", bytes.NewReader([]byte(`{"action":"create","name":"Орден","tag":"ORD","description":"x"}`)))
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("guild create %d %s", rr.Code, rr.Body.String())
	}
}
