package content

import (
	"encoding/json"
	"os"
	"path/filepath"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

type SidequestDef struct {
	QuestID             string   `json:"quest_id"`
	Title               string   `json:"title"`
	LocationID          string   `json:"location_id"`
	RequiredQuest       string   `json:"required_quest"`
	StepIDs             []string `json:"step_ids"`
	StepSequence        []string `json:"step_sequence"`
	StepsAnyOrder       bool     `json:"steps_any_order"`
	RewardBundleID      string   `json:"reward_bundle_id"`
	StartDialogueID     string   `json:"start_dialogue_id"`
	CompleteDialogueID  string   `json:"complete_dialogue_id"`
	RequiredForFinalBoss bool    `json:"required_for_final_boss"`
	POIIDs              []string `json:"poi_ids"`
}

type POIDef struct {
	POIID            string           `json:"poi_id"`
	LocationID       string           `json:"location_id"`
	Title            string           `json:"title"`
	Description      string           `json:"description"`
	RequiredQuest    any              `json:"required_quest"`
	RequiredFlags    []string         `json:"required_flags"`
	SidequestID      string           `json:"sidequest_id"`
	InteractionType  string           `json:"interaction_type"`
	Actions          []map[string]any `json:"actions"`
	DialogueID       string           `json:"dialogue_id"`
	RewardBundleID   any              `json:"reward_bundle_id"`
	OneTime          bool             `json:"one_time"`
	CompletionFlag   string           `json:"completion_flag"`
	SortOrder        int              `json:"sort_order"`
}

func (l *Loader) loadExpansion() {
	// sidequests
	if b, err := os.ReadFile(filepath.Join(l.root, "quests", "ch01_sidequests.json")); err == nil {
		var pack struct {
			Sidequests []SidequestDef `json:"sidequests"`
		}
		if json.Unmarshal(b, &pack) == nil {
			l.sidequests = map[string]SidequestDef{}
			for _, sq := range pack.Sidequests {
				l.sidequests[sq.QuestID] = sq
			}
		}
	}
	// poi
	if b, err := os.ReadFile(filepath.Join(l.root, "poi", "ch01_poi.json")); err == nil {
		var pack struct {
			POI []POIDef `json:"poi"`
		}
		if json.Unmarshal(b, &pack) == nil {
			l.poi = map[string]POIDef{}
			for _, p := range pack.POI {
				l.poi[p.POIID] = p
			}
		}
	}
	// rewards
	if b, err := os.ReadFile(filepath.Join(l.root, "rewards", "ch01_expansion_rewards.json")); err == nil {
		var pack struct {
			Bundles []struct {
				BundleID        string         `json:"bundle_id"`
				SoftCurrency    int            `json:"soft_currency"`
				Inventory       map[string]int `json:"inventory"`
				Equipment       []string       `json:"equipment"`
				PremiumCurrency int            `json:"premium_currency"`
			} `json:"bundles"`
		}
		if json.Unmarshal(b, &pack) == nil {
			l.rewards = map[string]store.ExpansionRewardBundle{}
			for _, r := range pack.Bundles {
				inv := r.Inventory
				if inv == nil {
					inv = map[string]int{}
				}
				l.rewards[r.BundleID] = store.ExpansionRewardBundle{
					BundleID: r.BundleID, Soft: r.SoftCurrency, Inventory: inv,
					Equipment: r.Equipment, PremiumCurrency: r.PremiumCurrency,
				}
			}
		}
	}
	// equipment
	if b, err := os.ReadFile(filepath.Join(l.root, "equipment", "ch01_equipment.json")); err == nil {
		var pack struct {
			Items []struct {
				ItemID        string         `json:"item_id"`
				Slot          string         `json:"slot"`
				Bonuses       map[string]int `json:"bonuses"`
				AccountUnique bool           `json:"account_unique"`
			} `json:"items"`
		}
		if json.Unmarshal(b, &pack) == nil {
			l.equipment = map[string]store.EquipmentDef{}
			for _, e := range pack.Items {
				bon := e.Bonuses
				if bon == nil {
					bon = map[string]int{}
				}
				l.equipment[e.ItemID] = store.EquipmentDef{
					ItemID: e.ItemID, Slot: e.Slot, Bonuses: bon, AccountUnique: e.AccountUnique,
				}
			}
		}
	}
	// packed expansion dialogues
	if b, err := os.ReadFile(filepath.Join(l.root, "dialogues", "ch01_expansion_dialogues.json")); err == nil {
		var pack struct {
			Dialogues []map[string]any `json:"dialogues"`
		}
		if json.Unmarshal(b, &pack) == nil {
			for _, d := range pack.Dialogues {
				if id, _ := d["dialogue_id"].(string); id != "" {
					l.dialogue[id] = d
				}
				if qid, _ := d["quest_id"].(string); qid != "" {
					l.dialogue[qid] = d
				}
			}
		}
	}
}

func (l *Loader) Sidequests() map[string]SidequestDef {
	l.mu.RLock()
	defer l.mu.RUnlock()
	out := map[string]SidequestDef{}
	for k, v := range l.sidequests {
		out[k] = v
	}
	return out
}

func (l *Loader) Sidequest(id string) (SidequestDef, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	v, ok := l.sidequests[id]
	return v, ok
}

func (l *Loader) POI() map[string]POIDef {
	l.mu.RLock()
	defer l.mu.RUnlock()
	out := map[string]POIDef{}
	for k, v := range l.poi {
		out[k] = v
	}
	return out
}

func (l *Loader) GetPOI(id string) (POIDef, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	v, ok := l.poi[id]
	return v, ok
}

func (l *Loader) RewardBundle(id string) (store.ExpansionRewardBundle, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	v, ok := l.rewards[id]
	return v, ok
}

func (l *Loader) EquipmentDefs() map[string]store.EquipmentDef {
	l.mu.RLock()
	defer l.mu.RUnlock()
	out := map[string]store.EquipmentDef{}
	for k, v := range l.equipment {
		out[k] = v
	}
	return out
}
