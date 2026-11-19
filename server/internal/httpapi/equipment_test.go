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

func equipmentContentRoot(t *testing.T) string {
	t.Helper()
	_, file, _, _ := runtime.Caller(0)
	return filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "..", "client", "data"))
}

func TestEquipmentCatalogAndEquipFlow(t *testing.T) {
	st := store.NewMemory("")
	c := content.New(equipmentContentRoot(t))
	if len(c.EquipmentTemplates()) != 32 {
		t.Fatalf("templates=%d", len(c.EquipmentTemplates()))
	}
	s := httpapi.New(st, c)
	h := s.Handler()

	rr := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/anonymous", nil)
	h.ServeHTTP(rr, req)
	var auth map[string]any
	_ = json.NewDecoder(rr.Body).Decode(&auth)
	tok, _ := auth["token"].(string)
	if tok == "" {
		t.Fatal("no token")
	}

	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/v1/equipment/catalog", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("catalog %d %s", rr.Code, rr.Body.String())
	}

	prog, inst, err := st.GrantEquipmentReward(tok, "CH01-B02-EQ-FIRST_CLEAR", "eq_n_starter_blade", "battle:B02", c.EquipmentTemplates(), c.EquipmentBalance())
	if err != nil || inst == nil {
		t.Fatalf("grant %v", err)
	}
	_ = prog

	body, _ := json.Marshal(map[string]any{
		"hero_id": "H01", "slot": "weapon", "request_id": "t1", "expected_version": inst.Version, "confirm_transfer": false,
	})
	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/v1/equipment/"+inst.ID+"/equip", bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("equip %d %s", rr.Code, rr.Body.String())
	}

	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/v1/heroes/H01/equipment", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("hero eq %d %s", rr.Code, rr.Body.String())
	}
	var heroEq map[string]any
	_ = json.NewDecoder(rr.Body).Decode(&heroEq)
	combat, _ := heroEq["combat"].(map[string]any)
	if combat == nil || combat["atk"].(float64) <= 100 {
		t.Fatalf("combat=%v", combat)
	}
}
