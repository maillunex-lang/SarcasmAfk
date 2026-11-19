# DESIGN_SYSTEM.md — UI Design System

> Версия: 1.1 · 2026-11-19 · Статус: **V0 UI-решения утверждены; ассеты не произведены**
> Направление: Premium Fantasy Mobile UI · Ориентация: 9:16 · Движок: Godot 4
> Зависимости: `ART_DIRECTION.md`, GDD VIS-002 C / VIS-003 A, ROAD этап 04
> Документация не является игровым прототипом.

## 0. Назначение

Единые токены цвета, типографики, отступов, компонентов и правил экранов. Текстовые описания ≠ готовые UI-ассеты.

## 1. Базовая сетка и адаптация

| Параметр | Значение |
|---|---|
| Design canvas | 1080 × 1920 px (эталон) |
| Logical safe area | Отступы 48 px сверху/снизу под вырезы; контент в 984 × 1824 |
| Сетка | 8 px base; ключевые отступы 8 / 16 / 24 / 32 / 48 |
| Колонки контента | 1 колонка для основных экранов; карточки героев — 2 в ряд |
| Минимальный тач-таргет | 88 × 88 px (≈ 48 dp) |
| Плотность | Не более 1 primary CTA в нижней трети главного экрана |

## 2. Цветовые токены

### 2.1 Core

| Token | Hex | Использование |
|---|---|---|
| `color.bg.navy` | `#101C35` | Корневой фон, модалки |
| `color.bg.deep` | `#1D3154` | Карточки, вторичные панели |
| `color.accent.gold` | `#E8BC68` | Primary CTA, награды, акцентные иконки |
| `color.accent.cyan` | `#54D9DA` | Магия, прогресс, AFK, ссылки системы |
| `color.text.ivory` | `#F5F0E5` | Основной текст на тёмном |
| `color.danger.coral` | `#E86D70` | HP-крит, ошибки, опасность |

### 2.2 Расширения (производные)

| Token | Hex | Использование |
|---|---|---|
| `color.bg.panelElevated` | `#243A63` | Приподнятые панели |
| `color.bg.scrim` | `#101C35` @ 72% | Затемнение модалок |
| `color.text.muted` | `#B7C0D4` | Вторичный текст |
| `color.text.onGold` | `#1A1408` | Текст на золотой кнопке |
| `color.success.mint` | `#6BCB8B` | Успех, лечение |
| `color.rarity.N` | `#8A93A6` | Рамка N |
| `color.rarity.R` | `#4C8DDE` | Рамка R |
| `color.rarity.SR` | `#8B5CF6` | Рамка SR |
| `color.rarity.SSR` | `#E8BC68` | Рамка SSR |
| `color.rarity.UR` | `#F0A0FF` | Рамка UR |
| `color.rarity.Mythic` | градиент cyan→gold | Рамка Mythic |

Не использовать фиолетово-белые «AI-default» темы вне редкости SR; основной бренд — navy/gold/cyan.

## 3. Типографика

Избегать Inter / Roboto / Arial / system как display. Рекомендуемые семейства (лицензии проверить до внедрения):

| Роль | Предложение | Размер (эталон 1080) | Вес |
|---|---|---|---|
| Display / заголовки экранов | Cinzel Decorative или Unbounded | 56–64 | SemiBold |
| UI Title | Manrope или Nunito Sans | 40–48 | Bold |
| Body | Manrope | 28–32 | Regular |
| Caption / журнал | Manrope | 22–24 | Medium |
| Damage numbers | Tabular figures, Manrope Bold | 36–44 | Bold |

Правила: контраст текста ≥ 4.5:1 на панелях; не ставить ivory на gold без `color.text.onGold`; длина строки диалога ≤ 42 символа комфортно.

## 4. Компоненты

### 4.1 Кнопки

