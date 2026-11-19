# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main`  
> CH01 vertical slice на Android (debug APK). Release keystore не найден.

## NOW

**Закрыто:** T-114 (live default в release), T-125 (играбельная цепочка + debug APK).  
**BLOCKED:** T-126 release APK — нет `ANDROID_RELEASE_KEYSTORE` на VPS/в доступных secrets (не создаём новый).  
**Дальше:** owner keystore → release APK; owner art-approve H01–H03/E01; CH01 accepted → P3.

## Работает / частично / заглушки

| | |
|---|---|
| **Работает** | Home→карта Уфы→L01→диалог→отряд→автобой→ручной ULT→награда→сейв→B02; debug APK; live integration (auth/battle/rewards/resume); reward idempotency |
| **Частично** | H01/H02/H03/E01 combat — Blender pipeline **drafts** (D-ART-05), не финальный арт; release build preset без подписи |
| **Заглушки / mock** | Debug APK по умолчанию **mock** (offline); guild/arena/events UI «НЕДОСТУПНО»; CH02+ закрыт; H04–H12 combat placeholders |

## Keystore audit

- Найдены только debug keystores (`~/.android/debug.keystore`, Godot keystores).
- GitHub Actions secrets: недоступны текущему токену (403).
- Новый release key **не** создавался (D-ADMIN-03).
