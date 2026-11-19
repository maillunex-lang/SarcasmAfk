package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/content"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/httpapi"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func TestAdminChatModerationAndGuildDonate(t *testing.T) {
	os.Setenv("ADMIN_API_KEY", "test-admin-key")
	defer os.Unsetenv("ADMIN_API_KEY")

	st := store.NewMemory("")
	c := content.New(onlineContentRoot(t))
	s := httpapi.New(st, c)
	h := s.Handler()

	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodPost, "/v1/auth/anonymous", nil))
	var auth map[string]any
	_ = json.Unmarshal(rr.Body.Bytes(), &auth)
	tok, _ := auth["token"].(string)

	req := httptest.NewRequest(http.MethodPost, "/v1/chat/global/send", bytes.NewReader([]byte(`{"text":"report me","display_name":"T"}`)))
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("send %d %s", rr.Code, rr.Body.String())
	}
	var sent map[string]any
	_ = json.Unmarshal(rr.Body.Bytes(), &sent)
	msg := sent["message"].(map[string]any)
	mid := int64(msg["id"].(float64))

	req = httptest.NewRequest(http.MethodPost, "/v1/chat/report", bytes.NewReader([]byte(`{"message_id":`+jsonNumber(mid)+`,"reason":"spam"}`)))
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)

	req = httptest.NewRequest(http.MethodGet, "/v1/admin/chat/reports", nil)
	req.Header.Set("X-Admin-Key", "test-admin-key")
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("reports %d %s", rr.Code, rr.Body.String())
	}

	req = httptest.NewRequest(http.MethodPost, "/v1/guild", bytes.NewReader([]byte(`{"action":"create","name":"Мод","tag":"MOD","description":""}`)))
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("guild %d %s", rr.Code, rr.Body.String())
	}

	req = httptest.NewRequest(http.MethodPost, "/v1/guild", bytes.NewReader([]byte(`{"action":"donate","amount":100}`)))
	req.Header.Set("Authorization", "Bearer "+tok)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("donate %d %s", rr.Code, rr.Body.String())
	}

	req = httptest.NewRequest(http.MethodGet, "/v1/admin/guilds", nil)
	req.Header.Set("X-Admin-Key", "test-admin-key")
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("admin guilds %d", rr.Code)
	}
}

func jsonNumber(n int64) string {
	b, _ := json.Marshal(n)
	return string(b)
}
