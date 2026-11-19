package httpapi

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func (s *Server) heroBase(id string) store.HeroBaseStats {
	m := s.Content.HeroMap()
	raw, ok := m[id]
	if !ok {
		return store.HeroBaseStats{HP: 1000, Atk: 100, Defense: 80, Speed: 100}
	}
	h, _ := raw.(map[string]any)
	num := func(keys ...string) int {
		for _, k := range keys {
			switch v := h[k].(type) {
			case float64:
				return int(v)
			case int:
				return v
			}
		}
		return 0
	}
	return store.HeroBaseStats{
		HP: num("hp"), Atk: num("atk"), Defense: num("defense", "def"), Speed: num("speed"),
	}
}

func (s *Server) heroesOwned(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	store.EnsureHeroInstances(acc)
	list := make([]*store.HeroInstance, 0, len(acc.HeroInstances))
	for _, inst := range acc.HeroInstances {
		base := s.heroBase(inst.CatalogID)
		inst.Power = store.ComputePower(base.HP, base.Atk, base.Defense, base.Speed, inst.Level, inst.Stars, inst.AwakenRank)
		list = append(list, inst)
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "heroes": list, "soft_currency": acc.SoftCurrency})
}

func (s *Server) heroesMutate(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/heroes/")
	parts := strings.Split(path, "/")
	if len(parts) < 2 {
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
		return
	}
	heroID, action := parts[0], parts[1]
	tok := bearer(r)
	base := s.heroBase(heroID)

	switch {
	case action == "level-up" && r.Method == http.MethodPost:
		var body struct {
			Levels int `json:"levels"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		if body.Levels <= 0 {
			body.Levels = 1
		}
		prog, inst, err := s.Store.LevelUpHero(tok, heroID, body.Levels, base)
		s.writeHeroMutate(w, prog, inst, err)
	case action == "star-up" && r.Method == http.MethodPost:
		prog, inst, err := s.Store.StarUpHero(tok, heroID, base)
		s.writeHeroMutate(w, prog, inst, err)
	case action == "equip" && r.Method == http.MethodPost:
		var body struct {
			Slot   string `json:"slot"`
			ItemID string `json:"item_id"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
			return
		}
		prog, inst, err := s.Store.EquipHero(tok, heroID, body.Slot, body.ItemID, base)
		s.writeHeroMutate(w, prog, inst, err)
	default:
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
	}
}

func (s *Server) writeHeroMutate(w http.ResponseWriter, prog *store.AccountProgress, inst *store.HeroInstance, err error) {
	switch err {
	case nil:
		writeJSON(w, http.StatusOK, map[string]any{
			"ok": true, "hero": inst, "soft_currency": prog.SoftCurrency, "progress": prog,
		})
	case store.ErrUnauthorized:
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
	case store.ErrNotOwned:
		writeErr(w, http.StatusNotFound, "HERO_NOT_OWNED")
	case store.ErrInsufficient:
		writeErr(w, http.StatusConflict, "INSUFFICIENT_RESOURCES")
	case store.ErrLevelCap:
		writeErr(w, http.StatusConflict, "LEVEL_CAP")
	case store.ErrStarCap:
		writeErr(w, http.StatusConflict, "STAR_CAP")
	default:
		writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
	}
}

