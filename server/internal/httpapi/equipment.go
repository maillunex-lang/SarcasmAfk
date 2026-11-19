package httpapi

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func (s *Server) equipmentRoutes(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/equipment/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")
	if path == "" || parts[0] == "" {
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
		return
	}
	switch {
	case parts[0] == "catalog" && r.Method == http.MethodGet:
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "catalog": s.Content.EquipmentCatalogPublic()})
	case parts[0] == "balance" && r.Method == http.MethodGet:
		writeJSON(w, http.StatusOK, map[string]any{
			"ok": true, "balance_version": s.Content.EquipmentBalanceVersion(),
			"balance": s.Content.EquipmentBalance(),
		})
	case parts[0] == "inventory" && r.Method == http.MethodGet:
		s.equipmentInventory(w, r)
	case parts[0] == "pending-rewards" && r.Method == http.MethodGet:
		s.equipmentPending(w, r)
	case parts[0] == "pending-rewards" && len(parts) == 2 && parts[1] == "claim" && r.Method == http.MethodPost:
		s.equipmentClaimPending(w, r)
	case len(parts) == 2 && parts[1] == "equip" && r.Method == http.MethodPost:
		s.equipmentEquip(w, r, parts[0])
	case len(parts) == 2 && parts[1] == "unequip" && r.Method == http.MethodPost:
		s.equipmentUnequip(w, r, parts[0])
	case len(parts) == 2 && parts[1] == "upgrade" && r.Method == http.MethodPost:
		s.equipmentUpgrade(w, r, parts[0])
	case len(parts) == 2 && parts[1] == "lock" && r.Method == http.MethodPost:
		s.equipmentLock(w, r, parts[0])
	case len(parts) == 2 && parts[1] == "salvage" && r.Method == http.MethodPost:
		s.equipmentSalvage(w, r, parts[0])
	default:
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
	}
}

func (s *Server) heroEquipmentGet(w http.ResponseWriter, r *http.Request, heroID string) {
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	store.EnsureEquipment(acc)
	templates := s.Content.EquipmentTemplates()
	sets := s.Content.EquipmentSets()
	bal := s.Content.EquipmentBalance()
	flat, pct, counts := store.ComputeHeroGearFlat(acc, heroID, templates, sets, bal.UpgradeGrowth)
	base := s.heroBase(heroID)
	hp, atk, def, spd := store.EffectiveCombatStatsFull(acc, base, acc.HeroInstances[heroID], s.Content.EquipmentDefs(), templates, sets, bal.UpgradeGrowth)
	slots := map[string]any{"weapon": nil, "armor": nil, "accessory": nil, "relic": nil}
	if hi := acc.HeroInstances[heroID]; hi != nil && hi.Equipment != nil {
		for slot, iid := range hi.Equipment {
			if eq := acc.EquipmentBag[iid]; eq != nil {
				slots[slot] = eq
			} else if iid != "" {
				slots[slot] = map[string]any{"legacy_ref": iid}
			}
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true, "hero_id": heroID, "slots": slots,
		"flat_bonuses": flat, "set_pct": pct, "set_counts": counts,
		"combat": map[string]int{"hp": hp, "atk": atk, "defense": def, "speed": spd},
	})
}

func (s *Server) equipmentInventory(w http.ResponseWriter, r *http.Request) {
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	store.EnsureEquipment(acc)
	bal := s.Content.EquipmentBalance()
	templates := s.Content.EquipmentTemplates()
	_, _, _ = s.Store.MigrateLegacyEquipment(bearer(r), templates, bal)
	acc, _ = s.Store.AccountByToken(bearer(r))
	store.EnsureEquipment(acc)
	list := make([]*store.EquipmentInstance, 0, len(acc.EquipmentBag))
	for _, eq := range acc.EquipmentBag {
		list = append(list, eq)
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true, "instances": list, "capacity": bal.InventoryCapacity,
		"count": len(list), "pending": acc.EquipmentPending,
		"materials": map[string]int{"mat_equipment_scrap": acc.Inventory["mat_equipment_scrap"]},
		"soft_currency": acc.SoftCurrency,
	})
}

func (s *Server) equipmentPending(w http.ResponseWriter, r *http.Request) {
	acc, err := s.Store.AccountByToken(bearer(r))
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	store.EnsureEquipment(acc)
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "pending": acc.EquipmentPending})
}

func (s *Server) equipmentClaimPending(w http.ResponseWriter, r *http.Request) {
	tok := bearer(r)
	acc, err := s.Store.AccountByToken(tok)
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	store.EnsureEquipment(acc)
	templates := s.Content.EquipmentTemplates()
	bal := s.Content.EquipmentBalance()
	if len(acc.EquipmentPending) == 0 {
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "claimed": []any{}})
		return
	}
	// Claim first pending entry into inventory.
	entry := acc.EquipmentPending[0]
	tplID, _ := entry["template_id"].(string)
	src, _ := entry["source"].(string)
	key := "pending-claim:" + tplID + ":" + src
	prog, inst, err := s.Store.GrantEquipmentReward(tok, key, tplID, src, templates, bal)
	if err != nil {
		s.writeEquipErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "instance": inst, "progress": prog})
}

