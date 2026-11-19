# PHASE0_SPEC.md — Контракты API и данных (T-020)

> Версия: 1.0 · 2026-11-19 · Статус: **спецификация согласована как черновик Phase 0**  
> Порядок: client-first (ROAD-002 A). Клиентские моки помечать `X-Mock: true`.  
> Сервер (Go + PostgreSQL + Redis) — источник истины **после** интеграции; до этого `GameState` локален.

## 0. Цели Phase 0

1. Зафиксировать модели данных и HTTP/WS контракты до расширения экранов.
2. Сопоставить текущий клиент V0-C с будущими endpoint’ами.
3. Критерии приёмки для замены моков.

## 1. Аудит репозитория (факт)

| Путь | Роль | Auth source? |
|---|---|---|
| `client/` | Godot 4.3 V0-C stub | Нет (local save) |
| `client/data/*.json` | Контент/баланс-моки | Контент |
| `docs/` | GDD/ROAD/VIS/API | Документы |
| `server/` | Go Phase2 stub API | In-memory/file (PG/Redis → T-085) |
| `.github/workflows/` | CI (T-021) | Проверки |

## 2. Идентификаторы (стабильные)

| Сущность | ID примеры | Правило |
|---|---|---|
| Account | `acc_…` UUID | Сервер выдаёт |
| Hero def | `H01`… | Из HEROES.md |
| Enemy def | `E01`… | Из CAMPAIGN |
| Quest | `CH01-Q01` | Кампания |
| Battle | `B01` | Кампания |
| Reward bundle | `CH01-Q01-B01-FIRST_CLEAR` | Уникален, идемпотентен |
| Dialogue | `CH01-Q01` | JSON lines |

## 3. Модели данных (JSON Schema-уровень)

### 3.1 AccountProgress

```json
{
  "account_id": "acc_…",
  "commander_xp": 0,
  "soft_currency": 0,
  "party_ids": ["H01", "H02", "H03"],
  "quest_flags": {"CH01-Q01": true},
  "claimed_rewards": {"CH01-Q01-B01-FIRST_CLEAR": true},
  "updated_at": "ISO-8601"
}
```

### 3.2 HeroInstance (будущее; V0 использует только defs)

```json
{
  "hero_id": "H01",
  "level": 1,
  "stars": 0,
  "rank": 0
}
```

### 3.3 BattleStartRequest / BattleResult

```json
{
  "battle_id": "B01",
  "party_ids": ["H01", "H02", "H03"],
  "client_seed": 123456,
  "client_version": "0.0.1-v0c"
}
```

```json
{
  "battle_id": "B01",
  "victory": true,
  "duration_ms": 12000,
  "actions_hash": "sha256…",
  "rewards_claimed": false
}
```

Сервер **пересчитывает** бой или валидирует replay; клиентский `victory` после интеграции не доверяется.

### 3.4 RewardClaim

```json
{
  "bundle_id": "CH01-Q01-B01-FIRST_CLEAR",
  "battle_id": "B01",
  "idempotency_key": "acc_…:CH01-Q01-B01-FIRST_CLEAR"
}
```

Ответ: `{ "ok": true, "soft_delta": 500, "xp_delta": 50, "already_claimed": false }`

## 4. HTTP API (черновик)

Base: `https://api.example.local/v1` (TBD)  
Auth: `Authorization: Bearer <token>` (после auth-модуля)

| Method | Path | Назначение | Mock сейчас |
|---|---|---|---|
| POST | `/auth/anonymous` | Создать/получить guest | Нет — local only |
| GET | `/me/progress` | AccountProgress | `GameState` |
| PUT | `/me/party` | Сохранить party_ids | local |
| GET | `/content/heroes` | roster defs | `roster_v0.json` |
| GET | `/content/battles/{id}` | battle def | `B01.json` |
| GET | `/content/dialogues/{id}` | dialogue | `ch01_q01.json` |
| POST | `/battles/{id}/start` | Старт, seed | client local |
| POST | `/battles/{id}/finish` | Результат | client local |
| POST | `/rewards/claim` | Идемпотентная выдача | `claim_reward` |

Заголовки мока клиента (пока без сети): логировать `source=local_mock`.

## 5. Соответствие текущему клиенту

| Клиент | Будущий контракт |
|---|---|
| `GameState.load/save` | GET/PUT progress |
| `claim_reward` | POST `/rewards/claim` |
| `BattleEngine` | finish payload + server verify |
| `roster_v0.json` | GET `/content/heroes` |
| `B01.json` | GET `/content/battles/B01` |

## 6. Ошибки

| Code | HTTP | Когда |
|---|---|---|
| `UNAUTHENTICATED` | 401 | нет/протух токен |
| `ALREADY_CLAIMED` | 409 | повтор награды |
| `INVALID_PARTY` | 400 | нет героя / дубликат |
| `BATTLE_NOT_FOUND` | 404 | неизвестный battle_id |
| `VALIDATION_FAILED` | 422 | неверный результат боя |

## 7. Безопасность (минимум)

- Не доверять клиенту soft/xp/victory после подключения сервера.
- Idempotency key на награды: `(account_id, bundle_id)`.
- Rate limit на `/battles/*/finish` и `/rewards/claim`.
- Контент JSON можно CDN/кэшировать; прогресс — только API.

## 8. Критерии приёмки Phase 0 spec

- [x] Документ PHASE0_SPEC существует и ссылается на V0 client.
- [x] ID совпадают с CAMPAIGN/HEROES/V0 data files.
- [ ] OpenAPI/Swagger файл — опционально следующим шагом.
- [ ] Go stubs — Фаза 2 ROAD, не Phase 0 docs.

## 9. Следующий инженерный шаг после спеки

1. ~~CI на JSON + Godot smoke (T-021).~~  
2. ~~Тонкий `ApiClient` в Godot с переключателем `USE_MOCK=true`.~~ → `client/scripts/net/api_client.gd`  
3. Не строить полный сервер, пока клиент MVP-экраны не стабилизированы (ROAD-002 A).  
4. При `use_mock=false` клиент ходит в локальный Go API (`scripts/run_api.sh` / `smoke_live_api.sh`).