| Тип | Фон | Текст | Высота | Состояния |
|---|---|---|---|---|
| Primary | Gold `#E8BC68` | onGold | 96 px | normal / pressed (−6% brightness) / disabled 40% |
| Secondary | Deep Blue + gold stroke 2 px | Ivory | 88 px | то же |
| Ghost | transparent + ivory stroke | Ivory | 88 px | то же |
| Danger | Coral | Ivory | 88 px | то же |
| Icon FAB | Navy + cyan icon | — | 112 × 112 | AFK / меню |

Радиус: 16 px (не pill `rounded-full`). Тень: одна мягкая (`0 8 24 #00000055`), без многослойного glow.

### 4.2 Панели

- `PanelStandard`: fill Deep Blue, stroke `#E8BC6833`, radius 20, padding 24.
- `PanelModal`: fill Navy, scrim 72%, radius 24, max width 960.
- `PanelDialog`: Soft Ivory текст на Navy; имя говорящего Gold; кнопка «Далее» Primary.

### 4.3 Карточки героя

- Размер сетки: 480 × 640 (2 в ряд с gap 24).
- Слои: фон редкости → портрет → градиент снизу → имя → класс-иконка → уровень.
- Не использовать карточки в герое главного экрана как «маркетинговые плашки»; карточки — только интерактив коллекции / выбора отряда.

### 4.4 Иконки

- Линейно-заливной гибрид, stroke 3–4 px на 96×96.
- Цвет: ivory по умолчанию; cyan для системы; gold для премиум.
- Набор MVP: Home, Map, Heroes, Battle, AFK, Quest, Guild, Arena, Summon, Events, Settings, Close, Skip, Speed.

### 4.5 Прогресс и ресурсы

- XP/AFK bar: track Deep Blue, fill Arcane Cyan, cap Gold.
- Currency chips: иконка 48 + число tabular; без pill-clusters из 6+ валют в одном ряду (макс. 3 на хедере).

## 5. Движение UI

Минимум 2–3 намеренных motion на визуально ведущих экранах:

1. Появление нижней навигации (slide-up 200 ms, ease-out).
2. Pulse CTA «Забрать AFK» (scale 1.0↔1.04, 1.2 s).
3. Открытие диалога (fade + 12 px rise, 180 ms).

На Low-пресете: отключить pulse и сложные шейдеры панелей; оставить мгновенные переходы или 100 ms fade.

## 6. Карта экранов MVP (расширенный)

| # | Экран | ID | Ключевые элементы |
|---|---|---|---|
| 1 | Главный | `UI-HOME` | Герой-витрина, CTA Кампания, AFK, валюты, нижнее меню |
| 2 | Карта республики | `UI-MAP-WORLD` | Стилизованная карта, точки городов, Уфа стартовая |
| 3 | Карта города / локации | `UI-MAP-CITY` | Якоря Lxx, состояние квеста |
| 4 | Бой | `UI-BATTLE` | 2 линии, ультимейты, speed, skip FX |
| 5 | Коллекция | `UI-HEROES` | Сетка 12 героев |
| 6 | Карточка / апгрейд | `UI-HERO-DETAIL` | Портрет, навыки, прокачка |
| 7 | AFK-награды | `UI-AFK` | Таймер ≤24ч, claim |
| 8 | Квесты / диалоги | `UI-QUEST` / `UI-DIALOG` | Текст, skip, журнал |
| 9 | Гильдия | `UI-GUILD` | Заглушка ролей до сервера |
| 10 | Арена | `UI-ARENA` | Асинхронный матч UI |
| 11 | Призыв | `UI-SUMMON` | Гача на моках |
| 12 | События | `UI-EVENTS` | Календарь ограниченный |

## 7. Вертикальный срез: главный экран `UI-HOME-V0`

### Заставка `UI-SPLASH-V0`

- Wordmark **«БашЛегенды: Эпоха Абсурда»** по центру / верхней трети.
- Короткий fade-in; без геймплейных кнопок.
- Репозиторий и package ID не отражаются в брендинге как «SarcasmAfk» для игрока.

