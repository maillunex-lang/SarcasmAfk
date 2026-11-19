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
	Chat    store.ChatService
	Guilds  *store.GuildHub
	WS      *wsHub
	Backend string
	Metrics *Metrics
}

func New(st store.Store, c *content.Loader) *Server {
	return &Server{
		Store: st, Content: c, Backend: "memory", Metrics: NewMetrics(),
		Chat: store.NewChatHub(), Guilds: store.NewGuildHub(), WS: newWSHub(),
	}
}

func (s *Server) WithBackend(name string) *Server {
	s.Backend = name
	return s
}

func (s *Server) WithChat(chat store.ChatService) *Server {
	if chat != nil {
		s.Chat = chat
	}
	return s
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", s.health)
	mux.HandleFunc("/readyz", s.readyz)
	mux.HandleFunc("/v1/admin/metrics", s.adminMetrics)
	mux.HandleFunc("/v1/admin/audit", s.adminAudit)
	mux.HandleFunc("/v1/auth/anonymous", s.authAnonymous)
	mux.HandleFunc("/v1/me/progress", s.meProgress)
	mux.HandleFunc("/v1/me/party", s.meParty)
	mux.HandleFunc("/v1/content/heroes", s.contentHeroes)
	mux.HandleFunc("/v1/content/battles/", s.contentBattle)
	mux.HandleFunc("/v1/content/dialogues/", s.contentDialogue)
	mux.HandleFunc("/v1/battles/", s.battles)
	mux.HandleFunc("/v1/rewards/claim", s.rewardsClaim)
	mux.HandleFunc("/v1/afk/claim", s.afkClaim)
	mux.HandleFunc("/v1/gacha/summon", s.gachaSummonBanner) // body: banner_id, count
	mux.HandleFunc("/v1/gacha/banners", s.gachaBanners)
	mux.HandleFunc("/v1/gacha/history", s.gachaHistory)
	mux.HandleFunc("/v1/guild", s.guildLive)
	mux.HandleFunc("/v1/arena", s.arena)
	mux.HandleFunc("/v1/events", s.events)
	mux.HandleFunc("/v1/heroes/owned", s.heroesOwned)
	mux.HandleFunc("/v1/heroes/", s.heroesMutate)
	mux.HandleFunc("/v1/chat/", s.chatHandler)
	mux.HandleFunc("/v1/ws/chat", s.chatWS)
	mux.HandleFunc("/v1/shop/catalog", s.shopCatalogV2)
	mux.HandleFunc("/v1/shop/purchase", s.shopPurchaseV2)
	mux.HandleFunc("/v1/vip/status", s.vipStatusV2)
	mux.HandleFunc("/v1/vip/claim-daily", s.vipClaimDaily)
	mux.HandleFunc("/v1/admin/config", s.adminConfig)
	mux.HandleFunc("/v1/admin/chat/reports", s.adminChat)
	mux.HandleFunc("/v1/admin/chat/mute", s.adminChat)
	mux.HandleFunc("/v1/admin/chat/delete", s.adminChat)
	mux.HandleFunc("/v1/admin/guilds", s.adminGuilds)
	mux.HandleFunc("/v1/campaign/ch01/", s.ch01Campaign)
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
		party := body.PartyIDs
		if len(party) == 0 {
			if acc, e := s.Store.AccountByToken(bearer(r)); e == nil && acc != nil {
				party = acc.PartyIDs
			}
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"ok": true, "battle_id": battleID, "client_seed": seed,
			"party_ids": party, "client_version": body.ClientVersion,
			"balance_version": battleverify.BalanceVersion,
			"auto_cast":      true,
			"note":           "authoritative seed+balance; client victory ignored on finish",
		})
	case "command":
		if r.Method != http.MethodPost {
			writeErr(w, http.StatusMethodNotAllowed, "METHOD")
			return
		}
		var body struct {
			Op     string `json:"op"`
			UnitID string `json:"unit_id"`
			AtTick int    `json:"at_tick"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
			return
		}
		prog, err := s.Store.AppendBattleCommand(bearer(r), battleID, store.BattleCommand{
			Op: body.Op, UnitID: body.UnitID, AtTick: body.AtTick,
		})
		if err == store.ErrUnauthorized {
			writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
			return
		}
		if err == store.ErrNoActiveBattle {
			writeErr(w, http.StatusConflict, "NO_ACTIVE_BATTLE")
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
			"ok": true, "battle_id": battleID, "commands": prog.BattleCommands,
		})
	case "finish":
		if r.Method != http.MethodPost {
			writeErr(w, http.StatusMethodNotAllowed, "METHOD")
			return
		}
		var body struct {
			DurationMS      int    `json:"duration_ms"`
			BalanceVersion  string `json:"balance_version"`
			ClientVictory   *bool  `json:"victory"` // ignored for authority; accepted for telemetry only
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
		enemyUnits := []map[string]any{}
		if ok {
			if enemies, ok2 := battle["enemies"].([]any); ok2 {
				for _, e := range enemies {
					if m, ok3 := e.(map[string]any); ok3 {
						enemyUnits = append(enemyUnits, m)
					}
				}
			}
		}
		heroMap := s.Content.HeroMap()
		heroUnits := make([]map[string]any, 0, len(acc.PartyIDs))
		for _, id := range acc.PartyIDs {
			if h, ok := heroMap[id].(map[string]any); ok {
				heroUnits = append(heroUnits, h)
			}
		}
		cmds := make([]battleverify.Command, 0, len(acc.BattleCommands))
		autoCast := true // D-COMBAT-02 default
		for _, c := range acc.BattleCommands {
			cmds = append(cmds, battleverify.Command{Op: c.Op, UnitID: c.UnitID, AtTick: c.AtTick})
			// D-COMBAT-03: recorded manual ultimates disable server auto-cast so replay matches player taps.
			if c.Op == "ultimate" {
				autoCast = false
			}
		}
		replayIn := battleverify.ReplayInput{
			Seed: acc.BattleSeed, BalanceVersion: body.BalanceVersion,
			PartyIDs: append([]string{}, acc.PartyIDs...), Heroes: heroUnits, Enemies: enemyUnits,
			Commands: cmds, AutoCast: autoCast, DurationMS: body.DurationMS,
		}
		sim, errCode := battleverify.CheckFinishReplay(replayIn)
		if errCode != "" {
			writeErr(w, http.StatusConflict, errCode)
			return
		}
		// Authoritative: ignore client victory (D-COMBAT-05).
		prog, err := s.Store.FinishBattle(tok, battleID, sim.Victory)
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
		reward := map[string]any{}
		if sim.Victory && ok {
			if fr, ok2 := battle["first_clear_reward"].(map[string]any); ok2 {
				bundle, _ := fr["bundle_id"].(string)
				soft := battleverify.AsIntPublic(fr["soft"])
				xp := battleverify.AsIntPublic(fr["commander_xp"])
				if bundle != "" {
					sd, xd, already, cerr := s.Store.ClaimReward(tok, bundle, soft, xp)
					if cerr == nil {
						reward = map[string]any{
							"bundle_id": bundle, "soft_delta": sd, "xp_delta": xd, "already_claimed": already,
						}
						if p2, e2 := s.Store.AccountByToken(tok); e2 == nil {
							prog = p2
						}
					}
				}
			}
		}
		cv := any(nil)
		if body.ClientVictory != nil {
			cv = *body.ClientVictory
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"ok": true, "battle_id": battleID, "victory": sim.Victory,
			"client_victory_ignored": cv, "duration_ms": body.DurationMS,
			"balance_version": sim.BalanceVersion, "sim_ticks": sim.Ticks, "sim_note": sim.Note,
			"party_ids": sim.PartyIDs, "commands": sim.Commands, "auto_cast": sim.AutoCast,
			"reward": reward, "progress": prog,
			"note": "server replay is source of truth for victory and rewards",
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
