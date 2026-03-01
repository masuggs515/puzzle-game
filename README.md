# Puzzle Game

A word and logic puzzle mobile game built with Flutter and Supabase.

Players drag and connect letters to form words that satisfy logical constraints. Words intersect at shared letters, meaning solving one word directly influences what's available for the next — combining the accessibility of word games with the satisfaction of logic puzzles.

**Target platform:** iOS and Android (single Flutter codebase)
**Status:** Phase 1 — Project Setup

---

## How to Run

Requires Flutter 3.41+, Dart 3.11+, and credentials in `.env.task`.

```bash
bash scripts/run_dev.sh
```

See `specs/master-development-plan.md` for the full setup guide (Pre-Phase Setup, Steps 1–17).

---

## Project Structure

```
lib/
  main.dart                    # Entry point — Supabase + Sentry init
  app.dart                     # MaterialApp + GoRouter
  core/
    config/                    # Env vars, feature flags
    constants/                 # Game values, asset paths
    theme/                     # Colors, typography
  data/
    models/                    # Dart data models
    repositories/              # Data access layer
    services/                  # Supabase, RevenueCat, Sentry, OneSignal
  features/
    auth/                      # Splash, sign-in, sign-up
    home/                      # Hello-world / home screen
    game/                      # Game screen, drag mechanic (Phase 4)
    world_map/                 # World map (Phase 4)
    shop/                      # Coin shop (Phase 9)
  puzzle_engine/               # Standalone Dart module — no Flutter deps
    constraints/               # Constraint library (Tiers 1–5)
    solver/                    # CSP solver (AC-3 + backtracking)
    generation/                # Pre-gen CLI + runtime vault generator
supabase/
  migrations/                  # All schema changes — version controlled
  functions/                   # Edge Functions
assets/
  puzzles/                     # Bundled level JSON (levels 1–200)
  word_lists/                  # Answer and guess word lists
scripts/
  run_dev.sh                   # Local development runner
specs/
  master-development-plan.md   # All phases, timelines, definitions of done
  manager-agent-spec.md        # How the Manager Agent works
  game-design-document.md      # Product decisions, economy, constraints
  flutter-agent-spec.md        # All UI specs
  supabase-agent-spec.md       # Database schema, RLS, Edge Functions
  puzzle-generation-agent-spec.md
  analytics-agent-spec.md
  level-design-agent-spec.md
  review-agent-spec.md
  testing-agent-spec.md
  project-state.md             # Current phase, open PRs, TODO MAS items
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI framework | Flutter 3.41+ / Flame |
| State management | flutter_riverpod |
| Navigation | go_router |
| Backend | Supabase (PostgreSQL + Edge Functions + Auth) |
| Analytics | Mixpanel |
| Crash reporting | Sentry |
| Monetization | RevenueCat (IAP) |
| Push notifications | OneSignal |

---

## Development Workflow

1. Adam gives a task to the Manager Agent in plain English
2. Manager Agent cuts a `task/*` branch, does the work, opens a PR to `dev`
3. Adam reviews and merges the PR
4. Manager Agent runs the Review Agent checklist internally before every commit
5. Nothing reaches `main` without Adam's explicit approval

All database work stays on a local Supabase instance during task branch development. No cloud migrations happen without explicit `TODO MAS` confirmation from Adam.

---

## Environment Variables

Injected at build time via `--dart-define`. Never hardcoded. See `.env.task` (gitignored).

```
SUPABASE_URL
SUPABASE_ANON_KEY
MIXPANEL_TOKEN
SENTRY_DSN
REVENUECAT_KEY
ONESIGNAL_APP_ID
```

---

## Branch Structure

| Branch | Purpose |
|---|---|
| `main` | Production — updated only via Adam-approved PR |
| `dev` | Integration branch — all finished task branches land here |
| `task/*` | One branch per task — cut from dev, PR back to dev |
