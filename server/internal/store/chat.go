package store

import (
	"errors"
	"strings"
	"sync"
	"time"
	"unicode/utf8"
)

const (
	ChatMaxBodyRunes   = 280
	ChatRateMinGap     = 2 * time.Second
	ChatDupWindow      = 30 * time.Second
	ChatHistoryDefault = 50
	ChatHistoryMax     = 100
)

type ChatMessage struct {
	ID          int64  `json:"id"`
	Channel     string `json:"channel"`
	AccountID   string `json:"account_id"`
	DisplayName string `json:"display_name"`
	Level       int    `json:"level"`
	Avatar      string `json:"avatar"`
	Body        string `json:"body"`
	CreatedAt   string `json:"created_at"`
}

type ChatHub struct {
	mu            sync.Mutex
	nextID        int64
	msgs          map[string][]ChatMessage // channel -> messages
	lastSent      map[string]time.Time     // account:channel
	lastBody      map[string]string        // account:channel
	lastAt        map[string]time.Time
	blocks        map[string]map[string]bool // account -> blocked
	reports       []map[string]any
	mutedChannels map[string]bool      // channel sound mute (client preference mirrored)
	mutedUntil    map[string]time.Time // account mute (moderation)
	deleted       map[int64]bool
}

func NewChatHub() *ChatHub {
	return &ChatHub{
		msgs:          map[string][]ChatMessage{},
		lastSent:      map[string]time.Time{},
		lastBody:      map[string]string{},
		lastAt:        map[string]time.Time{},
		blocks:        map[string]map[string]bool{},
		mutedChannels: map[string]bool{},
		mutedUntil:    map[string]time.Time{},
		deleted:       map[int64]bool{},
	}
}

var ErrMuted = errors.New("MUTED")

func SanitizeChatBody(raw string) string {
	s := strings.TrimSpace(raw)
	s = strings.ReplaceAll(s, "\x00", "")
	// Strip angle brackets to prevent HTML/script injection in clients that render rich text.
	s = strings.ReplaceAll(s, "<", "")
	s = strings.ReplaceAll(s, ">", "")
	if utf8.RuneCountInString(s) > ChatMaxBodyRunes {
		r := []rune(s)
		s = string(r[:ChatMaxBodyRunes])
	}
	return s
}

func (h *ChatHub) Post(channel, accountID, displayName, body string, level int) (ChatMessage, error) {
	body = SanitizeChatBody(body)
	if channel == "" || accountID == "" || body == "" {
		return ChatMessage{}, ErrValidation
	}
	if !strings.HasPrefix(channel, "global") && !strings.HasPrefix(channel, "system") &&
		!strings.HasPrefix(channel, "dm:") && !strings.HasPrefix(channel, "guild:") {
		return ChatMessage{}, ErrValidation
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	now := time.Now()
	if until, ok := h.mutedUntil[accountID]; ok && now.Before(until) {
		return ChatMessage{}, ErrMuted
	}
	key := accountID + ":" + channel
	if t, ok := h.lastSent[key]; ok && now.Sub(t) < ChatRateMinGap {
		return ChatMessage{}, ErrValidation
	}
	if prev, ok := h.lastBody[key]; ok && prev == body {
		if t, ok := h.lastAt[key]; ok && now.Sub(t) < ChatDupWindow {
			return ChatMessage{}, ErrValidation
		}
	}
	h.nextID++
	msg := ChatMessage{
		ID:          h.nextID,
		Channel:     channel,
		AccountID:   accountID,
		DisplayName: displayName,
		Level:       level,
		Avatar:      "lunex://heroes/avatar/default",
		Body:        body,
		CreatedAt:   now.UTC().Format(time.RFC3339),
	}
	h.msgs[channel] = append(h.msgs[channel], msg)
	h.lastSent[key] = now
	h.lastBody[key] = body
	h.lastAt[key] = now
	return msg, nil
}

func (h *ChatHub) History(channel string, beforeID int64, limit int) []ChatMessage {
	if limit <= 0 {
		limit = ChatHistoryDefault
	}
	if limit > ChatHistoryMax {
		limit = ChatHistoryMax
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	all := h.msgs[channel]
	out := make([]ChatMessage, 0, limit)
	for i := len(all) - 1; i >= 0 && len(out) < limit; i-- {
		m := all[i]
		if h.deleted[m.ID] {
			continue
		}
		if beforeID > 0 && m.ID >= beforeID {
			continue
		}
		out = append(out, m)
	}
	// reverse to chronological
	for i, j := 0, len(out)-1; i < j; i, j = i+1, j-1 {
		out[i], out[j] = out[j], out[i]
	}
	return out
}

func (h *ChatHub) Block(accountID, targetID string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.blocks[accountID] == nil {
		h.blocks[accountID] = map[string]bool{}
	}
	h.blocks[accountID][targetID] = true
}

func (h *ChatHub) IsBlocked(accountID, otherID string) bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	return h.blocks[accountID][otherID]
}

func (h *ChatHub) Report(reporterID string, messageID int64, reason string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.reports = append(h.reports, map[string]any{
		"reporter_id": reporterID,
		"message_id":  messageID,
		"reason":      SanitizeChatBody(reason),
		"created_at":  time.Now().UTC().Format(time.RFC3339),
	})
}

func (h *ChatHub) Reports() []map[string]any {
	h.mu.Lock()
	defer h.mu.Unlock()
	out := make([]map[string]any, len(h.reports))
	copy(out, h.reports)
	return out
}

func (h *ChatHub) MuteAccount(accountID string, durationSec int) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if durationSec <= 0 {
		durationSec = 3600
	}
	h.mutedUntil[accountID] = time.Now().Add(time.Duration(durationSec) * time.Second)
}

func (h *ChatHub) UnmuteAccount(accountID string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	delete(h.mutedUntil, accountID)
}

func (h *ChatHub) DeleteMessage(id int64) bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.deleted[id] = true
	return true
}

func (h *ChatHub) SetChannelMute(channel string, muted bool) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.mutedChannels[channel] = muted
}

func (h *ChatHub) ModerationSnapshot() map[string]any {
	h.mu.Lock()
	defer h.mu.Unlock()
	mutes := map[string]string{}
	for id, until := range h.mutedUntil {
		mutes[id] = until.UTC().Format(time.RFC3339)
	}
	return map[string]any{
		"reports":        append([]map[string]any{}, h.reports...),
		"muted_accounts": mutes,
		"deleted_count":  len(h.deleted),
		"channels":       len(h.msgs),
	}
}
