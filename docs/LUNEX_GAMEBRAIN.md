# Lunex GameBrain — архитектура (документация only)

Status: **ROADMAP / ARCHITECTURE** · 2026-11-19  
Scope: future AI Society for BashLegends. **Do not install LLM on VPS in this phase.**

## 1. Цель

Локальная компактная LLM на VPS, управляющая ИИ-игроками («агентами общества»), которые:

- Общаются в глобальном и гильдейском чатах (макс. **10 слов** на сообщение).
- Развиваются: гильдии, гача, PvE, прогрессия через **серверные API** (не читы).
- Имеют долговременную память.
- Знают игру только из утверждённых документов + live API.
- Управляются из админки (вкл/выкл, лимиты, персоны, каналы).

## 2. Компоненты (план)

| Компонент | Роль |
|---|---|
| `gamebrain-host` | Процесс на VPS: LLM runtime + agent loop (отдельный деплой) |
| `gamebrain-gateway` | HTTP/WS к Go API с service account / admin key |
| `persona store` | Профили ИИ-игроков, память (PG + optional vector) |
| `policy engine` | Лимит 10 слов, rate limits, запрет HTML/команд, PvP caps |
| Admin UI | Toggle agents, quotas, channel allowlist, kill switch |

## 3. Интеграция с текущим API

ИИ-игроки = обычные аккаунты с флагом `bot_kind=gamebrain` + отдельные сессии.  
Действия только через существующие endpoints: chat, guild, gacha, battles, shop (не TEST для prod bots).  
Память: `gamebrain_memory(account_id, key, value, updated_at)`.

## 4. Безопасность

- Нет прямого доступа к БД экономики вне API.
- Egress allowlist для модели.
- Kill switch в админке останавливает всех агентов.
- Сообщения проходят ту же sanitize/rate-limit цепочку, что и игроки.

## 5. Этапы внедрения (будущее)

1. Контракты аккаунтов-ботов + admin flags.  
2. Shadow mode (логируют «намерения», не пишут в чат).  
3. Chat-only agents (10 слов).  
4. Guild + gacha + PvE loops.  
5. Memory + evaluation harness.

## 6. Запреты сейчас

- Не устанавливать LLM на VPS.
- Не коммитить веса моделей.
- Не запускать агентов в production chat без отдельного разрешения владельца.
