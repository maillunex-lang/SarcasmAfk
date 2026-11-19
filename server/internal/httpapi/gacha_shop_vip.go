package httpapi

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func (s *Server) poolByRarity() map[string][]string {
	out := map[string][]string{}
	for _, raw := range s.Content.Heroes() {
		h, _ := raw.(map[string]any)
		id, _ := h["id"].(string)
		rarity, _ := h["rarity"].(string)
		if id == "" || rarity == "" || rarity == "Mythic" {
			continue // Mythic event-only
		}
		out[rarity] = append(out[rarity], id)
	}
	return out
}

func (s *Server) gachaBanners(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true,
		"paid_banners_enabled": false,
		"banners": []map[string]any{
			{
				"id": store.BannerStandard, "name": "Обычный призыв", "type": "standard",
				"rates": store.StandardRates, "pity": nil,
				"display_note": "Показаны базовые вероятности баннера",
			},
			{
				"id": store.BannerAdvanced, "name": "Продвинутый призыв", "type": "advanced",
				"rates": store.AdvancedRates,
				"pity": map[string]any{
					"soft_sr_every": store.PitySoftSREvery,
					"hard_ssr_every": store.PityHardSSREvery,
					"note": "Гарантия заменяет результат призыва, не добавляет награду",
				},
			},
		},
		"mythic_policy": "event_only_after_approval",
	})
}

