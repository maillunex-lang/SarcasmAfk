package store

import (
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"
)

const GuildCreateSoftCostDraft = 500

type GuildQuest struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Target      int    `json:"target"`
	Progress    int    `json:"progress"`
	RewardXP    int    `json:"reward_xp"`
	RewardSoft  int    `json:"reward_soft_vault"`
	Day         string `json:"day"`
	Completed   bool   `json:"completed"`
}

type Guild struct {
	ID            string            `json:"id"`
	Name          string            `json:"name"`
	Tag           string            `json:"tag"`
	Emblem        string            `json:"emblem"`
	Description   string            `json:"description"`
	JoinMode      string            `json:"join_mode"` // open | apply | invite
	Level         int               `json:"level"`
	XP            int               `json:"xp"`
	LeaderID      string            `json:"leader_id"`
	Members       map[string]string `json:"-"` // account -> role
	ContribXP     map[string]int    `json:"-"` // account -> contribution
	VaultSoft     int               `json:"vault_soft"`
	Permissions   map[string]any    `json:"permissions,omitempty"`
	Announcements []string          `json:"announcements,omitempty"`
	Pinned        string            `json:"pinned,omitempty"`
	Quests        []GuildQuest      `json:"quests,omitempty"`
	Log           []GuildLogEntry   `json:"log,omitempty"`
	CreatedAt     string            `json:"created_at"`
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
	VaultSoft   int    `json:"vault_soft"`
	CreatedAt   string `json:"created_at"`
}

type GuildMemberBoard struct {
	AccountID string `json:"account_id"`
	Role      string `json:"role"`
	ContribXP int    `json:"contrib_xp"`
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
		Members: len(g.Members), Cap: 30, VaultSoft: g.VaultSoft, CreatedAt: g.CreatedAt,
	}
}