func (s *Server) chatHandler(w http.ResponseWriter, r *http.Request) {
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	path := strings.TrimPrefix(r.URL.Path, "/v1/chat/")
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) == 0 || parts[0] == "" {
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
		return
	}

	switch {
	case parts[0] == "report" && r.Method == http.MethodPost:
		var body struct {
			MessageID int64  `json:"message_id"`
			Reason    string `json:"reason"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		s.Chat.Report(acc.AccountID, body.MessageID, body.Reason)
		writeJSON(w, http.StatusOK, map[string]any{"ok": true})
	case parts[0] == "block" && r.Method == http.MethodPost:
		var body struct {
			TargetID string `json:"target_id"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		if body.TargetID == "" {
			writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
			return
		}
		s.Chat.Block(acc.AccountID, body.TargetID)
		writeJSON(w, http.StatusOK, map[string]any{"ok": true})
	case len(parts) >= 2 && parts[1] == "history" && r.Method == http.MethodGet:
		channel := parts[0]
		before, _ := strconv.ParseInt(r.URL.Query().Get("before"), 10, 64)
		limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
		msgs := s.Chat.History(channel, before, limit)
		filtered := make([]store.ChatMessage, 0, len(msgs))
		for _, m := range msgs {
			if s.Chat.IsBlocked(acc.AccountID, m.AccountID) {
				continue
			}
			filtered = append(filtered, m)
		}
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "messages": filtered})
	case len(parts) >= 2 && parts[1] == "send" && r.Method == http.MethodPost:
		channel := parts[0]
		var body struct {
			Text string `json:"text"`
			Name string `json:"display_name"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		name := body.Name
		if name == "" {
			name = acc.AccountID
		}
		// Never trust client sender id — always use session account.
		msg, err := s.Chat.Post(channel, acc.AccountID, name, body.Text, acc.CommanderXP/100+1)
		if err != nil {
			writeErr(w, http.StatusTooManyRequests, "RATE_LIMITED")
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "message": msg})
	default:
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
	}
}

func (s *Server) guildLive(w http.ResponseWriter, r *http.Request) {
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	switch r.Method {
	case http.MethodGet:
		if g, role, ok := s.Guilds.ForAccount(acc.AccountID); ok {
			pub := g.Public()
			writeJSON(w, http.StatusOK, map[string]any{"ok": true, "guild": pub, "role": role, "list": s.Guilds.List()})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "guild": nil, "list": s.Guilds.List()})
	case http.MethodPost:
		var body struct {
			Action string `json:"action"`
			Name   string `json:"name"`
			Tag    string `json:"tag"`
			Desc   string `json:"description"`
			ID     string `json:"guild_id"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
			return
		}
		switch body.Action {
		case "create":
			if _, err := s.Store.SpendSoft(bearer(r), store.GuildCreateSoftCostDraft); err == store.ErrInsufficient {
				writeErr(w, http.StatusConflict, "INSUFFICIENT_RESOURCES")
				return
			} else if err != nil {
				writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
				return
			}
			g, err := s.Guilds.Create(acc.AccountID, body.Name, body.Tag, body.Desc)
			if err != nil {
				_, _, _ = s.Store.ApplySimulatedPurchase(bearer(r), "guild_create_refund:"+body.Tag, store.GuildCreateSoftCostDraft, 0, 0, nil)
				writeErr(w, http.StatusConflict, "VALIDATION_FAILED")
				return
			}
			writeJSON(w, http.StatusOK, map[string]any{
				"ok": true, "guild": g.Public(), "create_cost_draft": store.GuildCreateSoftCostDraft,
			})
		case "join":
			g, err := s.Guilds.Join(acc.AccountID, body.ID)
			if err == store.ErrNotFound {
				writeErr(w, http.StatusNotFound, "NOT_FOUND")
				return
			}
			if err != nil {
				writeErr(w, http.StatusConflict, "VALIDATION_FAILED")
				return
			}
			writeJSON(w, http.StatusOK, map[string]any{"ok": true, "guild": g.Public()})
		case "leave":
			if err := s.Guilds.Leave(acc.AccountID); err != nil {
				writeErr(w, http.StatusConflict, "VALIDATION_FAILED")
				return
			}
			writeJSON(w, http.StatusOK, map[string]any{"ok": true})
		default:
			writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		}
	default:
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
	}
}

func (s *Server) shopCatalog(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true,
		"purchase_mode_default": "simulated",
		"skus": []map[string]any{
			{"sku": "soft_pack_s", "title": "Мешок золота (S)", "category": "resource_packs", "purchase_mode": "simulated", "grants": map[string]int{"soft": 1000}, "lunex_visual_id": "lunex://shop/soft_pack_s"},
			{"sku": "ticket_pack_s", "title": "Билеты призыва ×5", "category": "growth_packs", "purchase_mode": "simulated", "grants": map[string]int{"tickets": 5}, "lunex_visual_id": "lunex://shop/ticket_pack_s"},
			{"sku": "exp_mat_pack", "title": "Набор опыта героя", "category": "growth_packs", "purchase_mode": "simulated", "grants": map[string]any{"inventory": map[string]int{"mat_hero_exp": 100}}, "lunex_visual_id": "lunex://shop/exp_mat_pack"},
		},
		"note": "Real payments disabled; simulated grants only",
	})
}

func (s *Server) shopPurchase(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	if _, err := s.Store.AccountByToken(bearer(r)); err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	var body struct {
		SKU string `json:"sku"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.SKU == "" {
		writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		return
	}
	soft, hard, tickets := 0, 0, 0
	inv := map[string]int{}
	switch body.SKU {
	case "soft_pack_s":
		soft = 1000
	case "ticket_pack_s":
		tickets = 5
	case "exp_mat_pack":
		inv["mat_hero_exp"] = 100
	default:
		writeErr(w, http.StatusNotFound, "SKU_NOT_FOUND")
		return
	}
	prog, already, err := s.Store.ApplySimulatedPurchase(bearer(r), body.SKU, soft, hard, tickets, inv)
	if err == store.ErrUnauthorized {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	if err != nil {
		writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true, "already": already, "purchase_mode": "simulated", "sku": body.SKU,
		"granted_soft": soft, "granted_tickets": tickets, "progress": prog,
		"note": "TEST/SIMULATED purchase — not a real payment",
	})
}

func (s *Server) vipStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true,
		"vip_points": acc.VipPoints,
		"vip_level": acc.VipLevel,
		"status": "draft",
		"lunex_visual_id": "lunex://vip/" + strconv.Itoa(acc.VipLevel),
		"note": "VIP levels Draft — pending owner approval",
	})
}
