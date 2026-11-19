package httpapi

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/battleverify"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/content"
	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

type Server struct {
	Store   store.Store
	Content *content.Loader
	Backend string
	Metrics *Metrics
}

func New(st store.Store, c *content.Loader) *Server {
	return &Server{Store: st, Content: c, Backend: "memory", Metrics: NewMetrics()}
}

func (s *Server) WithBackend(name string) *Server {
	s.Backend = name
	return s
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", s.health)
	mux.HandleFunc("/readyz", s.readyz)
	mux.HandleFunc("/v1/admin/metrics", s.adminMetrics)
	mux.HandleFunc("/v1/auth/anonymous", s.authAnonymous)
	mux.HandleFunc("/v1/me/progress", s.meProgress)
	mux.HandleFunc("/v1/me/party", s.meParty)
	mux.HandleFunc("/v1/content/heroes", s.contentHeroes)
	mux.HandleFunc("/v1/content/battles/", s.contentBattle)
	mux.HandleFunc("/v1/content/dialogues/", s.contentDialogue)
	mux.HandleFunc("/v1/battles/", s.battles)
	mux.HandleFunc("/v1/rewards/claim", s.rewardsClaim)
	mux.HandleFunc("/v1/afk/claim", s.afkClaim)
	mux.HandleFunc("/v1/gacha/summon", s.gachaSummon)
	mux.HandleFunc("/v1/guild", s.guild)
	mux.HandleFunc("/v1/arena", s.arena)
	mux.HandleFunc("/v1/events", s.events)
	return withLogging(s.Metrics, withCORS(mux))
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Mock")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}

func writeErr(w http.ResponseWriter, code int, errCode string) {
	writeJSON(w, code, map[string]any{"ok": false, "error": errCode})
}

func bearer(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if strings.HasPrefix(h, "Bearer ") {
		return strings.TrimPrefix(h, "Bearer ")
	}
	return ""
}

func (s *Server) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true, "service": "bashlegends-api", "phase": 2, "backend": s.Backend,
	})
}

func (s *Server) readyz(w http.ResponseWriter, _ *http.Request) {
	// Store is always constructed before listen; soft readiness for ops probes.
	if s.Store == nil || s.Content == nil {
		writeErr(w, http.StatusServiceUnavailable, "NOT_READY")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "ready": true, "backend": s.Backend})
}

func (s *Server) adminMetrics(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	snap := map[string]any{"ok": true, "backend": s.Backend, "heroes": len(s.Content.HeroIDs())}
	if s.Metrics != nil {
		for k, v := range s.Metrics.Snapshot() {
			snap[k] = v
		}
	}
	writeJSON(w, http.StatusOK, snap)
}

func (s *Server) authAnonymous(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	tok, prog := s.Store.CreateAnonymous()
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true, "token": tok, "progress": prog, "mock": false,
	})
}

func (s *Server) meProgress(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	prog, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "progress": prog})
}

