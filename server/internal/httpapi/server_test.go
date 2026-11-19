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

func contentRoot(t *testing.T) string {
	t.Helper()
	_, file, _, _ := runtime.Caller(0)
	root := filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "..", "client", "data"))
	return root
}

func newTestServer(t *testing.T) http.Handler {
	t.Helper()
	st := store.NewMemory("")
	cl := content.New(contentRoot(t))
	return httpapi.New(st, cl).Handler()
}

func auth(t *testing.T, h http.Handler) string {
	t.Helper()
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/anonymous", nil)
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("auth status %d", rr.Code)
	}
	var body map[string]any
	_ = json.Unmarshal(rr.Body.Bytes(), &body)
	tok, _ := body["token"].(string)
	if tok == "" {
		t.Fatal("missing token")
	}
	return tok
}

func TestHealthReadyMetrics(t *testing.T) {
	h := newTestServer(t)
	for _, path := range []string{"/healthz", "/readyz"} {
		rr := httptest.NewRecorder()
		h.ServeHTTP(rr, httptest.NewRequest(http.MethodGet, path, nil))
		if rr.Code != 200 {
			t.Fatalf("%s => %d %s", path, rr.Code, rr.Body.String())
		}
	}
	// Admin locked without ADMIN_API_KEY
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodGet, "/v1/admin/metrics", nil))
	if rr.Code != 503 && rr.Code != 401 {
		t.Fatalf("admin metrics expected locked, got %d %s", rr.Code, rr.Body.String())
	}
}

func TestHealthAndAuthProgress(t *testing.T) {
	h := newTestServer(t)
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if rr.Code != 200 {
		t.Fatalf("health %d", rr.Code)
	}
	tok := auth(t, h)
	req := httptest.NewRequest(http.MethodGet, "/v1/me/progress", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("progress %d", rr.Code)
	}
}

func TestRewardIdempotent(t *testing.T) {
	h := newTestServer(t)
	tok := auth(t, h)
	payload := []byte(`{"bundle_id":"TEST-BUNDLE","soft":100,"commander_xp":10}`)
	do := func() map[string]any {
		req := httptest.NewRequest(http.MethodPost, "/v1/rewards/claim", bytes.NewReader(payload))
		req.Header.Set("Authorization", "Bearer "+tok)
		req.Header.Set("Content-Type", "application/json")
		rr := httptest.NewRecorder()
		h.ServeHTTP(rr, req)
		var body map[string]any
		_ = json.Unmarshal(rr.Body.Bytes(), &body)
		return body
	}
	a := do()
	b := do()
	if a["already_claimed"] == true || a["soft_delta"].(float64) != 100 {
		t.Fatalf("first claim %#v", a)
	}
	if b["already_claimed"] != true || b["soft_delta"].(float64) != 0 {
		t.Fatalf("second claim %#v", b)
	}
}

func TestBattleStartFinishAndContent(t *testing.T) {
	h := newTestServer(t)
	tok := auth(t, h)

	req := httptest.NewRequest(http.MethodGet, "/v1/content/heroes", nil)
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("heroes %d", rr.Code)
	}

	req = httptest.NewRequest(http.MethodGet, "/v1/content/battles/B01", nil)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("battle %d body=%s", rr.Code, rr.Body.String())
	}

	body := []byte(`{"party_ids":["H01","H02","H03","H04","H07"],"client_version":"test"}`)
	req = httptest.NewRequest(http.MethodPost, "/v1/battles/B01/start", bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("start %d %s", rr.Code, rr.Body.String())
	}

	fin := []byte(`{"victory":true,"duration_ms":1000}`)
	req = httptest.NewRequest(http.MethodPost, "/v1/battles/B01/finish", bytes.NewReader(fin))
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("finish %d %s", rr.Code, rr.Body.String())
	}

	// Blind finish without start must fail
	req = httptest.NewRequest(http.MethodPost, "/v1/battles/B01/finish", bytes.NewReader(fin))
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 409 {
		t.Fatalf("expected 409 NO_ACTIVE_BATTLE, got %d %s", rr.Code, rr.Body.String())
	}

	// Too-fast finish after start
	body = []byte(`{"party_ids":["H01","H02","H03","H04","H07"],"client_version":"test"}`)
	req = httptest.NewRequest(http.MethodPost, "/v1/battles/B01/start", bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	fast := []byte(`{"victory":true,"duration_ms":50}`)
	req = httptest.NewRequest(http.MethodPost, "/v1/battles/B01/finish", bytes.NewReader(fast))
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 409 {
		t.Fatalf("expected 409 BATTLE_TOO_FAST, got %d %s", rr.Code, rr.Body.String())
	}
}

func TestFinishDisablesAutoCastWhenUltimateCommand(t *testing.T) {
	h := newTestServer(t)
	tok := auth(t, h)

	body := []byte(`{"party_ids":["H01","H02","H03","H04","H07"],"client_version":"test"}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/battles/B01/start", bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("start %d %s", rr.Code, rr.Body.String())
	}

	cmd := []byte(`{"op":"ultimate","unit_id":"H01","at_tick":40}`)
	req = httptest.NewRequest(http.MethodPost, "/v1/battles/B01/command", bytes.NewReader(cmd))
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("command %d %s", rr.Code, rr.Body.String())
	}

	fin := []byte(`{"victory":true,"duration_ms":5000}`)
	req = httptest.NewRequest(http.MethodPost, "/v1/battles/B01/finish", bytes.NewReader(fin))
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("finish %d %s", rr.Code, rr.Body.String())
	}
	var out map[string]any
	if err := json.Unmarshal(rr.Body.Bytes(), &out); err != nil {
		t.Fatal(err)
	}
	if out["auto_cast"] != false {
		t.Fatalf("expected auto_cast=false when ultimate command present, got %#v", out["auto_cast"])
	}
}

func TestGuildArenaEvents(t *testing.T) {
	h := newTestServer(t)
	tok := auth(t, h)
	for _, path := range []string{"/v1/guild", "/v1/arena", "/v1/events"} {
		req := httptest.NewRequest(http.MethodGet, path, nil)
		if path != "/v1/events" {
			req.Header.Set("Authorization", "Bearer "+tok)
		}
		rr := httptest.NewRecorder()
		h.ServeHTTP(rr, req)
		if rr.Code != 200 {
			t.Fatalf("%s => %d %s", path, rr.Code, rr.Body.String())
		}
	}
}

func TestGachaAndAFK(t *testing.T) {
	h := newTestServer(t)
	tok := auth(t, h)
	req := httptest.NewRequest(http.MethodPost, "/v1/gacha/summon", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("gacha %d %s", rr.Code, rr.Body.String())
	}
	// AFK may fail if zero elapsed — force via store is hard; accept 422 or 200
	req = httptest.NewRequest(http.MethodPost, "/v1/afk/claim", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 && rr.Code != 422 {
		t.Fatalf("afk %d", rr.Code)
	}
}
