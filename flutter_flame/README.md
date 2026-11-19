# БашЛегенды — Flutter + Flame демо

Меню + бой 1×1 (вид сбоку) на **Flutter 3 / Flame 1.38**.

## Запуск

```bash
export PATH="$HOME/flutter-sdk/flutter/bin:$PATH"   # если нужно
cd flutter_flame
flutter pub get
flutter run -d chrome --web-port=5173
# или: flutter run -d web-server --web-port=5173 --web-hostname=127.0.0.1
```

## Что внутри

- Главный экран (меню) с фоном и кнопкой «В бой»
- Арена Flame: забег → idle → удар (смена поз) → hit VFX → смерть
- Спрайты Каэрона / Живой Печати (idle / run / attack) + slash/burst

## Структура

```
lib/
  main.dart
  screens/menu_screen.dart
  screens/battle_screen.dart
  game/arena_game.dart
  game/fighter.dart
assets/images/   # спрайты и фоны
```
