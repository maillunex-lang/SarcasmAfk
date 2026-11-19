package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/content"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/httpapi"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func TestCH01ExpansionAPI_SQ01Flow(t *testing.T) {
	st := store.NewMemory("")
	c := content.New(onlineContentRoot(t))
	if len(c.Sidequests()) != 5 {
		t.Fatalf("sidequests=%d", len(c.Sidequests()))
	}
	if len(c.POI()) != 10 {
		t.Fatalf("poi=%d", len(c.POI()))
	}
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
	// unlock prerequisite
	acc, _ := st.AccountByToken(tok)
	acc.QuestFlags["CH01-Q01"] = true

	authHdr := func(req *http.Request) {
		req.Header.Set("Authorization", "Bearer "+tok)
	}

	rr = httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/v1/campaign/ch01/sidequests/CH01-SQ01/start", nil)
	authHdr(req)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("start %d %s", rr.Code, rr.Body.String())
	}

	for _, step := range []string{"sq01_doc_1", "sq01_doc_2", "sq01_doc_3"} {
		rr = httptest.NewRecorder()
		body := bytes.NewReader([]byte(`{"action_id":"` + step + `"}`))
		req = httptest.NewRequest(http.MethodPost, "/v1/campaign/ch01/poi/POI-02/interact", body)
		authHdr(req)
		h.ServeHTTP(rr, req)
		if rr.Code != 200 {
			t.Fatalf("poi %s %d %s", step, rr.Code, rr.Body.String())
		}
	}

	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/v1/campaign/ch01/sidequests/CH01-SQ01/claim", nil)
	authHdr(req)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("claim %d %s", rr.Code, rr.Body.String())
	}
	var claim map[string]any
	_ = json.Unmarshal(rr.Body.Bytes(), &claim)
	if claim["already"] == true {
		t.Fatal("first claim already?")
	}

	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/v1/campaign/ch01/sidequests/CH01-SQ01/claim", nil)
	authHdr(req)
	h.ServeHTTP(rr, req)
	_ = json.Unmarshal(rr.Body.Bytes(), &claim)
	if claim["already"] != true {
		t.Fatalf("second claim should be already: %v", claim)
	}

	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/v1/campaign/ch01/journal", nil)
	authHdr(req)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("journal %d", rr.Code)
	}

	// skill-up endpoint
	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/v1/heroes/H01/skill-up", bytes.NewReader([]byte(`{"skill_id":"ultimate"}`)))
	authHdr(req)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("skill-up %d %s", rr.Code, rr.Body.String())
	}
}
