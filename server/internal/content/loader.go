package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

type Loader struct {
	mu         sync.RWMutex
	root       string
	heroes     map[string]any
	battles    map[string]any
	dialogue   map[string]any
	heroIDs    []string
	sidequests map[string]SidequestDef
	poi        map[string]POIDef
	rewards    map[string]store.ExpansionRewardBundle
	equipment  map[string]store.EquipmentDef
	// EQUIPMENT-001
	eqTemplates         map[string]store.EquipmentTemplate
	eqSets              map[string]store.EquipmentSetDef
	eqBalance           store.EquipmentBalance
	eqBalanceVersion    string
	eqAliases           map[string]string
	eqCH01Rewards       map[string]string
	eqRandomDropEnabled bool
}

func New(root string) *Loader {
	l := &Loader{
		root:       root,
		heroes:     map[string]any{},
		battles:    map[string]any{},
		dialogue:   map[string]any{},
		sidequests:   map[string]SidequestDef{},
		poi:          map[string]POIDef{},
		rewards:      map[string]store.ExpansionRewardBundle{},
		equipment:    map[string]store.EquipmentDef{},
		eqTemplates:  map[string]store.EquipmentTemplate{},
		eqSets:       map[string]store.EquipmentSetDef{},
		eqAliases:    map[string]string{},
		eqCH01Rewards: map[string]string{},
	}
	l.reload()
	return l
}

func (l *Loader) reload() {
	l.mu.Lock()
	defer l.mu.Unlock()
	// heroes
	for _, name := range []string{"roster_release36.json", "roster_mvp.json", "roster_v0.json"} {
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
	// dialogues (single-file packs; expansion packed file handled in loadExpansion)
	matches, _ := filepath.Glob(filepath.Join(l.root, "dialogues", "*.json"))
	for _, p := range matches {
		base := filepath.Base(p)
		if base == "ch01_expansion_dialogues.json" {
			continue
		}
		var d map[string]any
		b, err := os.ReadFile(p)
		if err != nil || json.Unmarshal(b, &d) != nil {
			continue
		}
		if qid, _ := d["quest_id"].(string); qid != "" {
			l.dialogue[qid] = d
		}
		l.dialogue[base[:len(base)-5]] = d
	}
	l.loadExpansion()
	l.loadEquipmentCatalog()
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

func (l *Loader) HeroMap() map[string]any {
	l.mu.RLock()
	defer l.mu.RUnlock()
	out := make(map[string]any, len(l.heroes))
	for k, v := range l.heroes {
		out[k] = v
	}
	return out
}

func (l *Loader) Battle(id string) (map[string]any, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	b, ok := l.battles[id]
	if !ok {
		return nil, false
	}
	if m, ok := b.(map[string]any); ok {
		return m, true
	}
	return nil, false
}

func (l *Loader) Dialogue(id string) (any, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	d, ok := l.dialogue[id]
	return d, ok
}
