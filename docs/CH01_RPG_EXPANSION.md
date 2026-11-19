# CH01 RPG Expansion — реализация

> Статус: **в работе** · Срез A (контент/схема) · SHA базы: `3717cfb` (`main`)  
> Авторское ТЗ: владелец · Числовые награды = **Draft test balance**, не shop/VIP/gacha.

## Цель

Превратить CH01 в RPG-акт с 5 побочными квестами (SQ01–SQ05), 10 POI, сюжетными вставками EX-01…EX-06 и реальными level/equip/skill эффектами — без ломки Q01–Q12 / B01–B30 / L01–L10.

## Неприкосновенные ограничения

- CH02 / L11 закрыты; H01 Stage E / GLB не трогаем.
- Основные диалоги Q01–Q12 не переписываем; вставки — отдельные ID.
- H02/H03 сюжетные встречи **не** выдают коллекционные карточки автоматически.
- Гача/магазин/VIP не переделываем; TEST_PURCHASE; платежи OFF.
- Нет production-деплоя / release keystore / rename.

## Срезы

| Срез | Содержание | Статус |
|---|---|---|
| A | Data: sidequests, POI, dialogues, rewards, equipment + validation | этот PR |
| B | Go API + PG migration + idempotent claims | следующий |
| C | Godot UI POI / журнал / sidequests | следующий |
| D | RPG tutorial + server skill/equip combat effects | следующий |
| E | E2E + debug APK + STATUS/ROAD | следующий |

## Контент (срез A)

| Файл | Содержимое |
|---|---|
| `client/data/quests/ch01_sidequests.json` | 5 SQ |
| `client/data/poi/ch01_poi.json` | 10 POI |
| `client/data/dialogues/ch01_expansion_dialogues.json` | SQ/EX/POI реплики |
| `client/data/rewards/ch01_expansion_rewards.json` | Draft награды |
| `client/data/equipment/ch01_equipment.json` | `eq_ch01_clerk_coat` + starters |
| `scripts/validate_ch01_expansion.py` | CI schema checks |

## Матрица прогрессии (сюжет → механика)

| Main | Локация | Новое |
|---|---|---|
| Q01 | L01 | EX-01 после B01; POI-01 |
| Q02 | L01 | SQ01 + POI-02 |
| Q03 | L02 | EX-02 после B07; POI-03 |
| Q04 | L03 | SQ02 + POI-04 |
| Q05 | L04 | SQ03 + POI-05; EX-03 после B13 |
| Q06 | L05 | POI-06 skill hint |
| Q07 | L05 | EX-04 перед B20 |
| Q08 | L06 | SQ04 + POI-07 |
| Q09 | L07 | POI-08 + EX-05 после B24 |
| Q10 | L08 | POI-09 timer |
| Q11 | L09 | SQ05 + POI-10 |
| Q12 | L10 | EX-06 после B30; CH02 teaser locked |

## Награды (Draft)

| Bundle | Soft | mat_hero_exp | Equipment |
|---|---|---|---|
| CH01-SQ01-FIRST_CLEAR | 300 | 100 | — |
| CH01-SQ02-FIRST_CLEAR | 150 | — | `eq_ch01_clerk_coat` |
| CH01-SQ03-FIRST_CLEAR | 250 | 150 | — |
| CH01-SQ04-FIRST_CLEAR | 400 | 200 | — |
| CH01-SQ05-FIRST_CLEAR | 500 | 250 | — |
| CH01-POI-09-FIRST | 50 | 20 | — |

## Аудит расхождений (срез A)

| Тема | Факт на `3717cfb` | Решение |
|---|---|---|
| Sidequests/POI | отсутствовали | добавлены data files |
| Equipment catalog | только hardcoded starters | `ch01_equipment.json` + clerk coat |
| ClaimReward API | soft+xp only | срез B расширит inventory/equipment |
| Skill-up HTTP | отсутствует | срез B/D |
| CampaignCatalog | только main 12 | расширен загрузчиками expansion |
| Smoke CH01 | asserts 12/30 | не меняем; отдельный smoke expansion |

## Валидация

```bash
python3 scripts/validate_ch01_expansion.py
```

## Что не сделано в срезе A

- Backend endpoints / миграции
- Godot POI UI
- Боевые эффекты skill level / armor DEF на сервере
- Debug APK / E2E полный прогон
