package store

// ChatService is the chat/moderation backend (memory or Postgres).
type ChatService interface {
	Post(channel, accountID, displayName, body string, level int) (ChatMessage, error)
	History(channel string, beforeID int64, limit int) []ChatMessage
	Block(accountID, targetID string)
	IsBlocked(accountID, otherID string) bool
	Report(reporterID string, messageID int64, reason string)
	Reports() []map[string]any
	MuteAccount(accountID string, durationSec int)
	UnmuteAccount(accountID string)
	DeleteMessage(id int64) bool
	ModerationSnapshot() map[string]any
}

var _ ChatService = (*ChatHub)(nil)
