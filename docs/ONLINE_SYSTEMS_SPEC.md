# ONLINE SYSTEMS SPEC — API contracts & Draft knobs

Version: 0.1 (P1 foundation)  
Status: Implementation contracts for P1–P7. Monetization rates/prices remain Draft until owner approval.

## 1. Heroes & progression

### GET `/v1/heroes/catalog`
Returns release roster (36). Fields: id, name, class, rarity, faction, base stats, `status` (`approved_mvp`|`draft`), `lunex_visual_id`, art_status.

### GET `/v1/heroes/owned`
Auth. Returns player hero instances: catalog_id, level, stars, awaken_rank, skill_levels, equipment slots, power, fragments.

### POST `/v1/heroes/{id}/level-up`
Body: `{ "levels": 1 }`  
Server spends soft currency + EXP materials per `progression_draft.json`. Rejects if insufficient or over cap.

### POST `/v1/heroes/{id}/star-up`
Spends fragments/duplicates. Updates stars and recalculates power.

### POST `/v1/heroes/{id}/awaken`
Spends awaken materials; raises awaken_rank and level cap.

### POST `/v1/heroes/{id}/equip`
Body: `{ "slot": "weapon"|"armor"|"accessory"|"relic", "item_id": "..." }`  
Server validates ownership and class compatibility.

### Power formula (Draft)
```
power = floor(
  (hp * 0.15 + atk * 1.2 + defense * 0.9 + speed * 0.5)
  * (1 + 0.08 * (stars))
  * (1 + 0.05 * awaken_rank)
  * (1 + 0.02 * (level - 1))
)
```
Coefficients are Draft — pending balance approval.

## 2. Economy

Currencies: `soft` (gold), `hard` (diamonds), `tickets`, `vip_points`, `guild_coins`.  
All mutations via server transactions + audit log. No negative balances.

## 3. Chat (P3)

Channels: `global`, `system`, `dm:{pair}`, `guild:{id}`.  
WS `/v1/ws/chat` with session token. History GET `/v1/chat/{channel}/history?before=&limit=`.  
Rate limit Draft: 1 msg / 2s global; duplicate text block 30s. Reports, mute, ignore, mod actions.

## 4. Guilds (P4)

Create cost Draft: 500 soft. Tag 3–5 chars unique. Roles: leader, officer, member (+ custom permissions JSON).  
Atomic membership changes. Guild chat channel. Quests/bosses/wars: schema hooks only until rules approved.

## 5. Gacha (P5)

Banners from config. Server crypto/rand. Pity Draft: soft 10 / hard 70 for SSR+ (needs approval).  
Paid banners OFF until rates + monetization approved. Free/ticket summons OK in Draft.

## 6. Shop (P6)

Categories: diamonds, resource packs, growth, daily/weekly/monthly, cosmetic, events, VIP.  
Real money: test mode only until provider wired. In-game soft purchases: free simulation for now (explicit `purchase_mode: simulated`).

## 7. VIP (P7)

Levels driven by `vip_points`. Bonuses Draft in `vip_draft.json`. No unbounded PvP advantage.

## 8. Lunex Visual Studio

IDs: `lunex://heroes/{id}`, `lunex://guild/emblem/{id}`, `lunex://gacha/{banner}`, `lunex://shop/{sku}`, `lunex://vip/{level}`.  
Adapters store refs; no hard dependency on unfinished VS UI.
