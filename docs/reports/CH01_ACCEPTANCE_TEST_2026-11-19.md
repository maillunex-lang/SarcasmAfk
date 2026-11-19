# CH01 Acceptance Test Report — 2026-11-19

> Владелец: **CH01 пока НЕ accepted** (Q3). Это отчёт прогона, не приёмка.  
> Ветка: `cursor/ch01-game-polish-beaf` · Debug APK: `build/BashLegends-debug.apk` (~131MB)

## 1. Owner decisions (зафиксировано)

| ID | Решение |
|---|---|
| Q3 / T-128 | **Не принято.** Нужен отчёт цикла + дефекты. |
| Q2 / T-127 | Арт H01–H03/E01 = **черновики**. H01 = готовый Meshy GLB владельца; новую модель не генерировать. |
| T-131 | Хват меча — **владелец в Blender**. Stage E / финальные 2D-атласы **запрещены** до подтверждения. |
| Q1 / T-126 | Пока **только debug APK**. Release keystore не создавать/не перезаписывать. |
| Q4 / T-129 | Использовать **существующий** API-конфиг; не выдумывать URL; не уходить в offline-only без согласования. |
| Scope | Разрешена разработка систем **не зависящих** от финальных ассетов. |

## 2. Cycle under test

`Home → карта Уфы → L01 → диалоги → отряд → бой (+ручной ULT) → победа → награда → сейв → следующий этап`

### Results

| Проверка | Режим | Результат |
|---|---|---|
| `smoke_ch01_vertical.gd` | mock | **PASS** — ULT naturally ready @tick≈48, victory, reward +220, idempotent, save→B02, Home continue CTA |
| `smoke_ch01.gd` | mock | **PASS** — 12 квестов / 30 боёв / диалоги Q01–Q12 / Q01 clear |
| `smoke_mvp.gd` | mock | **PASS** — 12 экранов instantiate, party/AFK/gacha |
| `smoke_live_api.sh` | live :8080 | **PASS** — auth, content, start/finish, NO_ACTIVE_BATTLE, claim idempotent |
| `integration_live_slice.sh` | live | **PASS** — command + finish pair + progress + resume |
| `smoke_session_resume.sh` | live | **PASS** — token resume after restart |
| `check_release_keystore.sh` | — | **exit 2** — release keystore unavailable (ожидаемо) |
| `build_debug_apk.sh` | — | **PASS** → `build/BashLegends-debug.apk` |

## 3. Keystore / Live URL audit

### Keystore (safe probe)
- `ANDROID_RELEASE_KEYSTORE`: **unset**
- Common paths (`~/.android/release.keystore`, `/opt/android/…`, `/workspace/secrets/…`): **not found**
- GH Actions secrets: **not readable** with agent credentials (403)
- Action: continue **debug APK only**; nothing created/overwritten

### Live API
| Source | Value |
|---|---|
| `client/data/net/client_config.json` | `http://127.0.0.1:8080/v1` |
| `GameState.live_api_url` default | same |
| Local smokes | API on `:8080` / `:8091` works |
| Phone / production URL | **не задан** в репо/env агента |

**Вывод Q4:** рабочий локальный API есть и используется в CI/smoke. Для телефонов отдельный URL владельцем ещё не предоставлен — **не** переключали offline-only и **не** придумывали новый адрес. Debug на устройстве остаётся mock до явного URL или More→Live при доступном сервере.

## 4. Defects / gaps found

| Sev | ID | Описание | Статус |
|---|---|---|---|
| **P1** | DEF-01 | Live `/battles/{id}/finish` всегда слал `AutoCast: true`, даже после ручных `/command` ultimate → сервер мог автокастовать поверх ожидания игрока | **FIXED** в этом прогоне (`auto_cast=false` если есть ultimate commands) + тест |
| **P2** | DEF-02 | Party screen — только текст, без портретов; live `put_party` не вызывался при смене слота | **FIXED** (портреты + `put_party` в live) |
| **P2** | DEF-03 | `client_config.json` указывает только `127.0.0.1` — на телефоне Live без LAN/VPS URL недоступен | **OPEN** — ждёт Q4 URL от владельца |
| **P2** | DEF-04 | Баланс pass-1 применён к **B01**; B02+ в `ch01_battles.json` всё ещё HP 380 → ULT на следующих боях снова может не успеть | **OPEN** — можно крутить независимо от арта |
| **P3** | DEF-05 | H01–H03/E01 combat = drafts; H01 3D grip не в ладони до правки владельца; Stage E blocked | **OWNER** (T-131) |
| **P3** | DEF-06 | Guild/Arena/Events UI «НЕДОСТУПНО» (by design until T-128) | **EXPECTED** |
| **Info** | DEF-07 | STATUS ранее писал про force-energy в smoke — устарело после T-130 (natural ULT) | docs refresh |

## 5. CH01 acceptance verdict

**Не принимаем.** Автотесты вертикали зелёные, debug APK собран, но:
1. нет явного accept владельца;
2. live URL для устройств не зафиксирован;
3. арт/атласы H01 не финальны;
4. DEF-03/04 остаются.

Повторная приёмка: после правок владельца по grip (опц.) + прогон debug APK на устройстве + ответы Q3.

## 6. Что можно продолжать **независимо от Каэрона**

| Можно | Нельзя без владельца |
|---|---|
| Баланс B02+ / ATB pass-2 | Stage E 2D atlases H01 |
| Party/Heroes/Inventory UX | Новая модель H01 |
| Live API hardening, replay, admin | Release signed APK (keystore) |
| AFK/expedition/gacha polish (mock+live) | Guild/arena/events **live** (нужен T-128) |
| Save/resume, More live toggle UX | CH02+ / mass art / rename (PX) |
| Docs / CI / debug APK | Считать CH01 accepted |

## 7. Evidence paths

- Smokes: `/tmp/ch01_cycle_mock.log`, `/tmp/ch01_cycle_live.log`
- APK: `build/BashLegends-debug.apk`
- Keystore probe: `scripts/check_release_keystore.sh` → exit 2
- Config: `client/data/net/client_config.json`
