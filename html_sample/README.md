# БашЛегенды — HTML-клиент (образец)

Полноценный **редактируемый UI** на HTML/CSS/JS (9:16). Godot не нужен для оболочки.

## Экраны

- Splash · Город (POI + rails + tabbar)
- Кампания (5 этапов, прогрессия)
- Герои (партия 5, localStorage)
- Магазин (soft/hard, бесплатный пак)
- AFK (накопление до 8ч)
- Бой L/R + АВТО/×2/ULT по портрету

Сохранение: `localStorage` ключ `bashlegends_html_v1`.

## Правка UI

Редактируй `index.html` / `styles.css` / `app.js` — сразу видно в браузере.

```bash
python3 -m http.server 8765 --directory html_sample --bind 127.0.0.1
```

Live: https://bashlegends-shell.apps.grok.bot
