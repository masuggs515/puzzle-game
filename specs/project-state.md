# Project State
Last updated: 2026-03-10
Current phase: 4 — Core Game
Current task branch: task/phase4-tile-placement

---

## Phase Completion

- [ ] Phase 1 — Project Setup (in progress — Phase 2 started per Adam's instruction)
- [ ] Phase 2 — Foundation (code merged; end-to-end verification requires device)
- [ ] Phase 3 — Puzzle Engine (PR #12 merged; levels_001_200.json and Supabase seeding still blocked — see TODO MAS)
- [ ] Phase 4 — Core Game (in progress — PR #15 open, awaiting Level 1 playtesting)
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
| 20260301000001_create_enums | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000002_create_player_profiles | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000003_create_player_progress | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000004_create_coin_transactions | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000005_create_achievements | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000006_create_analytics_events | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000007_create_puzzles | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000008_rls_policies | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000009_indexes | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000010_stored_procedures | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000011_triggers | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260301000012_auto_rls_trigger | ✓ applied | ✓ applied 2026-03-01 | not yet |
| 20260303010346_fix-function-search-paths | ✓ applied | ✓ applied 2026-03-03 | not yet |
| 20260303014251_fix-is-guest-for-anonymous-users | ✓ applied | ✓ applied 2026-03-03 | not yet |
| 20260303014942_restrict-migrate-anon-function | ✓ applied | ✓ applied 2026-03-03 | not yet |

---

## Open PRs

- **PR #15** — "feat: Phase 4 — tile-placement mechanic, crossword grid, drag-and-drop" — targeting dev — DO NOT MERGE YET (Level 1 playtesting required first)

---

## Open TODO MAS Items

- [ ] **Branch protection rules** — Go to https://github.com/masuggs515/puzzle-game → Settings → Branches:
  - Branch `main`: Require PR before merging, Require 1 approval, Do not allow bypassing
  - Branch `dev`: Require PR before merging, Do not allow force pushes
  — raised 2026-03-01

- [ ] **Disable email confirmation for development** — puzzle-game-dev dashboard → Authentication → Providers → Email → disable "Enable email confirmations". — raised 2026-03-01

- [ ] **Confirm app brand colors** — Placeholder palette in `lib/core/theme/app_colors.dart`. Confirm before Phase 5 visual work. — raised 2026-03-01

- [ ] **levels_001_200.json** — Not yet generated. CLI tool (`dart run tools/generate_puzzles.dart`) is ready. Blocked on word list decision (resolved: proceed with ~1,200-word list) and pending pre-generation embedding hand-crafted levels 1–50 first. — raised 2026-03-03

- [ ] **Puzzles seeded in Supabase `puzzles` table** — Phase 3 DoD item. Blocked on levels_001_200.json. — raised 2026-03-03

- [ ] **Level 32 multi-intersection** — Level 32 (boss) has SCARF pos 2 in two intersections. Geometrically valid; engine handles it. Confirm in Phase 4 playtesting. — raised 2026-03-03

- [ ] **Hint cost (5 or 10 coins)** — GameConstants.hintCost set to 5 (spec default). GDD says 5–10 TBD. Confirm via Phase 4 playtesting. — raised 2026-03-04

- [ ] **Phase 4 playtesting (all 50 levels)** — Manual step: play every level, record findings. Required for Phase 4 DoD. Do on physical device after PR #15 merges. — raised 2026-03-04

- [ ] **Sign in with Apple** — Phase 8/9. — raised 2026-03-01
- [ ] **Sign in with Google** — Phase 8/9. — raised 2026-03-01
- [ ] **App name / codename** — Before Phase 8/10. — raised 2026-03-01
- [ ] **iOS build verification** — Requires Mac. — raised 2026-03-01

- [ ] **Level 1 playtesting** — Test PR #15 on physical device: grid layout, drag feel, tile displacement, intersection cell visual, submit feedback. Required before merging. — raised 2026-03-05
- [ ] **Merge PR #15** — Phase 4 tile-placement — after Level 1 playtesting confirmed — raised 2026-03-05

---

## Phase 1 Definition of Done Checklist

- [ ] App launches on simulator and physical device without crashing
- [ ] Supabase connection confirmed (status shows "connected" in hello world screen)
- [x] No secrets committed to Git
- [x] All dependencies installed and resolving
- [x] Android build succeeds — `flutter build apk --debug` ✓
- [ ] iOS build succeeds — requires Mac; TODO MAS raised
- [x] Repository pushed to GitHub with main and dev branches
- [ ] Branch protection rules enabled on main and dev (TODO MAS above)
- [x] `flutter analyze` clean
- [x] `flutter test` passing

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
> Full end-to-end verification requires running the app with `bash scripts/run_dev.sh`.

---

## Phase 3 Definition of Done Checklist

- [x] `answer_words.txt` and `valid_guess_words.txt` exist and correctly filtered (~1,200-word placeholder accepted)
- [x] All category lists populated (14 categories, 12 required + 2 extras)
- [x] All constraint tests passing (95/95)
- [x] All solver tests passing (100/100 total)
- [x] All 50 hand-crafted puzzles serialized in hand_crafted_001_050.json
- [ ] `levels_001_200.json` exists with 200 valid puzzles — blocked (see TODO MAS)
- [ ] Puzzles seeded in Supabase `puzzles` table — blocked on levels_001_200.json
- [x] Debug screen loads all puzzles without errors
- [ ] Performance: puzzle load time under 500ms — unverified (requires device)

---

## Phase 4 Definition of Done Checklist

- [ ] All 50 hand-crafted levels playable end-to-end — requires device playtest
- [ ] Drag mechanic smooth at 60fps on physical device — requires device
- [x] Both feedback states working correctly (red/amber) with correct messages — code + tests ✓
- [x] Level complete screen working with correct star rating — code + tests ✓
- [x] Back button with confirmation works (PopScope) — code ✓
- [ ] Playtest of all 50 levels complete, all issues documented and resolved — TODO MAS raised
- [ ] No crashes in Sentry during playtesting session — requires device

---

## Recent Sessions

| Date | Task | Branch | Outcome |
|---|---|---|---|
| 2026-03-01 | Phase 1 skeleton | dev | Both branches pushed to GitHub |
| 2026-03-01 | Phase 1 build verification | task/phase1-build-verification | PR #1 merged |
| 2026-03-01 | Claude agent infrastructure | task/claude-agent-setup | PR #2 merged |
| 2026-03-01 | Phase 2 DB schema — 12 migrations, 2 Edge Functions | task/phase2-supabase-schema | PR #3 merged |
| 2026-03-01 | Phase 2 Flutter foundation — auth, services, 4 screens, 5 tests | task/phase2-flutter-foundation | PR #4 merged |
| 2026-03-02 | Fix CRLF line endings | task/fix-script-line-endings | PR #5 merged |
| 2026-03-02 | All PRs merged (#1, #3, #4, #5) | dev | dev branch up to date |
| 2026-03-03 | Phase 3 puzzle engine — full engine, 50 levels, debug screen | task/phase3-puzzle-engine | PR #12 merged. 100/100 tests. |
| 2026-03-04 | Phase 4 core game — Flame drag, game state, feedback, level complete | task/phase4-core-game | PR #14 merged. 128/128 tests. |
| 2026-03-05 | Phase 4 tile-placement redesign — crossword grid, drag-and-drop, tile pool fix | task/phase4-tile-placement | PR #15 open. 153/153 tests. |
