# CHARACTER_STYLE_GUIDE.md — Герои, враги, анимации, VFX

> Версия: 1.1 · 2026-11-19 · Статус: **V0-пайплайн утверждён; ассеты не произведены**
> Источник персонажей: `HEROES.md` (H01–H12). Имена и классы не переименовывать.
> Враги CH01: `CAMPAIGN_LOCATIONS.md` §6. Числа баланса — TBD, здесь только визуал.
> Боевой пайплайн V0: Blender 3D → анимация → прозрачные 2D-атласы → Godot 4.

## 0. Цели

- Единый силуэтный язык Stylized Anime Fantasy.
- Классовая читаемость цвета/формы.
- Анимационный набор под AFK-автобой + ручные ультимейты.
- VFX, укладывающиеся в пресеты Low/Med/High.

## 1. Пропорции и силуэт

| Параметр | Значение |
|---|---|
| Рост героя (боевой) | ~520–560 px на эталоне 1080 ширины арены |
| Пропорции | Голова ~1/5.5–1/6 тела (умеренно anime, не chibi) |
| Плечи | Класс-зависимы: танк широкие, маг уже, воин динамичный контрапост |
| Читаемость | Узнавание в 128 px иконке и в полный рост |
| Контур | Мягкий dark navy outline 2–3 px или qualitative separation без жёсткого «тоон-обвода» везде |

Силуэт-тест: чёрный спрайт на сером фоне — класс угадывается без цвета.

## 2. Материалы

| Материал | Стилизация |
|---|---|
| Ткань плаща | Крупные складки, 2–3 тона, без micro-weave |
| Металл доспеха | Чистые блики, ограниченный specular |
| Кожа/ремень | Матовые плоскости |
| Магия/руны | Emissive cyan / lilac, animated UV на High |
| Бумага (враги) | Жёсткие сгибы, штамп, номер — источник сатиры |

Запрет: фототекстуры кожи, грязь, шум film grain на персонажах.

## 3. Классовые маркеры

| Класс | Форма | Цвет-якорь | Оружие-знак |
|---|---|---|---|
| Танк | Массивный щит/наплечники | Графит + медь/малахит | Щит, молот |
| Воин | Диагональ плаща, клинок | Янтарь + тёмно-синий | Меч, клинки |
| Маг | Мантия, посох/сфера | Лиловый / лазурь + cyan | Посох, книга, часы |
| Поддержка | Открытый жест, инструмент | Бирюза / кремовый / soft gold | Ключ, фонарь, посох лечения |

## 4. Редкость (визуал, не баланс)

| Редкость | Орнамент | VFX idle |
|---|---|---|
| N | Минимум | Нет |
| R | Простая кайма | Редкий блик |
| SR | Узор фракции | Лёгкие частицы |
| SSR | Сложный узор + emissive | Постоянный soft aura |
| UR | Асимметричный орнамент | Двухцветный aura |
| Mythic | Уникальный crown FX | Сложный loop (High only) |

Стартовый ростер HEROES: R / SR / SSR — N/UR/Mythic остаются уровнями системы даже без представителей в первых 12.

## 5. Карточки героев V0 (сюжетные трое)

Имена и визуал строго по HEROES.md.

### H01 — Каэрон (Воин, SR, Вольные искатели)

- Серебристые волосы, тёмно-синий плащ, янтарный шарф, короткий меч.
- Ультимейт FX: «Прорыв регламента» — золотой разрез печати/барьера.
- Позиция: фронт.

### H02 — Вейриса (Поддержка, SR, Мастера искры)

- Бирюзовый плащ механика, золотые крепления, магический ключ.
- Ультимейт FX: «Аварийный ремонт» — cyan искры + green mend glyphs.
- Позиция: тыл.

### H03 — Эльдарион (Маг, SSR, Хранители свитков)

- Лиловая мантия, рунический посох, очки с сияющими линзами.
- Ультимейт FX: «Параграф забвения» — руны-параграфы, замедляющий туман.
- Позиция: тыл.

## 6. Остальной ростер — краткие визуальные якоря

| ID | Якорь внешности (из HEROES) |
|---|---|
| H04 Тарвекс | Графитовые доспехи, горный щит |
| H05 Селарис | Медно-синие рукава, катушки, кристалл |
| H06 Ноктар | Чёрно-бордовая броня, двойные клинки |
| H07 Аурелиян | Кремовый плащ, подвески-свитки |
| H08 Гранвир | Базальтовые наплечники, малахитовые руны, молот |
| H09 Лиорен | Зелёный капюшон, изогнутый клинок |
| H10 Мираксис | Тёмно-лазурная мантия, парящие часы |
| H11 Феронис | Медная броня, складной щит |
| H12 Зирель | Белая накидка, синие узоры, фонарь |

## 7. Враги — визуальный юмор

| Правило | Пример |
|---|---|
| Чистый стилизованный «монстр из канцелярии» | E01 Живой талон с зубастым номером |
| Силуэт ≠ герой | Бумажный голем — глыба листов, не гуманоид-герой |
| Один gag-prop на тип | Штамп, лупа, фуражка, ластик |
| Без реальных лиц и форменных копий | Фэнтези-инспектор, не пародия на конкретного чиновника |

