package httpapi

import (
	"encoding/json"
	"net/http"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func (s *Server) adminChat(w http.ResponseWriter, r *http.Request) {
	if adminKey() == "" {
		writeErr(w, http.StatusServiceUnavailable, "ADMIN_NOT_CONFIGURED")
		return
	}
	path := r.URL.Path
	switch {
	case path == "/v1/admin/chat/reports" && r.Method == http.MethodGet:
		if !requireAdmin(w, r, "viewer") {
			return
		}
		appendAudit(adminRole(r), "chat_reports", path, "")
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "snapshot": s.Chat.ModerationSnapshot()})
	case path == "/v1/admin/chat/mute" && r.Method == http.MethodPost:
		if !requireAdmin(w, r, "admin") {
			return
		}
		var body struct {
			AccountID string `json:"account_id"`
			Seconds   int    `json:"seconds"`
			Unmute    bool   `json:"unmute"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		if body.AccountID == "" {
			writeErr(w, http.StatusBadRequest, "VALIDATION_FAILED")
			return
		}
		if body.Unmute {
			s.Chat.UnmuteAccount(body.AccountID)
			appendAudit("admin", "chat_unmute", path, body.AccountID)
		} else {
			s.Chat.MuteAccount(body.AccountID, body.Seconds)
			appendAudit("admin", "chat_mute", path, body.AccountID)
		}
		writeJSON(w, http.StatusOK, map[string]any{"ok": true})
	case path == "/v1/admin/chat/delete" && r.Method == http.MethodPost:
		if !requireAdmin(w, r, "admin") {
			return
		}
		var body struct {
			MessageID int64 `json:"message_id"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		s.Chat.DeleteMessage(body.MessageID)
		appendAudit("admin", "chat_delete", path, "")
		writeJSON(w, http.StatusOK, map[string]any{"ok": true})
	default:
		writeErr(w, http.StatusNotFound, "NOT_FOUND")
	}
}

func (s *Server) adminGuilds(w http.ResponseWriter, r *http.Request) {
	if adminKey() == "" {
		writeErr(w, http.StatusServiceUnavailable, "ADMIN_NOT_CONFIGURED")
		return
	}
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	if !requireAdmin(w, r, "viewer") {
		return
	}
	appendAudit(adminRole(r), "guilds_list", r.URL.Path, "")
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "guilds": s.Guilds.List()})
}

func (s *Server) guildDonate(w http.ResponseWriter, r *http.Request) {
	// handled via guildLive action; kept for clarity
	_ = store.GuildCreateSoftCostDraft
}