func (s *Server) meParty(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	var body struct {
		PartyIDs []string `json:"party_ids"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		return
	}
	prog, err := s.Store.SetParty(bearer(r), body.PartyIDs)
	if err == store.ErrUnauthorized {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	if err == store.ErrInvalidParty {
		writeErr(w, http.StatusBadRequest, "INVALID_PARTY")
		return
	}
	if err != nil {
		writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "progress": prog})
}

func (s *Server) contentHeroes(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "heroes": s.Content.Heroes()})
}

func (s *Server) contentBattle(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/v1/content/battles/")
	b, ok := s.Content.Battle(id)
	if !ok {
		writeErr(w, http.StatusNotFound, "BATTLE_NOT_FOUND")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "battle": b})
}

func (s *Server) contentDialogue(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/v1/content/dialogues/")
	d, ok := s.Content.Dialogue(id)
	if !ok {
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "dialogue": d})
}

func (s *Server) battles(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/battles/")
	parts := strings.Split(path, "/")
	if len(parts) < 2 {
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
		return
	}
	battleID, action := parts[0], parts[1]
	switch action {
	case "start":
		if r.Method != http.MethodPost {
			writeErr(w, http.StatusMethodNotAllowed, "METHOD")
			return
		}
		if _, ok := s.Content.Battle(battleID); !ok {
			writeErr(w, http.StatusNotFound, "BATTLE_NOT_FOUND")
			return
		}
		var body struct {
			PartyIDs      []string `json:"party_ids"`
			ClientVersion string   `json:"client_version"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		seed, err := s.Store.StartBattle(bearer(r), battleID, body.PartyIDs)
		if err == store.ErrUnauthorized {
			writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
			return
		}
		if err == store.ErrInvalidParty {
			writeErr(w, http.StatusBadRequest, "INVALID_PARTY")
			return
		}
		if err != nil {
			writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"ok": true, "battle_id": battleID, "client_seed": seed,
			"party_ids": body.PartyIDs, "client_version": body.ClientVersion,
			"note": "server seed issued; full replay verify TBD",
		})
	case "finish":
		if r.Method != http.MethodPost {
			writeErr(w, http.StatusMethodNotAllowed, "METHOD")
			return
		}
		var body struct {
			Victory     bool   `json:"victory"`
			DurationMS  int    `json:"duration_ms"`
			ActionsHash string `json:"actions_hash"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		tok := bearer(r)
		acc, err := s.Store.AccountByToken(tok)
		if err == store.ErrUnauthorized {
			writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
			return
		}
		if err != nil || acc == nil {
			writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
			return
		}
		if acc.ActiveBattleID == "" || acc.ActiveBattleID != battleID {
			writeErr(w, http.StatusConflict, "NO_ACTIVE_BATTLE")
			return
		}
		battle, ok := s.Content.Battle(battleID)
		enemyPower := 0
		if ok {
			if enemies, ok2 := battle["enemies"].([]any); ok2 {
				units := make([]map[string]any, 0, len(enemies))
				for _, e := range enemies {
					if m, ok3 := e.(map[string]any); ok3 {
						units = append(units, m)
					}
				}
				enemyPower = battleverify.PowerFromUnits(units)
			}
		}
		partyPower := battleverify.PowerFromHeroIDs(acc.PartyIDs, s.Content.HeroMap())
		serverVictory, errCode := battleverify.CheckFinish(acc.BattleSeed, body.DurationMS, partyPower, enemyPower, body.Victory)
		if errCode != "" {
			writeErr(w, http.StatusConflict, errCode)
			return
		}
		prog, err := s.Store.FinishBattle(tok, battleID, serverVictory)
		if err == store.ErrUnauthorized {
			writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
			return
		}
		if err == store.ErrNoActiveBattle {
			writeErr(w, http.StatusConflict, "NO_ACTIVE_BATTLE")
			return
		}
		if err != nil {
			writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"ok": true, "battle_id": battleID, "victory": serverVictory,
			"client_victory": body.Victory, "duration_ms": body.DurationMS,
			"party_power": partyPower, "enemy_power": enemyPower,
			"rewards_claimed": false, "progress": prog,
			"note": "soft server verify (power+seed); full tick sim later",
		})
	default:
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
	}
}

func (s *Server) rewardsClaim(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	var body struct {
		BundleID string `json:"bundle_id"`
		BattleID string `json:"battle_id"`
		Soft     int    `json:"soft"`
		XP       int    `json:"commander_xp"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		return
	}
	soft, xp, already, err := s.Store.ClaimReward(bearer(r), body.BundleID, body.Soft, body.XP)
	if err == store.ErrUnauthorized {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	if err != nil {
		writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
		return
	}
	code := http.StatusOK
	if already {
		code = http.StatusOK // idempotent success; PHASE0 also allows 409 — we return already_claimed
	}
	writeJSON(w, code, map[string]any{
		"ok": true, "soft_delta": soft, "xp_delta": xp,
		"already_claimed": already, "bundle_id": body.BundleID,
	})
}

func (s *Server) afkClaim(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	hours, soft, xp, err := s.Store.ClaimAFK(bearer(r), 120, 15)
	if err == store.ErrUnauthorized {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	if err != nil {
		writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true, "hours": hours, "soft": soft, "xp": xp, "max_hours": store.AFKMaxHours,
	})
}

func (s *Server) gachaSummon(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	heroID, newly, err := s.Store.Summon(bearer(r), s.Content.HeroIDs())
	if err == store.ErrUnauthorized {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	if err == store.ErrNoTickets {
		writeErr(w, http.StatusConflict, "NO_TICKETS")
		return
	}
	if err != nil {
		writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true, "hero_id": heroID, "newly_owned": newly,
	})
}

func (s *Server) guild(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	if _, err := s.Store.AccountByToken(bearer(r)); err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true,
		"guild": store.GuildStub{ID: "g_queue13", Name: "Очередь №13", Role: "Рекрут", Members: 1, Cap: 30},
	})
}

func (s *Server) arena(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	if _, err := s.Store.AccountByToken(bearer(r)); err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true,
		"arena": store.ArenaStub{Rank: "Бронзовый талон", Points: 1000, Rival: "Инспектор Нейросеть"},
	})
}

func (s *Server) events(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true,
		"events": []store.EventStub{
			{ID: "EV01", Title: "День живого талона", City: "Уфа", Status: "active", Tone: "humor"},
			{ID: "EV02", Title: "Сезон слякоти и баффов", City: "Республика", Status: "upcoming", Tone: "season"},
			{ID: "EV03", Title: "Региональный босс: Инспектор Тьмы", City: "Стерлитамак", Status: "locked", Tone: "boss"},
		},
	})
}