Эталон V0: **E01 Живой талон** — мелкий нападающий, бумажный талон с зубастым номером.

Мини-босс E20 / босс E30 — увеличенный силуэт, уникальная палитра мантии/кресла, фазы читаются сменой aura (щит → контроль → усиление).

## 8. Набор анимаций (герой)

Обязательный набор (HEROES / VIS):

| Анимация | Длительность ориентир | Заметки |
|---|---|---|
| idle | 1.2–2.0 s loop | Дыхание, плащ |
| attack | 0.4–0.7 s | Hit frame на 40–55% |
| ultimate | 1.0–1.6 s | Ручной каст + VFX socket |
| hit | 0.25–0.4 s | Отдача |
| win | 1.0–1.5 s | Победа |
| death/defeat | 0.8–1.2 s | Поражение |

Техника (утверждено V0): **Blender 3D-модель → анимация в Blender → орто/камерный рендер прозрачных кадров → упаковка 2D-атласа → Godot 4 SpriteFrames / AnimatedSprite2D** (уточнение VIS-001 C).  
В рантайме Android **нет** тяжёлой 3D-сцены персонажа — только атласы и VFX.  
До первого bake допускается помеченный placeholder (статичный idle + 2 кадра атаки), не выдаваемый за финал.

## 9. VFX-правила

| Пресет | Частицы | Искажения экрана | Трейлы |
|---|---|---|---|
| Low | Выкл или 1 burst | Выкл | Выкл |
| Medium | Короткие bursts | Лёгкий | На ультимейтах |
| High | Loop aura SSR+ | Shake ультимейт | Полные |

Цвета VFX: урон coral/gold; лечение mint/cyan; контроль lilac; система/Печать — cyan+gold.

## 10. Требования к ассетам на героя

1. Полноразмерный концепт (лист A).
2. Портрет UI (карточка героя).
3. **Статичный диалоговый портрет** (bust; без lipsync).
4. Blender-сцена + анимации → прозрачный боевой 2D-атлас.
5. Иконка умения ×2–3.
6. VFX ультимейта (спрайт-шит или particles scene).

## 11. Промпты генерации

### P-CHR-01 — Каэрон full concept

```
Full body character concept art, Kaeron fantasy warrior, silver hair,
dark blue cloak, amber scarf, short sword, stylized anime fantasy,
clear silhouette, premium clean mobile RPG hero, soft lighting,
harmonious colors, no photorealism, white/neutral backdrop turnaround hint,
vertical composition --ar 9:16
```

### P-CHR-02 — Вейриса full concept

```
Full body character concept, Veirisa technomage support heroine,
turquoise mechanic cloak, gold fastenings, magical key tool,
stylized anime fantasy, clear readable silhouette, premium clean art,
soft lighting, mobile RPG, no photorealism --ar 9:16
```

### P-CHR-03 — Эльдарион full concept

```
Full body character concept, Eldarion archivist mage, lilac robes,
runic staff, glowing lens glasses, stylized anime fantasy SSR mage,
elegant silhouette, premium clean mobile RPG, soft magical rim light,
no photorealism --ar 9:16
```

### P-CHR-04 — Портрет UI (шаблон)

```
Bust portrait UI asset for mobile RPG, [HERO NAME], [CLASS], 
expressive face, clean stylized anime fantasy, soft lighting,
transparent or solid navy backdrop, high readability at small size --ar 1:1
```

### P-CHR-05 — E01 Живой талон

```
Cute menacing fantasy enemy, living paper queue ticket monster,
toothy number stamp face, clean stylized mobile RPG creature,
readable silhouette, comic bureaucracy satire, no gore, no logos --ar 1:1
```

### P-CHR-06 — Боевой idle sheet placeholder note

```
Game animation concept sheet, five heroes stylized anime fantasy,
idle attack ultimate poses labeled, AFK RPG battle sprites,
clean premium style, orthographic useful for atlas --ar 16:9
```

## 12. Список ассетов персонажей

### V0 must-have

| ID | Ассет |
|---|---|
| H01-CONCEPT | Концепт Каэрона |
| H01-PORTRAIT | Портрет UI |
| H01-BATTLE | Боевой атлас/скелет (или placeholder) |
| H01-ULT-VFX | FX ультимейта |
| H02-CONCEPT / PORTRAIT / BATTLE / ULT-VFX | Вейриса |
| H03-CONCEPT / PORTRAIT / BATTLE / ULT-VFX | Эльдарион |
| E01-CONCEPT | Живой талон |
| E01-BATTLE | Боевой спрайт |

### После утверждения V0

H04–H12 полный пакет; E02–E30 по CAMPAIGN; shared VFX library (hit, heal, shield, stun).

## 13. Приёмка

- [ ] Имена H01–H03 совпадают с HEROES.md.
- [ ] Классы и позиции фронт/тыл соблюдены.
- [ ] Силуэт-тест пройден.
- [ ] Анимационный список полный.
- [ ] Placeholder явно помечен, не выдаётся за финал.