### Композиция первого вьюпорта Home (одна сцена, не дашборд)

1. Бренд / рабочее название (hero-level, **обязательно** на Home V0).
2. Один короткий слоган.
3. Одна группа CTA: «В кампанию» (primary) + «AFK» (secondary/FAB).
4. Доминантный визуал: H01 Каэрон на фоне намёка на Площадь талонов (full-bleed фон, не inset-карточка).

Запрещено в первом вьюпорте V0: статы, расписание событий, адресные блоки, pill-clusters, плавающие бейджи на герое.

### Wire-метрики

```
[ Safe top 48 ]
Brand wordmark 64
Spacer 16
Slogan caption 28
[ Full-bleed hero stage ~1100 ]
Bottom CTA row 120
Nav bar 128
[ Safe bottom 48 ]
```

## 8. Диалоговое окно (STORY-003 D + решение V0)

- Имя говорящего (gold).
- Текст реплики (ivory), typewriter optional (отключаемо).
- Кнопки: Далее | Пропуск.
- Журнал: список реплик без повторной выдачи наград.
- **Портрет: статичный bust/portrait говорящего** (H01/H02/H03/NPC-система).
- Запрещено в V0: lipsync, морфы лица, анимированные кат-сцены.
- Смена говорящего = смена статичного портрета + имя; лёгкий fade 100–180 ms допустим.

## 9. Промпты генерации UI

### P-UI-01 — Главный экран

```
Premium fantasy mobile game home screen, vertical 9:16, 1080x1920,
midnight navy and deep blue UI, royal gold CTA button, arcane cyan AFK indicator,
soft ivory typography, full-bleed stylized fantasy plaza background,
single warrior hero centered as brand stage, clean modern RPG HUD,
no cards in hero area, no floating badges, no photorealism,
high-end AFK idle RPG --ar 9:16
```

### P-UI-02 — Диалог

```
Fantasy mobile RPG dialogue panel overlay, vertical 9:16,
static character bust portrait on the side, speaker name in gold,
soft ivory body text, midnight navy panel, continue and skip buttons,
subtle text reveal, no lipsync, no animated face, clean premium UI,
readable on small phone --ar 9:16
```

### P-UI-03 — Карточка героя SR

```
Mobile RPG hero card UI, SR rarity purple-gold frame accents,
stylized anime fantasy warrior portrait, class icon warrior,
level badge, deep blue panel, royal gold trim, clean silhouette,
portrait orientation component on dark navy --ar 3:4
```

## 10. Список ассетов UI (V0 + ядро)

| ID | Ассет | Примечание |
|---|---|---|
| UI-SPLASH-BG | Фон заставки | Специфицирован |
| UI-HOME-BG | Фон главного экрана (L01 tone) | Специфицирован |
| UI-LOGO-WORDMARK | Wordmark «БашЛегенды: Эпоха Абсурда» | Утверждён к показу на splash/home |
| UI-BTN-PRIMARY | 9-slice кнопка gold | Специфицирован |
| UI-BTN-SECONDARY | 9-slice secondary | Специфицирован |
| UI-PANEL-DIALOG | 9-slice диалог | Специфицирован |
| UI-ICON-SET-16 | 16 базовых иконок | Специфицирован |
| UI-NAV-BAR | Нижняя навигация | Специфицирован |
| UI-AFK-CHIP | Индикатор AFK | Специфицирован |
| UI-CURRENCY-ICONS | 3 валюты-заглушки | Без финальной экономики |
| UI-FRAME-RARITY | 6 рамок редкостей | N–Mythic |

## 11. Приёмка

- [ ] Токены цветов совпадают с ART_DIRECTION.
- [ ] Главный экран V0 проходит brand test (без навбара бренд всё ещё доминирует).
- [ ] Тач-таргеты ≥ 88 px.
- [ ] Диалоги соответствуют STORY-003 D.
- [ ] Нет объявления ассетов «готовыми» без файлов.
