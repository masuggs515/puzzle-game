# Project State
Last updated: 2026-03-01
Current phase: 2 — Foundation (in progress)
Current task branch: task/phase2-flutter-foundation (PR #4 open → dev)

---

## Phase Completion

- [ ] Phase 1 — Project Setup (in progress — Phase 2 started per Adam's instruction)
- [ ] Phase 2 — Foundation (in progress)
- [ ] Phase 3 — Puzzle Engine
- [ ] Phase 4 — Core Game
- [ ] Phase 5 — Economy & Progression
- [ ] Phase 6 — Analytics
- [ ] Phase 7 — The Vault
- [ ] Phase 8 — Polish
- [ ] Phase 9 — Monetization
- [ ] Phase 10 — Pre-Launch

---

## Migration Status

| Migration | local db | puzzle-game-dev | puzzle-game-prod |
|---|---|---|---|
| 20260301000001_create_enums | ✓ applied | pending Adam approval | not yet |
| 20260301000002_create_player_profiles | ✓ applied | pending Adam approval | not yet |
| 20260301000003_create_player_progress | ✓ applied | pending Adam approval | not yet |
| 20260301000004_create_coin_transactions | ✓ applied | pending Adam approval | not yet |
| 20260301000005_create_achievements | ✓ applied | pending Adam approval | not yet |
| 20260301000006_create_analytics_events | ✓ applied | pending Adam approval | not yet |
| 20260301000007_create_puzzles | ✓ applied | pending Adam approval | not yet |
| 20260301000008_rls_policies | ✓ applied | pending Adam approval | not yet |
| 20260301000009_indexes | ✓ applied | pending Adam approval | not yet |
| 20260301000010_stored_procedures | ✓ applied | pending Adam approval | not yet |
| 20260301000011_triggers | ✓ applied | pending Adam approval | not yet |
| 20260301000012_auto_rls_trigger | ✓ applied | pending Adam approval | not yet |

---

## Open PRs

- **PR #1** — "chore: Phase 1 build verification — smoke test + sentry upgrade" — https://github.com/masuggs515/puzzle-game/pull/1 — awaiting Adam review and merge
- **PR #3** — "schema: Phase 2 database schema — tables, RLS, stored procedures, triggers" — https://github.com/masuggs515/puzzle-game/pull/3 — awaiting Adam review and merge
- **PR #4** — "feat: Phase 2 Flutter foundation — auth, services, screens" — https://github.com/masuggs515/puzzle-game/pull/4 — awaiting Adam review and merge (merge PR #3 first)

---

## Open TODO MAS Items

- [ ] **Branch protection rules** — Go to https://github.com/masuggs515/puzzle-game → Settings → Branches and add:
  - Branch `main`: Require PR before merging, Require 1 approval, Do not allow bypassing
  - Branch `dev`: Require PR before merging, Do not allow force pushes
  — raised 2026-03-01

- [ ] **Supabase cloud projects** — Create `puzzle-game-dev` and `puzzle-game-prod` in Supabase dashboard (supabase.com). Save URLs, anon keys, and service role keys in credentials.txt. Required before applying migrations to cloud environments. — raised 2026-03-01

- [ ] **Apply migrations to puzzle-game-dev** — After merging PR #3 to dev and after creating the cloud project, confirm and I will run `supabase db push --linked` against puzzle-game-dev. — raised 2026-03-01

- [ ] **Configure Auth webhook (create-player-profile Edge Function)** — In puzzle-game-dev and puzzle-game-prod dashboards: Authentication → Hooks → add hook for "User created" event → point to `create-player-profile` function URL. The DB trigger (migration 011) handles local dev without this. — raised 2026-03-01

- [ ] **Disable email confirmation for development** — In puzzle-game-dev dashboard: Authentication → Providers → Email → disable "Enable email confirmations". Prevents needing to click a confirmation link when testing sign-up. — raised 2026-03-01

- [ ] **Sign in with Apple** — Requires Apple Developer account + Supabase OAuth config. Add in Phase 8/9 before App Store submission. — raised 2026-03-01

- [ ] **Sign in with Google** — Requires Google Cloud project + OAuth credentials in Supabase. Add in Phase 8/9. — raised 2026-03-01

- [ ] **Confirm app brand colors** — Placeholder colors in `lib/core/theme/app_colors.dart`. Confirm palette before Phase 4. — raised 2026-03-01

- [ ] **App name / codename** — Spec says "codename TBD". Needed before Phase 8/10. — raised 2026-03-01

- [ ] **iOS build verification** — `flutter build ios --no-codesign` must be run on a Mac. Android confirmed ✓. — raised 2026-03-01

- [ ] **Review and merge PR #1** — https://github.com/masuggs515/puzzle-game/pull/1 — Phase 1 build verification. — raised 2026-03-01

- [ ] **Review and merge PR #3** — https://github.com/masuggs515/puzzle-game/pull/3 — Phase 2 DB schema. Merge before PR #4. — raised 2026-03-01

- [ ] **Review and merge PR #4** — https://github.com/masuggs515/puzzle-game/pull/4 — Phase 2 Flutter foundation. Merge after PR #3. — raised 2026-03-01

---

## Phase 1 Definition of Done Checklist

- [ ] App launches on simulator and physical device without crashing
- [ ] Supabase connection confirmed (status shows "connected" in hello world screen)
- [x] No secrets committed to Git
- [x] All dependencies installed and resolving
- [ ] Both dev and prod Supabase cloud projects created (pre-phase setup — Adam's action)
- [x] Android build succeeds — `flutter build apk --debug` ✓ (commit 391f064)
- [ ] iOS build succeeds — requires Mac; TODO MAS raised
- [x] Repository pushed to GitHub with main and dev branches — https://github.com/masuggs515/puzzle-game
- [ ] Branch protection rules enabled on main and dev (TODO MAS above)
- [x] `flutter analyze` clean — no issues
- [x] `flutter test` passing — 5/5 (upgraded from 1/1 in Phase 2 session)

---

## Phase 2 Definition of Done Checklist

- [ ] App launches and automatically creates an anonymous session
- [ ] `player_profiles` row visible in Supabase dashboard within 2 seconds of first launch
- [ ] Home screen shows real data from Supabase (coins, streak, words found — all 0 initially)
- [ ] Sign up creates an account and migrates anonymous data
- [ ] Sign in restores progress on a new device
- [ ] All RLS policies verified: logged in as user A cannot see user B's data
- [ ] No crashes, no unhandled exceptions in Sentry

> NOTE: DB schema applied to local Supabase ✓. Flutter code written ✓.
> Full end-to-end verification (checking Supabase dashboard for player_profiles row)
> requires running the app with `bash scripts/run_dev.sh`.

---

## Recent Sessions

| Date | Task | Branch | Outcome |
|---|---|---|---|
| 2026-03-01 | Phase 1 skeleton — Git init, Flutter create, README, project-state, push to GitHub | dev (initial commit eb42784) | Both branches pushed to https://github.com/masuggs515/puzzle-game |
| 2026-03-01 | Phase 1 build verification — smoke test + sentry upgrade | task/phase1-build-verification | PR #1 open → dev. flutter analyze ✓ flutter test 1/1 ✓ flutter build apk ✓ |
| 2026-03-01 | Claude agent infrastructure — .claude/agents/ + settings.json | task/claude-agent-setup | PR #2 merged to dev. 8 agent spec files + skipPermissions setting. |
| 2026-03-01 | Phase 2 DB schema — 12 migrations, 2 Edge Functions, local DB verified | task/phase2-supabase-schema | PR #3 open → dev. supabase migration list 12/12 applied locally. |
| 2026-03-01 | Phase 2 Flutter foundation — auth, services, 4 screens, 5 tests | task/phase2-flutter-foundation | PR #4 open → dev. flutter analyze clean, 5/5 tests passing. |
