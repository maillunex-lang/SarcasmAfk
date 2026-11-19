# V0_REVIEW.md — Review и стоп-линия (T-050)

> Дата: 2026-11-19 · Статус: **агентский review-пакет готов; финальное OK владельца — отдельным сообщением**  
> Срез: Splash / Home / L01 / Dialog CH01-Q01 / ARENA-L01 autofight B01  
> Это **не** приёмка полного MVP.

## 1. Definition of Done (V0)

| Критерий | Результат | Доказательство |
|---|---|---|
| Splash и Home показывают «БашЛегенды: Эпоха Абсурда» | PASS | `splash.gd` / `home.gd` + branding assets |
| L01 и ARENA-L01 в едином стиле, 9:16 | PASS (draft) | `client/assets/locations/L01/*`, arena floor |
| H01–H03 + E01: concept/portrait; atlas bake | PARTIAL | portraits/full есть; **Blender atlas = BLOCKED (T-031)** — still sprites как placeholder |
| Диалог CH01-Q01, static portraits, skip/next | PASS | `dialog_screen.gd` + `ch01_q01.json` |
| Blender→atlas пилот на H01 | FAIL / BLOCKED | нет Blender в CI/dev image |
| Пресеты Low/Med/High | PARTIAL | описаны в ASSET_PIPELINE; runtime toggle не реализован |
| ROAD/STATUS обновлены фактом | PASS | журналы 2026-11-19 |
| Нет заявления «MVP готов» | PASS | STATUS / README явно stub |

**Вердикт DoD:** V0 **условно принят как playable stub** с открытым T-031 и без финального арт-approve.

## 2. Что работает (проверено smoke)

```bash
godot4 --headless --path client -s res://scripts/tools/smoke_v0a.gd  # EXIT 0
godot4 --headless --path client -s res://scripts/tools/smoke_v0c.gd  # EXIT 0
```

- Навигация Splash→Home→L01→Dialog→Battle→Home  
- ATB autofight, ULT, speed ×1/×2  
- First-clear reward idempotent  
- Local save `user://bashlegends_v0_save.json`

## 3. Дефекты / долг только по V0

| ID | Severity | Описание | Рекомендация |
|---|---|---|---|
| V0-D01 | High | Нет прозрачных combat-атласов | T-031 при появлении Blender |
| V0-D02 | Med | JPG draft с фоном вместо alpha props | Paintover / cutout |
| V0-D03 | Med | Баланс B01 черновой (быстрый бой) | Отдельный balance pass |
| V0-D04 | Med | Кнопки UI — texture plates не 9-slice | Нарезать 9-slice или оставить code StyleBox |
| V0-D05 | Low | AFK кнопка disabled | После AFK спеки |
| V0-D06 | Low | Нет runtime Low/Med/High | VIS preset hook |
| V0-D07 | Low | H03 full чуть моложе портрета | Перегенерация full при review арта |

## 4. Стоп-линия (решение)

**Разрешено дальше:**
1. Phase 0 API/контракты (**T-020**) и минимальный CI (**T-021**) — сделано следом в этом цикле.
2. Расширение **только CH01** боёв/квестов на моках после API-контрактов.
3. Арт-правки строго внутри V0 ID (H01–H03, L01, E01, UI chrome).

**Запрещено стоп-линией:**
- Главы 02–12 (T-090)
- Массовая генерация ассетов вне очереди (T-091)
- Rename repo/package (T-092)
- Объявление MVP / «игра готова»

**Рекомендация владельцу:** подтвердить draft-арт OK/правки списком; приоритет после этого цикла — CH01 B02–B04 **или** серверные моки по PHASE0_SPEC.

## 5. Подпись агента

- Review выполнен по коду, ассетам и smoke.  
- Финальный визуальный sign-off — за владельцем.  
- Статус задачи T-050: пакет review готов; стоп-линия зафиксирована.
