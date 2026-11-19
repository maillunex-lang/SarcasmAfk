package content

import (
	"encoding/json"
	"os"
	"path/filepath"
)

type EnemyCatalogEntry struct {
	ID        string         `json:"id"`
	Name      string         `json:"name"`
	Archetype string         `json:"archetype"`
	Basic     map[string]any `json:"basic"`
	Special   map[string]any `json:"special"`
	Lore      string         `json:"lore"`
	Quote     string         `json:"quote"`
	Art       map[string]any `json:"art"`
}

func (l *Loader) loadEnemyCatalog() {
	l.enemyCatalog = map[string]EnemyCatalogEntry{}
	path := filepath.Join(l.root, "enemies", "enemy_catalog_ch01.json")
	b, err := os.ReadFile(path)
	if err != nil {
		return
	}
	var pack struct {
		Enemies []EnemyCatalogEntry `json:"enemies"`
	}
	if json.Unmarshal(b, &pack) != nil {
		return
	}
	for _, e := range pack.Enemies {
		l.enemyCatalog[e.ID] = e
	}
}

func (l *Loader) EnemyCatalog() map[string]EnemyCatalogEntry {
	l.mu.RLock()
	defer l.mu.RUnlock()
	out := map[string]EnemyCatalogEntry{}
	for k, v := range l.enemyCatalog {
		out[k] = v
	}
	return out
}

func (l *Loader) Enemy(id string) (EnemyCatalogEntry, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	v, ok := l.enemyCatalog[id]
	return v, ok
}

// EnrichEnemyUnit attaches catalog skills onto a battle enemy row without changing HP/ATK/DEF/SPD.
func (l *Loader) EnrichEnemyUnit(m map[string]any) map[string]any {
	out := map[string]any{}
	for k, v := range m {
		out[k] = v
	}
	etype, _ := m["enemy_type"].(string)
	if etype == "" {
		etype, _ = m["id"].(string)
	}
	// Strip instance suffix like E01_a
	base := etype
	if len(base) > 3 && base[0] == 'E' {
		i := 1
		for i < len(base) && ((base[i] >= '0' && base[i] <= '9') || base[i] == 'A') {
			i++
		}
		if i > 1 {
			base = base[:i]
		}
	}
	l.mu.RLock()
	ent, ok := l.enemyCatalog[base]
	l.mu.RUnlock()
	if !ok {
		// try exact
		l.mu.RLock()
		ent, ok = l.enemyCatalog[etype]
		l.mu.RUnlock()
	}
	if !ok {
		return out
	}
	out["archetype"] = ent.Archetype
	if ent.Basic != nil {
		out["basic"] = ent.Basic
	}
	if ent.Special != nil {
		out["special"] = ent.Special
	}
	if ent.Name != "" && asStringAny(out["name"]) == "" {
		out["name"] = ent.Name
	}
	return out
}

func asStringAny(v any) string {
	s, _ := v.(string)
	return s
}
