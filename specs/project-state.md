# Project State
Last updated: 2026-03-14
Current phase: 7 — Ads & Monetization
Current task branch: task/phase7-ads-monetization (PR #25 open)

---

## Phase Completion

- [ ] Phase 1 — Project Setup (in progress — Phase 2 started per Adam's instruction)
- [ ] Phase 2 — Foundation (code merged; end-to-end verification requires device)
- [ ] Phase 3 — Puzzle Engine (PR #12 merged; levels_001_200.json and Supabase seeding still blocked — see TODO MAS)
- [x] Phase 4 — Core Game (playtesting complete 2026-03-11 on Samsung Galaxy S8+ and emulator — mechanic confirmed good)
- [ ] Phase 5 — Economy & Progression (in progress — PR open, awaiting review and merge)
- [ ] Phase 6 — Analytics (in progress — PR #24 open)
- [ ] Phase 7 — Ads & Monetization (in progress — PR #25 open; spec Phase 9 content sequenced here)
- [ ] Phase 8 — The Vault (spec Phase 7 content — deferred)
- [ ] Phase 9 — Polish (spec Phase 8)
- [ ] Phase 10 — Pre-Launch (spec Phase 10)
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
| 20260311000001_phase5_increment_words_procedure | ✓ applied | ✓ applied 2026-03-12 | not yet |
| 20260314000001_add_rewarded_ad_transaction_type | pending Docker | pending Adam approval | not yet |

---

## Open PRs

- **PR #24** (open) — "feat: Phase 6 — Analytics (Mixpanel + Supabase dual-write)" — targeting dev
- **PR #25** (open) — "feat: Phase 7 — Ads & Monetization (AdMob + RevenueCat + Shop)" — targeting dev

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

- [ ] **Level 32 multi-intersection** — Level 32 (boss) has SCARF pos 2 in two intersections. Geometrically valid; engine handles it. ✓ Confirmed fine in Phase 4 playtesting 2026-03-11.

- [ ] **Hint cost confirmed** — GameConstants.hintCost = 5. ✓ Phase 4 playtesting complete — 5 coins feels right.

- [ ] **Sign in with Apple** — Phase 8/9. — raised 2026-03-01
- [ ] **Sign in with Google** — Phase 8/9. — raised 2026-03-01
- [ ] **App name / codename** — Before Phase 8/10. — raised 2026-03-01
- [ ] **iOS build verification** — Requires Mac. — raised 2026-03-01

- [ ] **`first_try` achievement definition** — GDD §14 says "Submit correct word on first attempt 50 times total." Current implementation counts levels completed with `attempts_made === 1` (one board submission attempt). Clarify: is the intent (a) 50 levels completed on first board submit attempt, or (b) per-word-slot first-attempt success tracked separately? Option (a) is implemented. If (b), a new tracking field is required. — raised 2026-03-11

- [x] **Apply migration `20260311000001` to puzzle-game-dev** — Applied 2026-03-12 ✓

- [x] **Deploy Phase 5 Edge Functions to puzzle-game-dev** — `on-level-complete`, `on-hint-used`, `on-level-skip` deployed 2026-03-12 ✓

- [ ] **Phase 5 playtesting** — Full progression loop on physical device: start → earn coins → buy hint → complete bossLevel → check achievements screen. Required for Phase 5 DoD. — raised 2026-03-11
  - Use `bash scripts/run_dev_cloud.sh` (not run_dev.sh) — loads .env.dev with cloud URL
  - Watch debug console for `[SupabaseService]` and `[GameNotifier]` lines to pinpoint failure

- [ ] **Create `.env.dev`** — file with puzzle-game-dev credentials for `run_dev_cloud.sh`. Format: `SUPABASE_URL=https://xgqqpyehkmzyrtvqsofe.supabase.co` and `SUPABASE_ANON_KEY=<dev anon key>`. — raised 2026-03-12

- [ ] **Verify anonymous auth enabled in puzzle-game-dev** — Dashboard → Authentication → Providers → Anonymous → must be toggled ON. If off, signInAnonymously() fails and no profile is created. — raised 2026-03-12

- [ ] **Create Mixpanel account and get token** — Phase 6 analytics. Create project at mixpanel.com → copy project token → add `MIXPANEL_TOKEN=<token>` to `.env.task` and `.env.dev`. Events write to Supabase without token, but Mixpanel dashboard requires it. — raised 2026-03-13

- [ ] **Phase 6 verification** — After merging PR #24 and adding Mixpanel token, play through 3+ levels while watching Mixpanel Live View. Confirm: `app_open`, `level_start`, `word_submitted`, `level_complete` events appear within 5 seconds with correct properties. Also confirm `analytics_events` table in Supabase populating. — raised 2026-03-13

- [ ] **Review and merge PR #24** — Phase 6 analytics implementation. — raised 2026-03-13

- [ ] **Review and merge PR #25** — Phase 7 Ads & Monetization. — raised 2026-03-14

- [ ] **Create AdMob account** — admob.google.com → create iOS + Android apps → create `puzzle_game_interstitial` and `puzzle_game_rewarded` ad units → replace placeholder App IDs in `AndroidManifest.xml` (`ca-app-pub-3940256099942544~3347511713`) and `Info.plist` (`ca-app-pub-3940256099942544~1458002511`) with real IDs. Also update `.env.task` and `.env.dev` with real unit IDs for the four ADMOB_* vars. — raised 2026-03-14

- [ ] **Add REVENUECAT_KEY to env files** — Create RevenueCat project at app.revenuecat.com → copy API key → add `REVENUECAT_KEY=<key>` to `.env.task` and `.env.dev`. Then create coin bundle products (coins_500/$0.99, coins_1200/$1.99, coins_2500/$3.99, coins_6000/$7.99) in both App Store Connect and Google Play, then configure them in RevenueCat. — raised 2026-03-14

- [ ] **Set REVENUECAT_WEBHOOK_SECRET in Supabase** — Dashboard → Edge Functions → Secrets → add `REVENUECAT_WEBHOOK_SECRET=<secret from RevenueCat>`. Then in RevenueCat dashboard, add webhook URL: `https://xgqqpyehkmzyrtvqsofe.supabase.co/functions/v1/on-iap-purchase`. — raised 2026-03-14

- [ ] **Apply migration 20260314000001 to local DB** — Start Docker → `supabase start` → `supabase db push --local`. Then confirm applies to puzzle-game-dev (pending Adam approval). — raised 2026-03-14

- [ ] **Deploy on-rewarded-ad and on-iap-purchase Edge Functions to puzzle-game-dev** — After PR #25 merges and migration applied. Commands: `SUPABASE_ACCESS_TOKEN=<token> supabase functions deploy on-rewarded-ad --project-ref xgqqpyehkmzyrtvqsofe` and same for `on-iap-purchase`. — raised 2026-03-14

- [ ] **Phase 7 verification** — After real AdMob IDs are set, test on physical device: (1) complete 4–5 levels and confirm interstitial appears; (2) tap "Watch Ad" on level-complete screen and confirm 15 coins awarded; (3) tap "Watch Ad" on shop screen and confirm 30 coins awarded; (4) purchase a coin bundle in sandbox and confirm paying user flag suppresses future interstitials. — raised 2026-03-14

---

## Phase 4 Definition of Done Checklist

- [x] All 50 hand-crafted levels playable end-to-end — confirmed 2026-03-11 (S8+ + emulator)
- [x] Drag mechanic smooth at 60fps on physical device — confirmed 2026-03-11
- [x] Both feedback states working correctly (red/amber) with correct messages — code + tests ✓
- [x] Level complete screen working with correct star rating — code + tests ✓
- [x] Back button with confirmation works (PopScope) — code ✓
- [x] Playtest of all 50 levels complete — confirmed 2026-03-11
- [ ] No crashes in Sentry during playtesting session — Sentry not yet integrated (Phase 8)

---

## Phase 5 Definition of Done Checklist

- [x] Coin economy working end-to-end (earn, spend, persist) — Edge Functions + Flutter wired
- [x] Hints working with correct coin deduction and tile highlighting — code ✓
- [x] Skips working with correct coin deduction — code ✓; guards against overwriting earned stars ✓
- [x] World map shows real progress (50 level grid, locked/available/completed/boss states)
- [x] All 20 achievements listed in achievements screen
- [x] 19/20 achievement triggers implemented (vault_dweller deferred to Phase 7)
- [x] Streaks tracking correctly across sessions — on-level-complete Edge Function ✓
- [ ] Full playtest of progression loop — TODO MAS raised
- [ ] No coin duplication bugs (idempotency confirmed) — code ✓; requires device verification

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
| 2026-03-05 | Phase 4 tile-placement redesign — crossword grid, drag-and-drop, tile pool fix | task/phase4-tile-placement | PR #15 merged. 153/153 tests. |
| 2026-03-10 | Fix runtime validation — category lists, answer words, failure reasons | task/fix-validation-runtime | PR #16 merged. 162/162 tests. |
| 2026-03-10 | Grid coordinates for all 50 puzzles; fix boss triangle layouts | task/add-grid-coords-all-puzzles | PR #17 merged. 213/213 tests. |
| 2026-03-10 | Swap tile placement (grid-to-grid swap mechanic) | task/swap-tile-placement | PR #18 merged. |
| 2026-03-11 | Phase 5 economy & progression — Edge Functions, coin HUD, hints, skips, world map, achievements | task/phase5-economy-progression | PR #19 merged. 222/222 tests. |
| 2026-03-12 | Fix Phase 5 backend persistence — error logging, cloud run script | task/fix-phase5-backend-persistence | PR #20 merged. 222/222 tests. |
| 2026-03-13 | Phase 6 — Analytics (AnalyticsService, Mixpanel init, all 12 wired call sites) | task/phase6-analytics | PR #24 open. 222/222 tests. |
| 2026-03-14 | Phase 7 — Ads & Monetization (AdMob, RevenueCat, Shop screen, 2 Edge Functions) | task/phase7-ads-monetization | PR #25 open. 237/237 tests. |
