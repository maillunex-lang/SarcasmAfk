package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"
)

type Loader struct {
	mu       sync.RWMutex
	root     string
	heroes   map[string]any
	battles  map[string]any
	dialogue map[string]any
	heroIDs  []string
}

func New(root string) *Loader {
	l := &Loader{
		root:     root,
		heroes:   map[string]any{},
		battles:  map[string]any{},
		dialogue: map[string]any{},
	}
	l.reload()
	return l
}

func (l *Loader) reload() {
	l.mu.Lock()
	defer l.mu.Unlock()
	// heroes
	for _, name := range []string{"roster_mvp.json", "roster_v0.json"} {
		path := filepath.Join(l.root, "heroes", name)
		var data struct {
			Heroes []map[string]any `json:"heroes"`
		}
		if b, err := os.ReadFile(path); err == nil && json.Unmarshal(b, &data) == nil {
			ids := []string{}
			for _, h := range data.Heroes {
				id, _ := h["id"].(string)
				if id != "" {
					l.heroes[id] = h
					ids = append(ids, id)
				}
			}
			l.heroIDs = ids
			break
		}
	}
	// battles pack
	if b, err := os.ReadFile(filepath.Join(l.root, "battles", "ch01_battles.json")); err == nil {
		var pack struct {
			Battles []map[string]any `json:"battles"`
		}
		if json.Unmarshal(b, &pack) == nil {
			for _, battle := range pack.Battles {
				id, _ := battle["battle_id"].(string)
				if id != "" {
					l.battles[id] = battle
				}
			}
		}
	}
	if b, err := os.ReadFile(filepath.Join(l.root, "battles", "B01.json")); err == nil {
		var battle map[string]any
		if json.Unmarshal(b, &battle) == nil {
			if id, _ := battle["battle_id"].(string); id != "" {
				l.battles[id] = battle
			}
		}
	}
	// dialogues
	matches, _ := filepath.Glob(filepath.Join(l.root, "dialogues", "*.json"))
	for _, p := range matches {
		var d map[string]any
		b, err := os.ReadFile(p)
		if err != nil || json.Unmarshal(b, &d) != nil {
			continue
		}
		if qid, _ := d["quest_id"].(string); qid != "" {
			l.dialogue[qid] = d
		}
		base := filepath.Base(p)
		l.dialogue[base[:len(base)-5]] = d
	}
}

func (l *Loader) Heroes() []any {
	l.mu.RLock()
	defer l.mu.RUnlock()
	out := make([]any, 0, len(l.heroIDs))
	for _, id := range l.heroIDs {
		out = append(out, l.heroes[id])
	}
	return out
}

func (l *Loader) HeroIDs() []string {
	l.mu.RLock()
	defer l.mu.RUnlock()
	return append([]string{}, l.heroIDs...)
}

func (l *Loader) Battle(id string) (any, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	b, ok := l.battles[id]
	return b, ok
}

func (l *Loader) Dialogue(id string) (any, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	d, ok := l.dialogue[id]
	return d, ok
}
