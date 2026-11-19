# ASSET_PIPELINE.md — Создание и оптимизация ассетов

> Версия: 1.1 · 2026-11-19 · Статус: **пайплайн V0 утверждён; массовая генерация не начата**
> Стек: Godot 4 · Android · VIS-001 C → Blender bake-атласы · пресеты Low/Med/High · ≥6 ГБ ОЗУ
> Документация ≠ готовый прототип.

## 0. Принципы

1. Сначала спецификация и утверждение V0, потом массовая генерация.
2. Текстовый промпт / описание ≠ готовый ассет.
3. Каждый импортируемый файл имеет стабильный ID и путь.
4. Бюджет памяти и overdraw важнее «ещё одного слоя glow».
5. Клиент-first (ROAD-002 A): ассеты живут в клиенте; сервер не хранит бинарники арта как источник истины геймплея.

## 1. Папки репозитория (целевая структура)

Пока код клиента не создан — структура **проектная**:

```
/assets
  /art
    /heroes/{Hxx}/
    /enemies/{Exx}/
    /locations/{Lxx}/
    /arenas/{ARENA-Lxx}/
    /map/
    /ui/
    /vfx/
    /moodboards/
  /source   # PSD/CLIP/Blender — опционально LFS, не в APK
/docs
  ART_DIRECTION.md
  DESIGN_SYSTEM.md
  ...
```

Godot-проект (будущий): `res://assets/...` с импорт-пресетами.

## 2. Форматы

| Тип | Рабочий формат | Runtime | Примечание |
|---|---|---|---|
| Концепт/мудборд | PNG/WebP | не в APK | Только референс |
| Фон локации слой | PNG 2048×2048 или 1080×1920 | WebP/PNG compressed | Резать на слои |
| UI 9-slice | PNG | import Godot | Safe margins |
| Портрет | PNG 1024² → 512² | WebP | Мип-карты |
| Боевой атлас | PNG atlas / `.tres` SpriteFrames | сжатие | Max atlas 2048² Low |
| Диалоговый портрет | PNG 512–1024 bust, static | WebP | Без анимации лица |
| Blender source | `.blend` (+ экспорты) | не в APK | Source / LFS |
| Bake из 3D | Blender anim → transparent PNG sequence → atlas | Godot SpriteFrames | **Канон V0 для героев/врагов** |
| VFX | spritesheet + `.tscn` particles | — | Отключаемые ноды |
| Шрифты | OFL/лицензированные TTF | dynamic / MSDF | Проверить лицензию |

## 3. Пайплайн героя / врага (end-to-end, утверждено V0)

```
HEROES.md / enemy card
  → промпт/бриф (CHARACTER_STYLE_GUIDE)
  → концепт full body (утверждение силуэта)
  → портрет UI + статичный диалоговый bust
  → Blender: моделирование (stylized, low-mid poly)
  → Blender: анимации idle/attack/ult/hit/win/defeat
  → Render: прозрачные кадры (ortho/fixed cam, no BG)
  → Pack: 2D atlas (кратность 4, бюджет по пресету)
  → Godot 4: SpriteFrames / AnimatedSprite2D + VFX sockets
  → LOD/VFX preset hooks (Low/Med/High)
  → тест на ARENA-L01 в 9:16
  → чеклист приёмки
```

**Запрет runtime:** полноценный 3D viewport персонажа на Android в V0.  
Статусы файла: `spec` → `draft` → `review` → `approved` → `imported` → `verified`.

## 4. Пайплайн локации

```
CAMPAIGN карточка Lxx
  → mood + цвет региона
  → paintover слоёв sky/far/mid/props/near
  → интерактивные props отдельно
  → вычитание арены (battle floor + BG)
  → состояния quest/crisis/cleared
  → сжатие и пресеты
  → тест параллакса и памяти
```

## 5. Оптимизация Android

