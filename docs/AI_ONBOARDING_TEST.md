# AI_ONBOARDING_TEST.md — cold-start check

> Goal: a new agent finds the next task + verify commands in ≤5 files, without contradictions.

## Simulated cold start (2026-11-19)

| Step | File | What the agent learns |
|------|------|------------------------|
| 1 | `AGENTS.md` | Read order, hard rules, stack |
| 2 | `docs/PROJECT_CONTEXT.md` | Product + milestone + constraints |
| 3 | `docs/STATUS.md` | NOW / works / blocked with evidence |
| 4 | `docs/TASK_QUEUE.md` | Next actionable IDs |
| 5 | `docs/AI_TASK_ROUTER.md` | Which code + commands for that task type |

Optional 6th: one domain spec from the router row (not the whole docs tree).

## Expected answers (this snapshot)

1. **What is the game?** Android Godot idle RPG “БашЛегенды”; repo `SarcasmAfk`.
2. **Where is code?** `client/` + `server/`.
3. **What is NOW?** Post VO-001 on `main`; REPO-REORG-001 in progress on `cursor/chore-repo-reorg-001-beaf`; next product TODO includes T-157 / owner-gated items.
4. **What is blocked?** T-090 CH02, T-131 Stage E, T-126 keystore, T-153 real payments, T-128 owner accept.
5. **How to verify?** `bash scripts/ci_validate.sh` (or router commands for the subsystem).

## Pass / fail

| Check | Result |
|-------|--------|
| ≤5 files to next task | **PASS** (route above) |
| STATUS matches `main` VO merge | Fixed in PR-2 (was stale pre-reorg) |
| No conflicting “truth” files required | **PASS** if agents ignore archive reports as canon |
| Token savings claim | **Not measured** — do not claim % |

## Failure modes to avoid

- Treating `docs/reports/*` audit history as current STATUS.
- Marking TEMP art as final Stage E.
- Starting CH02 or payments because JSON stubs exist.