func ensureDailyQuests(g *Guild) {
	day := time.Now().UTC().Format("2006-01-02")
	if len(g.Quests) > 0 && g.Quests[0].Day == day {
		return
	}
	g.Quests = []GuildQuest{
		{ID: "gq_chat", Title: "Написать в гильдейский чат", Target: 5, RewardXP: 20, RewardSoft: 100, Day: day},
		{ID: "gq_donate", Title: "Внести вклад в казну", Target: 3, RewardXP: 30, RewardSoft: 200, Day: day},
		{ID: "gq_active", Title: "Ежедневная активность участников", Target: 10, RewardXP: 50, RewardSoft: 300, Day: day},
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
		ContribXP: map[string]int{leaderID: 0},
		VaultSoft: 0,
		Permissions: map[string]any{
			"leader":  []string{"invite", "kick", "announce", "pin", "transfer", "edit", "vault"},
			"officer": []string{"invite", "kick", "announce"},
			"member":  []string{"chat", "donate"},
		},
		CreatedAt: time.Now().UTC().Format(time.RFC3339),
	}
	ensureDailyQuests(g)
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
	if g.ContribXP == nil {
		g.ContribXP = map[string]int{}
	}
	g.ContribXP[accountID] = 0
	h.byAcc[accountID] = guildID
	ensureDailyQuests(g)
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

func (h *GuildHub) SetRole(actorID, targetID, role string) error {
	h.mu.Lock()
	defer h.mu.Unlock()
	gid, ok := h.byAcc[actorID]
	if !ok {
		return ErrNotFound
	}
	g := h.guilds[gid]
	if g.Members[actorID] != "leader" && g.Members[actorID] != "officer" {
		return ErrValidation
	}
	if role != "officer" && role != "member" {
		return ErrValidation
	}
	if _, ok := g.Members[targetID]; !ok {
		return ErrNotFound
	}
	if targetID == g.LeaderID {
		return ErrValidation
	}
	g.Members[targetID] = role
	g.Log = append(g.Log, GuildLogEntry{
		ActorID: actorID, Action: "set_role", Meta: targetID + "=" + role,
		CreatedAt: time.Now().UTC().Format(time.RFC3339),
	})
	return nil
}

func (h *GuildHub) Announce(actorID, text string) error {
	h.mu.Lock()
	defer h.mu.Unlock()
	gid, ok := h.byAcc[actorID]
	if !ok {
		return ErrNotFound
	}
	g := h.guilds[gid]
	role := g.Members[actorID]
	if role != "leader" && role != "officer" {
		return ErrValidation
	}
	g.Announcements = append(g.Announcements, text)
	if len(g.Announcements) > 20 {
		g.Announcements = g.Announcements[len(g.Announcements)-20:]
	}
	g.Log = append(g.Log, GuildLogEntry{
		ActorID: actorID, Action: "announce", CreatedAt: time.Now().UTC().Format(time.RFC3339),
	})
	return nil
}

func (h *GuildHub) ChatChannel(accountID string) (string, bool) {
	h.mu.Lock()
	defer h.mu.Unlock()
	gid, ok := h.byAcc[accountID]
	if !ok {
		return "", false
	}
	return "guild:" + gid, true
}

func (h *GuildHub) MemberBoard(accountID string) ([]GuildMemberBoard, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	gid, ok := h.byAcc[accountID]
	if !ok {
		return nil, ErrNotFound
	}
	g := h.guilds[gid]
	if g.ContribXP == nil {
		g.ContribXP = map[string]int{}
	}
	out := make([]GuildMemberBoard, 0, len(g.Members))
	for id, role := range g.Members {
		out = append(out, GuildMemberBoard{AccountID: id, Role: role, ContribXP: g.ContribXP[id]})
	}
	return out, nil
}

func (h *GuildHub) Quests(accountID string) ([]GuildQuest, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	gid, ok := h.byAcc[accountID]
	if !ok {
		return nil, ErrNotFound
	}
	g := h.guilds[gid]
	ensureDailyQuests(g)
	out := make([]GuildQuest, len(g.Quests))
	copy(out, g.Quests)
	return out, nil
}

func (h *GuildHub) ProgressQuest(accountID, questID string, delta int) (*Guild, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	gid, ok := h.byAcc[accountID]
	if !ok {
		return nil, ErrNotFound
	}
	g := h.guilds[gid]
	ensureDailyQuests(g)
	if g.ContribXP == nil {
		g.ContribXP = map[string]int{}
	}
	for i := range g.Quests {
		q := &g.Quests[i]
		if q.ID != questID || q.Completed {
			continue
		}
		q.Progress += delta
		g.ContribXP[accountID] += delta
		if q.Progress >= q.Target {
			q.Progress = q.Target
			q.Completed = true
			g.XP += q.RewardXP
			g.VaultSoft += q.RewardSoft
			for g.XP >= g.Level*100 {
				g.XP -= g.Level * 100
				g.Level++
			}
			g.Log = append(g.Log, GuildLogEntry{
				ActorID: accountID, Action: "quest_complete", Meta: questID,
				CreatedAt: time.Now().UTC().Format(time.RFC3339),
			})
		}
		return g, nil
	}
	return g, ErrNotFound
}

func (h *GuildHub) Donate(accountID string, soft int) (*Guild, error) {
	if soft <= 0 {
		return nil, ErrValidation
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	gid, ok := h.byAcc[accountID]
	if !ok {
		return nil, ErrNotFound
	}
	g := h.guilds[gid]
	if g.ContribXP == nil {
		g.ContribXP = map[string]int{}
	}
	g.VaultSoft += soft
	g.ContribXP[accountID] += soft / 10
	g.XP += soft / 50
	for g.XP >= g.Level*100 {
		g.XP -= g.Level * 100
		g.Level++
	}
	ensureDailyQuests(g)
	for i := range g.Quests {
		if g.Quests[i].ID == "gq_donate" && !g.Quests[i].Completed {
			g.Quests[i].Progress++
			if g.Quests[i].Progress >= g.Quests[i].Target {
				g.Quests[i].Completed = true
				g.XP += g.Quests[i].RewardXP
				g.VaultSoft += g.Quests[i].RewardSoft
			}
		}
	}
	g.Log = append(g.Log, GuildLogEntry{
		ActorID: accountID, Action: "donate", Meta: strconv.Itoa(soft),
		CreatedAt: time.Now().UTC().Format(time.RFC3339),
	})
	return g, nil
}
