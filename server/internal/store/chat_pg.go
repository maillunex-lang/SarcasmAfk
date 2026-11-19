package store

import (
	"context"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

// PostgresChat persists messages/blocks/reports/mutes; rate-limit stays local (+ optional Redis).
type PostgresChat struct {
	pool *pgxpool.Pool
	rdb  *redis.Client
	ctx  context.Context

	mu       sync.Mutex
	lastSent map[string]time.Time
	lastBody map[string]string
	lastAt   map[string]time.Time
}

func NewPostgresChat(ctx context.Context, pool *pgxpool.Pool, rdb *redis.Client) *PostgresChat {
	return &PostgresChat{
		pool: pool, rdb: rdb, ctx: ctx,
		lastSent: map[string]time.Time{},
		lastBody: map[string]string{},
		lastAt:   map[string]time.Time{},
	}
}

func (c *PostgresChat) rateOK(accountID, channel, body string) error {
	key := accountID + ":" + channel
	now := time.Now()
	c.mu.Lock()
	defer c.mu.Unlock()
	if t, ok := c.lastSent[key]; ok && now.Sub(t) < ChatRateMinGap {
		return ErrValidation
	}
	if prev, ok := c.lastBody[key]; ok && prev == body {
		if t, ok := c.lastAt[key]; ok && now.Sub(t) < ChatDupWindow {
			return ErrValidation
		}
	}
	c.lastSent[key] = now
	c.lastBody[key] = body
	c.lastAt[key] = now
	if c.rdb != nil {
		rkey := "chat:rl:" + key
		ok, err := c.rdb.SetNX(c.ctx, rkey, "1", ChatRateMinGap).Result()
		if err == nil && !ok {
			return ErrValidation
		}
	}
	return nil
}

func (c *PostgresChat) Post(channel, accountID, displayName, body string, level int) (ChatMessage, error) {
	body = SanitizeChatBody(body)
	if channel == "" || accountID == "" || body == "" {
		return ChatMessage{}, ErrValidation
	}
	prefixOK := false
	for _, p := range []string{"global", "system", "dm:", "guild:"} {
		if len(channel) >= len(p) && channel[:len(p)] == p {
			prefixOK = true
			break
		}
	}
	if !prefixOK {
		return ChatMessage{}, ErrValidation
	}
	var until time.Time
	err := c.pool.QueryRow(c.ctx, `SELECT muted_until FROM chat_mutes WHERE account_id=$1`, accountID).Scan(&until)
	if err == nil && time.Now().Before(until) {
		return ChatMessage{}, ErrMuted
	}
	if err := c.rateOK(accountID, channel, body); err != nil {
		return ChatMessage{}, err
	}
	if level <= 0 {
		level = 1
	}
	avatar := "lunex://heroes/avatar/default"
	var id int64
	var created time.Time
	err = c.pool.QueryRow(c.ctx, `
		INSERT INTO chat_messages(channel, account_id, display_name, body, level, avatar)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id, created_at`,
		channel, accountID, displayName, body, level, avatar,
	).Scan(&id, &created)
	if err != nil {
		return ChatMessage{}, err
	}
	return ChatMessage{
		ID: id, Channel: channel, AccountID: accountID, DisplayName: displayName,
		Level: level, Avatar: avatar, Body: body, CreatedAt: created.UTC().Format(time.RFC3339),
	}, nil
}

func (c *PostgresChat) History(channel string, beforeID int64, limit int) []ChatMessage {
	if limit <= 0 {
		limit = ChatHistoryDefault
	}
	if limit > ChatHistoryMax {
		limit = ChatHistoryMax
	}
	q := `
		SELECT id, channel, account_id, display_name, COALESCE(level,1), COALESCE(avatar,''), body, created_at
		FROM chat_messages
		WHERE channel=$1 AND deleted=false`
	args := []any{channel}
	if beforeID > 0 {
		q += ` AND id < $2`
		args = append(args, beforeID)
		q += ` ORDER BY id DESC LIMIT $3`
		args = append(args, limit)
	} else {
		q += ` ORDER BY id DESC LIMIT $2`
		args = append(args, limit)
	}
	rows, err := c.pool.Query(c.ctx, q, args...)
	if err != nil {
		return nil
	}
	defer rows.Close()
	var rev []ChatMessage
	for rows.Next() {
		var m ChatMessage
		var created time.Time
		if err := rows.Scan(&m.ID, &m.Channel, &m.AccountID, &m.DisplayName, &m.Level, &m.Avatar, &m.Body, &created); err != nil {
			continue
		}
		m.CreatedAt = created.UTC().Format(time.RFC3339)
		rev = append(rev, m)
	}
	out := make([]ChatMessage, 0, len(rev))
	for i := len(rev) - 1; i >= 0; i-- {
		out = append(out, rev[i])
	}
	return out
}

func (c *PostgresChat) Block(accountID, targetID string) {
	_, _ = c.pool.Exec(c.ctx, `
		INSERT INTO chat_blocks(account_id, blocked_id) VALUES ($1,$2)
		ON CONFLICT DO NOTHING`, accountID, targetID)
}

func (c *PostgresChat) IsBlocked(accountID, otherID string) bool {
	var n int
	_ = c.pool.QueryRow(c.ctx, `
		SELECT 1 FROM chat_blocks WHERE account_id=$1 AND blocked_id=$2`, accountID, otherID).Scan(&n)
	return n == 1
}

func (c *PostgresChat) Report(reporterID string, messageID int64, reason string) {
	_, _ = c.pool.Exec(c.ctx, `
		INSERT INTO chat_reports(reporter_id, message_id, reason) VALUES ($1,$2,$3)`,
		reporterID, messageID, SanitizeChatBody(reason))
}

func (c *PostgresChat) Reports() []map[string]any {
	rows, err := c.pool.Query(c.ctx, `
		SELECT id, reporter_id, message_id, reason, created_at FROM chat_reports ORDER BY id DESC LIMIT 100`)
	if err != nil {
		return nil
	}
	defer rows.Close()
	var out []map[string]any
	for rows.Next() {
		var id, mid int64
		var reporter, reason string
		var created time.Time
		if err := rows.Scan(&id, &reporter, &mid, &reason, &created); err != nil {
			continue
		}
		out = append(out, map[string]any{
			"id": id, "reporter_id": reporter, "message_id": mid, "reason": reason,
			"created_at": created.UTC().Format(time.RFC3339),
		})
	}
	return out
}

func (c *PostgresChat) MuteAccount(accountID string, durationSec int) {
	if durationSec <= 0 {
		durationSec = 3600
	}
	until := time.Now().Add(time.Duration(durationSec) * time.Second)
	_, _ = c.pool.Exec(c.ctx, `
		INSERT INTO chat_mutes(account_id, muted_until) VALUES ($1,$2)
		ON CONFLICT (account_id) DO UPDATE SET muted_until=EXCLUDED.muted_until`, accountID, until)
}

func (c *PostgresChat) UnmuteAccount(accountID string) {
	_, _ = c.pool.Exec(c.ctx, `DELETE FROM chat_mutes WHERE account_id=$1`, accountID)
}

func (c *PostgresChat) DeleteMessage(id int64) bool {
	tag, err := c.pool.Exec(c.ctx, `UPDATE chat_messages SET deleted=true WHERE id=$1`, id)
	return err == nil && tag.RowsAffected() > 0
}

func (c *PostgresChat) ModerationSnapshot() map[string]any {
	var msgCount, delCount, muteCount int
	_ = c.pool.QueryRow(c.ctx, `SELECT COUNT(*) FROM chat_messages`).Scan(&msgCount)
	_ = c.pool.QueryRow(c.ctx, `SELECT COUNT(*) FROM chat_messages WHERE deleted=true`).Scan(&delCount)
	_ = c.pool.QueryRow(c.ctx, `SELECT COUNT(*) FROM chat_mutes WHERE muted_until > NOW()`).Scan(&muteCount)
	return map[string]any{
		"reports":         c.Reports(),
		"message_count":   msgCount,
		"deleted_count":   delCount,
		"active_mutes":    muteCount,
		"backend":         "postgres",
	}
}

var _ ChatService = (*PostgresChat)(nil)