func (s *Server) gachaSummonBanner(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	var body struct {
		BannerID string `json:"banner_id"`
		Count    int    `json:"count"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)
	if body.Count == 0 {
		body.Count = 1
	}
	if body.BannerID == "" {
		body.BannerID = store.BannerStandard
	}
	prog, results, err := s.Store.SummonBanner(bearer(r), body.BannerID, body.Count, s.poolByRarity())
	switch err {
	case nil:
		writeJSON(w, http.StatusOK, map[string]any{
			"ok": true, "banner_id": body.BannerID, "results": results,
			"pity_counters": prog.PityCounters, "tickets": prog.SummonTickets,
			"history_tail": prog.GachaHistory,
		})
	case store.ErrUnauthorized:
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
	case store.ErrNoTickets:
		writeErr(w, http.StatusConflict, "NO_TICKETS")
	default:
		writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
	}
}

func (s *Server) gachaHistory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "history": acc.GachaHistory, "pity": acc.PityCounters})
}

func (s *Server) shopCatalogV2(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true,
		"purchase_mode_default": "TEST_PURCHASE",
		"test_mode": true,
		"paid_provider": nil,
		"test_limits": map[string]int{
			"max_test_purchases_per_day": store.TestMaxPurchasesPerDay,
			"max_test_hard_per_day":      store.TestMaxHardPerDay,
			"max_test_vip_points_per_day": store.TestMaxVipPerDay,
		},
		"skus": defaultShopSKUs(),
		"note": "Prices are placeholders. TEST_PURCHASE only — not real revenue.",
	})
}

type shopSKU struct {
	SKU          string         `json:"sku"`
	Category     string         `json:"category"`
	Title        string         `json:"title"`
	PriceDisplay string         `json:"price_display"`
	PriceLabel   string         `json:"price_label"`
	Soft         int            `json:"grant_soft"`
	Hard         int            `json:"grant_hard"`
	Tickets      int            `json:"grant_tickets"`
	VIPPoints    int            `json:"grant_vip_points"`
	Inventory    map[string]int `json:"grant_inventory,omitempty"`
}

func defaultShopSKUs() []map[string]any {
	return []map[string]any{
		{"sku": "diamonds_60", "category": "diamonds", "title": "Алмазы ×60", "price_display": "99 ₽", "price_label": "Тестовый режим", "grant_hard": 60, "grant_vip_points": 10, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "diamonds_300", "category": "diamonds", "title": "Алмазы ×300", "price_display": "449 ₽", "price_label": "Тестовый режим", "grant_hard": 300, "grant_vip_points": 50, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "resource_pack_s", "category": "resource_packs", "title": "Набор ресурсов S", "price_display": "149 ₽", "price_label": "Тестовый режим", "grant_soft": 5000, "grant_vip_points": 15, "grant_inventory": map[string]int{"mat_hero_exp": 100}, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "growth_pack_m", "category": "growth_packs", "title": "Набор развития M", "price_display": "299 ₽", "price_label": "Тестовый режим", "grant_tickets": 5, "grant_vip_points": 30, "grant_inventory": map[string]int{"mat_awaken": 3}, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "daily_deal", "category": "daily", "title": "Ежедневное предложение", "price_display": "49 ₽", "price_label": "Тестовый режим", "grant_soft": 1000, "grant_tickets": 1, "grant_vip_points": 5, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "weekly_deal", "category": "weekly", "title": "Еженедельное предложение", "price_display": "199 ₽", "price_label": "Тестовый режим", "grant_hard": 100, "grant_tickets": 3, "grant_vip_points": 25, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "monthly_deal", "category": "monthly", "title": "Месячное предложение", "price_display": "799 ₽", "price_label": "Тестовый режим", "grant_hard": 500, "grant_tickets": 10, "grant_vip_points": 80, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "cosmetic_frame_cyan", "category": "cosmetic", "title": "Рамка «Циан талона»", "price_display": "129 ₽", "price_label": "Тестовый режим", "grant_vip_points": 8, "grant_inventory": map[string]int{"frame_cyan": 1}, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "vip_starter", "category": "vip", "title": "VIP-старт", "price_display": "99 ₽", "price_label": "Тестовый режим", "grant_vip_points": 100, "grant_soft": 500, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "soft_pack_s", "category": "resource_packs", "title": "Мешок золота (S)", "price_display": "0 ₽", "price_label": "Тестовый режим", "grant_soft": 1000, "purchase_mode": "TEST_PURCHASE"},
		{"sku": "ticket_pack_s", "category": "growth_packs", "title": "Билеты ×5", "price_display": "0 ₽", "price_label": "Тестовый режим", "grant_tickets": 5, "purchase_mode": "TEST_PURCHASE"},
	}
}

func resolveSKU(sku string) (soft, hard, tickets, vip int, inv map[string]int, ok bool) {
	inv = map[string]int{}
	ok = true
	switch sku {
	case "diamonds_60":
		hard, vip = 60, 10
	case "diamonds_300":
		hard, vip = 300, 50
	case "resource_pack_s":
		soft, vip, inv = 5000, 15, map[string]int{"mat_hero_exp": 100}
	case "growth_pack_m":
		tickets, vip, inv = 5, 30, map[string]int{"mat_awaken": 3}
	case "daily_deal":
		soft, tickets, vip = 1000, 1, 5
	case "weekly_deal":
		hard, tickets, vip = 100, 3, 25
	case "monthly_deal":
		hard, tickets, vip = 500, 10, 80
	case "cosmetic_frame_cyan":
		vip, inv = 8, map[string]int{"frame_cyan": 1}
	case "vip_starter":
		vip, soft = 100, 500
	case "soft_pack_s":
		soft = 1000
	case "ticket_pack_s":
		tickets = 5
	case "exp_mat_pack":
		inv = map[string]int{"mat_hero_exp": 100}
	default:
		ok = false
	}
	return
}

func (s *Server) shopPurchaseV2(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	var body struct {
		SKU string `json:"sku"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.SKU == "" {
		writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		return
	}
	soft, hard, tickets, vip, inv, ok := resolveSKU(body.SKU)
	if !ok {
		writeErr(w, http.StatusNotFound, "SKU_NOT_FOUND")
		return
	}
	prog, meta, err := s.Store.TestPurchase(bearer(r), body.SKU, soft, hard, tickets, vip, inv)
	switch err {
	case nil:
		writeJSON(w, http.StatusOK, map[string]any{
			"ok": true, "transaction_type": "TEST_PURCHASE", "sku": body.SKU,
			"meta": meta, "progress": prog,
			"granted": map[string]any{"soft": soft, "hard": hard, "tickets": tickets, "vip_points": vip, "inventory": inv},
			"note": "TEST_PURCHASE — not a real payment / not revenue",
		})
	case store.ErrUnauthorized:
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
	case store.ErrInsufficient:
		writeErr(w, http.StatusConflict, "TEST_LIMIT_REACHED")
	default:
		writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
	}
}

func vipSoftTickets(level int) (soft, tickets int) {
	table := []struct{ soft, tickets int }{
		{0, 0}, {50, 0}, {80, 0}, {120, 1}, {160, 1}, {200, 1},
		{250, 2}, {300, 2}, {360, 2}, {420, 3}, {500, 3},
	}
	if level < 0 {
		level = 0
	}
	if level >= len(table) {
		level = len(table) - 1
	}
	return table[level].soft, table[level].tickets
}

func (s *Server) vipStatusV2(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	lvl := store.ComputeVIPLevel(acc.VipPoints)
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true, "vip_points": acc.VipPoints, "vip_level": lvl,
		"levels": 10, "pvp_power_bonus_cap_pct": 5,
		"lunex_visual_id": "lunex://vip/" + strconv.Itoa(lvl),
		"status": "draft_preliminary",
		"daily_claimed": acc.VipDailyClaimed,
	})
}

func (s *Server) vipClaimDaily(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	lvl := store.ComputeVIPLevel(acc.VipPoints)
	soft, tickets := vipSoftTickets(lvl)
	prog, already, err := s.Store.ClaimVIPDaily(bearer(r), soft, tickets)
	if err == store.ErrUnauthorized {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	if err != nil {
		writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true, "already": already, "granted_soft": soft, "granted_tickets": tickets, "progress": prog,
	})
}

func (s *Server) adminConfig(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r, "viewer") {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true,
		"gacha": map[string]any{
			"standard_rates": store.StandardRates,
			"advanced_rates": store.AdvancedRates,
			"pity_soft_sr": store.PitySoftSREvery,
			"pity_hard_ssr": store.PityHardSSREvery,
			"paid_banners_enabled": false,
		},
		"shop": map[string]any{"mode": "TEST_PURCHASE", "paid_provider": nil},
		"vip": map[string]any{"levels": 10, "pvp_cap_pct": 5},
	})
}