| Правило | Low | Medium | High |
|---|---|---|---|
| Max texture фон | 1024 | 1536 | 2048 |
| Параллакс слои | 3 | 5 | 6 |
| Particles | off | limited | full |
| Skeleton mesh deform | simplified | full | full + cloth soft |
| Post FX | off | soft vignette | vignette + mild bloom |
| Целевой FPS боя | 30 | 30–45 | 45–60 |

Общее: избегать full-screen overdraw; атласы вместо сотен мелких TextureRect; пул VFX; отложенная загрузка неактивных городов.

Минимум устройства: **6 ГБ ОЗУ** — не значит «можно грузить всё»; держать residency CH01 локаций в бюджете (ориентир: ≤ 250–350 МБ текстур активной сцены на Low — уточнить профилированием).

## 6. Именование файлов

```
{domain}_{id}_{variant}_{state}_{res}.{ext}

heroes_H01_kaeron_full_concept_v1.png
heroes_H01_portrait_512.png
loc_L01_mid_day.png
arena_L01_floor.png
ui_btn_primary_9slice.png
vfx_H01_ult_sheet.png
enemy_E01_idle_atlas.png
```

Запрет пробелов и кириллицы в именах файлов runtime.

## 7. Генерация изображений — рабочий процесс

1. Взять промпт из гайда.
2. Сгенерировать 2–4 варианта.
3. Отобрать по силуэту/палитре/9:16.
4. Paintover руками (чистка артефактов, единый контур).
5. Нарезать слои / атласы.
6. Пометить статус; **не** коммитить как `approved` без ревью владельца.

Промпты-библиотека уже в ART/DESIGN/LOCATION/CHARACTER; общие негативы:

```
Negative (всегда): photorealistic, raw photo, dirty grunge texture, logo trademarks,
illegible small ornaments, horror gore, real government emblem, watermark, text gibberish UI
```

## 8. Контроль качества (чек до import)

- [ ] Палитра в допуске navy/gold/cyan/ivory/coral + классовые акценты.
- [ ] Силуэт читается в 128 px.
- [ ] Нет чужих логотипов и фото-вставок.
- [ ] Альфа чистая; нет белой подложки.
- [ ] Размер кратен 4 для сжатия.
- [ ] Документ-источник обновлён (ID ассета в списке).

## 9. Промпты утилитарные

### P-PIPE-01 — Atlas packing preview

```
Sprite atlas layout preview sheet for mobile RPG, labeled frames idle attack ultimate,
clean transparent background, stylized anime fantasy warrior, technical presentation --ar 16:9
```

### P-PIPE-02 — Texture budget board

```
Game art technical comparison board low medium high quality presets,
same fantasy plaza scene with reduced layers and particles on low,
clean premium stylized look, annotation-friendly --ar 16:9
```

## 10. Список ассетов пайплайна / инфраструктуры

| ID | Ассет / артефакт |
|---|---|
| PIPE-FOLDER | Создание `/assets` после утверждения V0 |
| PIPE-IMPORT | Godot import presets (texture, compression) |
| PIPE-LOD | Скрипт/настройки переключения Low/Med/High |
| PIPE-CHECKLIST | QA-форма ассета (шаблон) |
| PIPE-LFS | Решение по Git LFS для source |

## 11. Связь с фазами ROAD

| Фаза | Работа с ассетами |
|---|---|
| Сейчас | Документы + утверждённые решения V0 + план реализации; **без** массовой генерации |
| После плана V0 | Точечная подготовка только ассетов среза (не главы 02–12) |
| Фаза 1 ROAD | Полный клиентский арт MVP по VISUAL_ROADMAP |
| Фаза 2+ | Оптимизация по профилированию, сезонные скины |

## 12. Приёмка пайплайна

- [ ] Пути и ID стабильны.
- [ ] Пресеты описаны.
- [ ] Запрет «описание = готовый арт» соблюдён.
- [ ] V0 можно произвести без изменения GDD-механик.
