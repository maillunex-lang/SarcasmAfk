package store

import (
	"strings"
	"sync"
	"time"
	"unicode"
)

const GuildCreateSoftCostDraft = 500

type Guild struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Tag         string            `json:"tag"`
	Emblem      string            `json:"emblem"`
	Description string            `json:"description"`
	JoinMode    string            `json:"join_mode"` // open | apply | invite
	Level       int               `json:"level"`
	XP          int               `json:"xp"`
	LeaderID    string            `json:"leader_id"`
	Members     map[string]string `json:"-"` // account -> role
	Log         []GuildLogEntry   `json:"log,omitempty"`
	CreatedAt   string            `json:"created_at"`
}

type GuildLogEntry struct {
	ActorID   string `json:"actor_id"`
	Action    string `json:"action"`
	Meta      string `json:"meta,omitempty"`
	CreatedAt string `json:"created_at"`
}

type GuildPublic struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Tag         string `json:"tag"`
	Emblem      string `json:"emblem"`
	Description string `json:"description"`
	JoinMode    string `json:"join_mode"`
	Level       int    `json:"level"`
	XP          int    `json:"xp"`
	LeaderID    string `json:"leader_id"`
	Members     int    `json:"members"`
	Cap         int    `json:"cap"`
	CreatedAt   string `json:"created_at"`
}

type GuildHub struct {
	mu     sync.Mutex
	guilds map[string]*Guild
	byTag  map[string]string
	byAcc  map[string]string // account -> guild
}

func NewGuildHub() *GuildHub {
	return &GuildHub{
		guilds: map[string]*Guild{},
		byTag:  map[string]string{},
		byAcc:  map[string]string{},
	}
}

func normalizeTag(tag string) string {
	tag = strings.ToUpper(strings.TrimSpace(tag))
	var b strings.Builder
	for _, r := range tag {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			b.WriteRune(r)
		}
	}
	return b.String()
}

func (h *GuildHub) List() []GuildPublic {
	h.mu.Lock()
	defer h.mu.Unlock()
	out := make([]GuildPublic, 0, len(h.guilds))
	for _, g := range h.guilds {
		out = append(out, g.Public())
	}
	return out
}

func (g *Guild) Public() GuildPublic {
	return GuildPublic{
		ID: g.ID, Name: g.Name, Tag: g.Tag, Emblem: g.Emblem, Description: g.Description,
		JoinMode: g.JoinMode, Level: g.Level, XP: g.XP, LeaderID: g.LeaderID,
		Members: len(g.Members), Cap: 30, CreatedAt: g.CreatedAt,
	}
}

func (h *GuildHub) Get(id string) (*Guild, bool) {
	h.mu.Lock()
	defer h.mu.Unlock()
	g, ok := h.guilds[id]
	return g, ok
}

func (h *GuildHub) ForAccount(accountID string) (*Guild, string, bool) {
	h.mu.Lock()
	defer h.mu.Unlock()
	gid, ok := h.byAcc[accountID]
	if !ok {
		return nil, "", false
	}
	g := h.guilds[gid]
	role := g.Members[accountID]
	return g, role, true
}

func (h *GuildHub) Create(leaderID, name, tag, desc string) (*Guild, error) {
	name = strings.TrimSpace(name)
	tag = normalizeTag(tag)
	if leaderID == "" || name == "" || len(tag) < 3 || len(tag) > 5 {
		return nil, ErrValidation
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	if _, ok := h.byAcc[leaderID]; ok {
		return nil, ErrValidation
	}
	if _, ok := h.byTag[tag]; ok {
		return nil, ErrValidation
	}
	id := newID("g_")
	g := &Guild{
		ID: id, Name: name, Tag: tag, Emblem: "lunex://guild/emblem/default",
		Description: strings.TrimSpace(desc), JoinMode: "open", Level: 1, XP: 0,
		LeaderID: leaderID, Members: map[string]string{leaderID: "leader"},
		CreatedAt: time.Now().UTC().Format(time.RFC3339),
	}
	g.Log = append(g.Log, GuildLogEntry{ActorID: leaderID, Action: "create", CreatedAt: g.CreatedAt})
	h.guilds[id] = g
	h.byTag[tag] = id
	h.byAcc[leaderID] = id
	return g, nil
}

func (h *GuildHub) Join(accountID, guildID string) (*Guild, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if _, ok := h.byAcc[accountID]; ok {
		return nil, ErrValidation
	}
	g, ok := h.guilds[guildID]
	if !ok {
		return nil, ErrNotFound
	}
	if len(g.Members) >= 30 {
		return nil, ErrValidation
	}
	if g.JoinMode != "open" {
		return nil, ErrValidation
	}
	g.Members[accountID] = "member"
	h.byAcc[accountID] = guildID
	g.Log = append(g.Log, GuildLogEntry{
		ActorID: accountID, Action: "join", CreatedAt: time.Now().UTC().Format(time.RFC3339),
	})
	return g, nil
}

func (h *GuildHub) Leave(accountID string) error {
	h.mu.Lock()
	defer h.mu.Unlock()
	gid, ok := h.byAcc[accountID]
	if !ok {
		return ErrNotFound
	}
	g := h.guilds[gid]
	role := g.Members[accountID]
	if role == "leader" && len(g.Members) > 1 {
		return ErrValidation // transfer leadership first
	}
	delete(g.Members, accountID)
	delete(h.byAcc, accountID)
	g.Log = append(g.Log, GuildLogEntry{
		ActorID: accountID, Action: "leave", CreatedAt: time.Now().UTC().Format(time.RFC3339),
	})
	if len(g.Members) == 0 {
		delete(h.byTag, g.Tag)
		delete(h.guilds, gid)
	}
	return nil
}
