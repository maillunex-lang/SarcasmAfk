package httpapi

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func (s *Server) ch01Campaign(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/campaign/ch01/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")
	if len(parts) == 0 || parts[0] == "" {
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
		return
	}
	tok := bearer(r)
	acc, err := s.Store.AccountByToken(tok)
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	store.EnsureExpansion(acc)

	switch {
	case parts[0] == "sidequests" && r.Method == http.MethodGet && len(parts) == 1:
		s.ch01ListSidequests(w, acc)
	case parts[0] == "sidequests" && len(parts) == 3 && parts[2] == "start" && r.Method == http.MethodPost:
		s.ch01StartSidequest(w, tok, parts[1])
	case parts[0] == "sidequests" && len(parts) == 3 && parts[2] == "claim" && r.Method == http.MethodPost:
		s.ch01ClaimSidequest(w, tok, parts[1])
	case parts[0] == "poi" && len(parts) == 3 && parts[2] == "interact" && r.Method == http.MethodPost:
		s.ch01InteractPOI(w, r, tok, parts[1])
	case parts[0] == "journal" && r.Method == http.MethodGet:
		writeJSON(w, http.StatusOK, map[string]any{
			"ok":            true,
			"journal_flags": acc.JournalFlags,
			"sidequests":    acc.Sidequests,
			"poi_progress":  acc.POIProgress,
			"quest_flags":   acc.QuestFlags,
		})
	default:
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
	}
}

func (s *Server) ch01ListSidequests(w http.ResponseWriter, acc *store.AccountProgress) {
	out := []map[string]any{}
	for id, def := range s.Content.Sidequests() {
		st := acc.Sidequests[id]
		state := "locked"
		if def.RequiredQuest == "" || acc.QuestFlags[def.RequiredQuest] {
			state = "available"
		}
		if st != nil && st.State != "" {
			state = st.State
		}
		steps := []string{}
		if st != nil {
			steps = st.CompletedStepIDs
		}
		out = append(out, map[string]any{
			"quest_id":               id,
			"title":                  def.Title,
			"state":                  state,
			"location_id":            def.LocationID,
			"completed_step_ids":     steps,
			"reward_bundle_id":       def.RewardBundleID,
			"required_for_final_boss": def.RequiredForFinalBoss,
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "sidequests": out})
}

func (s *Server) ch01StartSidequest(w http.ResponseWriter, tok, questID string) {
	def, ok := s.Content.Sidequest(questID)
	if !ok {
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
		return
	}
	prog, err := s.Store.StartSidequest(tok, questID, def.RequiredQuest)
	if err != nil {
		writeErr(w, http.StatusConflict, "VALIDATION_FAILED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok":                true,
		"sidequest":         prog.Sidequests[questID],
		"start_dialogue_id": def.StartDialogueID,
		"progress":          prog,
	})
}

func (s *Server) ch01ClaimSidequest(w http.ResponseWriter, tok, questID string) {
	def, ok := s.Content.Sidequest(questID)
	if !ok {
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
		return
	}
	bundle, ok := s.Content.RewardBundle(def.RewardBundleID)
	if !ok {
		writeErr(w, http.StatusNotFound, "REWARD_NOT_FOUND")
		return
	}
	prog, already, granted, err := s.Store.ClaimSidequest(tok, questID, def.StepIDs, bundle, s.Content.EquipmentDefs())
	if err != nil {
		writeErr(w, http.StatusConflict, "VALIDATION_FAILED")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok":        true,
		"already":   already,
		"granted":   granted,
		"bundle_id": bundle.BundleID,
		"progress":  prog,
	})
}

func (s *Server) ch01InteractPOI(w http.ResponseWriter, r *http.Request, tok, poiID string) {
	def, ok := s.Content.GetPOI(poiID)
	if !ok {
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
		return
	}
	var body struct {
		ActionID string `json:"action_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ActionID == "" {
		writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
		return
	}
	stepID := ""
	for _, a := range def.Actions {
		aid, _ := a["action_id"].(string)
		if aid == body.ActionID {
			stepID, _ = a["step_id"].(string)
			break
		}
	}
	var sequence []string
	if def.SidequestID != "" {
		if sq, ok := s.Content.Sidequest(def.SidequestID); ok && !sq.StepsAnyOrder && len(sq.StepSequence) > 0 {
			sequence = sq.StepSequence
		}
	}
	prog, reset, err := s.Store.InteractPOI(tok, poiID, body.ActionID, stepID, def.SidequestID, sequence, def.CompletionFlag, def.OneTime)
	if err != nil {
		writeErr(w, http.StatusConflict, "VALIDATION_FAILED")
		return
	}
	var side any
	if def.SidequestID != "" {
		side = prog.Sidequests[def.SidequestID]
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ok":            true,
		"poi_id":        poiID,
		"action_id":     body.ActionID,
		"puzzle_reset":  reset,
		"poi_progress":  prog.POIProgress[poiID],
		"sidequest":     side,
		"journal_flags": prog.JournalFlags,
		"progress":      prog,
	})
}