func (s *Server) equipmentEquip(w http.ResponseWriter, r *http.Request, instanceID string) {
	var body struct {
		HeroID          string `json:"hero_id"`
		Slot            string `json:"slot"`
		RequestID       string `json:"request_id"`
		ExpectedVersion int    `json:"expected_version"`
		ConfirmTransfer bool   `json:"confirm_transfer"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.HeroID == "" || body.Slot == "" {
		writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		return
	}
	base := s.heroBase(body.HeroID)
	heroClass := s.heroClass(body.HeroID)
	prog, inst, extras, err := s.Store.EquipInstance(
		bearer(r), instanceID, body.HeroID, body.Slot, body.ConfirmTransfer, body.ExpectedVersion, body.RequestID,
		base, heroClass, s.Content.EquipmentTemplates(), s.Content.EquipmentSets(), s.Content.EquipmentBalance(),
	)
	if err != nil {
		s.writeEquipErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "instance": inst, "progress": prog, "result": extras})
}

func (s *Server) equipmentUnequip(w http.ResponseWriter, r *http.Request, instanceID string) {
	var body struct {
		RequestID       string `json:"request_id"`
		ExpectedVersion int    `json:"expected_version"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)
	prog, inst, err := s.Store.UnequipInstance(bearer(r), instanceID, body.ExpectedVersion, body.RequestID)
	if err != nil {
		s.writeEquipErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "instance": inst, "progress": prog})
}

func (s *Server) equipmentUpgrade(w http.ResponseWriter, r *http.Request, instanceID string) {
	var body struct {
		RequestID       string `json:"request_id"`
		ExpectedVersion int    `json:"expected_version"`
		Levels          int    `json:"levels"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)
	base := store.HeroBaseStats{}
	prog, inst, extras, err := s.Store.UpgradeInstance(
		bearer(r), instanceID, body.ExpectedVersion, body.RequestID, base,
		s.Content.EquipmentTemplates(), s.Content.EquipmentSets(), s.Content.EquipmentBalance(),
	)
	if err != nil {
		s.writeEquipErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "instance": inst, "progress": prog, "result": extras})
}

func (s *Server) equipmentLock(w http.ResponseWriter, r *http.Request, instanceID string) {
	var body struct {
		Locked          bool   `json:"locked"`
		RequestID       string `json:"request_id"`
		ExpectedVersion int    `json:"expected_version"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		return
	}
	prog, inst, err := s.Store.LockInstance(bearer(r), instanceID, body.Locked, body.ExpectedVersion, body.RequestID)
	if err != nil {
		s.writeEquipErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "instance": inst, "progress": prog})
}

func (s *Server) equipmentSalvage(w http.ResponseWriter, r *http.Request, instanceID string) {
	var body struct {
		RequestID       string `json:"request_id"`
		ExpectedVersion int    `json:"expected_version"`
		Confirm         bool   `json:"confirm"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		return
	}
	prog, reward, err := s.Store.SalvageInstance(
		bearer(r), instanceID, body.ExpectedVersion, body.RequestID, body.Confirm,
		s.Content.EquipmentTemplates(), s.Content.EquipmentBalance(),
	)
	if err != nil {
		s.writeEquipErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "reward": reward, "progress": prog})
}

func (s *Server) heroClass(id string) string {
	m := s.Content.HeroMap()
	raw, ok := m[id]
	if !ok {
		return ""
	}
	h, _ := raw.(map[string]any)
	for _, k := range []string{"class", "role"} {
		if v, ok := h[k].(string); ok && v != "" {
			return v
		}
	}
	return ""
}

func (s *Server) writeEquipErr(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, store.ErrUnauthorized):
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
	case errors.Is(err, store.ErrEquipNotOwned):
		writeErr(w, http.StatusNotFound, "NOT_OWNED")
	case errors.Is(err, store.ErrNotOwned):
		writeErr(w, http.StatusNotFound, "HERO_NOT_OWNED")
	case errors.Is(err, store.ErrInsufficient):
		writeErr(w, http.StatusConflict, "INSUFFICIENT_RESOURCES")
	case errors.Is(err, store.ErrLevelCap):
		writeErr(w, http.StatusConflict, "LEVEL_CAP")
	case errors.Is(err, store.ErrInvalidSlot):
		writeErr(w, http.StatusUnprocessableEntity, store.ErrInvalidSlotCode)
	case errors.Is(err, store.ErrClassRestricted):
		writeErr(w, http.StatusUnprocessableEntity, store.ErrClassRestrictedCode)
	case errors.Is(err, store.ErrLevelTooLow):
		writeErr(w, http.StatusUnprocessableEntity, store.ErrLevelTooLowCode)
	case errors.Is(err, store.ErrItemLocked):
		writeErr(w, http.StatusConflict, store.ErrItemLockedCode)
	case errors.Is(err, store.ErrAlreadyEquipped):
		writeErr(w, http.StatusConflict, store.ErrAlreadyEquippedCode)
	case errors.Is(err, store.ErrInventoryFull):
		writeErr(w, http.StatusConflict, store.ErrInventoryFullCode)
	case errors.Is(err, store.ErrVersionConflict):
		writeErr(w, http.StatusConflict, store.ErrVersionConflictCode)
	case errors.Is(err, store.ErrInvalidTemplate):
		writeErr(w, http.StatusUnprocessableEntity, store.ErrInvalidTemplateCode)
	case errors.Is(err, store.ErrConfirmTransfer):
		writeErr(w, http.StatusConflict, store.ErrConfirmTransferCode)
	default:
		writeErr(w, http.StatusUnprocessableEntity, "VALIDATION_FAILED")
	}
}
