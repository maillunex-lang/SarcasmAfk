package httpapi

import (
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

// Admin auth (D-ADMIN-01): X-Admin-Key or Bearer matching ADMIN_API_KEY.
// Roles: admin (full), viewer (metrics read). Service key = admin.

type auditEntry struct {
	At     string `json:"at"`
	Actor  string `json:"actor"`
	Action string `json:"action"`
	Path   string `json:"path"`
	Detail string `json:"detail,omitempty"`
}

var (
	auditMu   sync.Mutex
	auditLog  []auditEntry
	maxAudit  = 200
)

func adminKey() string {
	return strings.TrimSpace(os.Getenv("ADMIN_API_KEY"))
}

func adminRole(r *http.Request) string {
	key := adminKey()
	if key == "" {
		return "" // admin locked until key configured
	}
	h := r.Header.Get("X-Admin-Key")
	if h == "" {
		auth := r.Header.Get("Authorization")
		if strings.HasPrefix(auth, "Bearer ") {
			h = strings.TrimPrefix(auth, "Bearer ")
		}
	}
	if h == "" || h != key {
		return ""
	}
	// Optional role override for service accounts: X-Admin-Role: viewer|admin
	role := strings.ToLower(strings.TrimSpace(r.Header.Get("X-Admin-Role")))
	if role == "viewer" {
		return "viewer"
	}
	return "admin"
}

func requireAdmin(w http.ResponseWriter, r *http.Request, minRole string) bool {
	role := adminRole(r)
	if role == "" {
		writeErr(w, http.StatusUnauthorized, "ADMIN_UNAUTHORIZED")
		return false
	}
	if minRole == "admin" && role != "admin" {
		writeErr(w, http.StatusForbidden, "ADMIN_FORBIDDEN")
		return false
	}
	return true
}

func appendAudit(actor, action, path, detail string) {
	auditMu.Lock()
	defer auditMu.Unlock()
	auditLog = append(auditLog, auditEntry{
		At: time.Now().UTC().Format(time.RFC3339), Actor: actor, Action: action, Path: path, Detail: detail,
	})
	if len(auditLog) > maxAudit {
		auditLog = auditLog[len(auditLog)-maxAudit:]
	}
	log.Printf("AUDIT actor=%s action=%s path=%s %s", actor, action, path, detail)
}

func (s *Server) adminMetrics(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	if adminKey() == "" {
		writeErr(w, http.StatusServiceUnavailable, "ADMIN_NOT_CONFIGURED")
		return
	}
	if !requireAdmin(w, r, "viewer") {
		return
	}
	appendAudit(adminRole(r), "metrics", r.URL.Path, "")
	snap := map[string]any{"ok": true, "backend": s.Backend, "heroes": len(s.Content.HeroIDs())}
	if s.Metrics != nil {
		for k, v := range s.Metrics.Snapshot() {
			snap[k] = v
		}
	}
	writeJSON(w, http.StatusOK, snap)
}

func (s *Server) adminAudit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "METHOD")
		return
	}
	if adminKey() == "" {
		writeErr(w, http.StatusServiceUnavailable, "ADMIN_NOT_CONFIGURED")
		return
	}
	if !requireAdmin(w, r, "admin") {
		return
	}
	appendAudit("admin", "audit_read", r.URL.Path, "")
	auditMu.Lock()
	defer auditMu.Unlock()
	out := make([]auditEntry, len(auditLog))
	copy(out, auditLog)
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "entries": out})
}
