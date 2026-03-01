# Master Development Plan
**Project:** Word/Logic Puzzle Game (codename TBD)  
**Document Version:** 0.2  
**Last Updated:** February 2026

---

## Agent Convention — TODO MAS

**Every agent working on this project must follow this rule without exception:**

Any time an agent needs human input, a decision, a credential, an account, a review, or flags anything uncertain — it must leave a comment in the relevant file and in its session summary formatted exactly as:

```
// TODO MAS: [clear description of what is needed and why]
```

In Dart/Flutter files use `//`. In SQL/Edge Function files use `--`. In JSON use a separate `_todos` key. In markdown use `> TODO MAS:`.

Agents must never block or stall silently. If something requires Adam, leave a TODO MAS and continue with everything else that doesn't require it. At the end of every session, agents must print a consolidated list of all TODO MAS items they left during that session so Adam can action them in one pass.

Adam reviews TODO MAS comments each day before the next agent session begins.

---

## Pre-Phase Setup — Your Personal TODO MAS List

Complete every item below before touching Claude Code. These are all browser or installer actions — no coding required yet. Do them in order. Each step tells you exactly what to do, what you are looking for, and where to save anything important.

> **Before you start:** Open a plain text file on your computer called `credentials.txt` and save it somewhere private (not in the project folder). Every time a step tells you to "save" something, paste it into this file with a label. You will paste these into the project later. Never share this file or commit it to Git.

---

### Step 1 — Install VS Code (your code editor)

VS Code is the application you will use to read code, review what the agents built, and run the terminal. Think of it as the window into your project.

- [ ] Go to **code.visualstudio.com**
- [ ] Click the big blue download button — it will detect your operating system automatically
- [ ] Open the downloaded file and follow the installer
- [ ] When asked about "Add to PATH" — make sure this is **checked**. It is usually checked by default.
- [ ] Open VS Code after installing. You should see a welcome screen. That is all you need for now.

---

### Step 2 — Install Node.js (required for Claude Code)

Node.js is a tool that lets you run developer software from the terminal, including Claude Code. You are not writing Node.js code — it just needs to be installed.

- [ ] Go to **nodejs.org**
- [ ] Click the button labelled **LTS** (Long Term Support) — not "Current". LTS is more stable.
- [ ] Open the downloaded file and follow the installer. Accept all defaults.
- [ ] To verify it worked: open VS Code, go to the top menu, click Terminal, then New Terminal. A panel will appear at the bottom of VS Code. Type `node --version` and press Enter.
- [ ] You should see something like `v20.11.0`. Any version number means it worked. If you see an error, restart VS Code and try again.

---

### Step 3 — Install the Flutter SDK (the mobile app framework)

Flutter is what the app is built with. Installing it lets Claude Code create, build, and test the app on your machine.

- [ ] Go to **flutter.dev/docs/get-started/install**
- [ ] Click your operating system (Windows, macOS, or Linux)
- [ ] Follow the instructions on that page step by step — Flutter's official guide is thorough
- [ ] **macOS users:** you will likely run a few commands in the terminal. Copy and paste them exactly from the Flutter site. You may also need to install Xcode from the Mac App Store — the guide will tell you if so.
- [ ] **Windows users:** you will download a zip file. The guide tells you exactly where to put it.
- [ ] When the guide tells you to run `flutter doctor` — do it in the VS Code terminal. It will show a list of items with checkmarks or X marks. The ones that must be green before continuing:
  - Flutter — must be green
  - Android toolchain — must be green
  - Xcode (macOS only) — must be green
  - Everything else can be yellow for now
- [ ] If `flutter doctor` shows errors you cannot fix, paste the full output into a new Claude.ai chat and ask for help. This is completely normal — almost everyone needs to fix one or two things.

---

### Step 4 — Subscribe to Claude Pro (your AI agent)

Claude Pro gives you access to Claude Code, which is the agent that does the building.

- [ ] Go to **claude.ai**
- [ ] Create an account or sign in if you already have one
- [ ] Go to Settings and find the Plans section
- [ ] Subscribe to **Pro** ($20/month)
- [ ] Claude Code is included in Pro — you do not need to purchase anything extra

---

### Step 5 — Install Claude Code (the agent that does the work)

Claude Code runs in your terminal and is how you communicate with the Manager Agent.

- [ ] Open VS Code
- [ ] Open the terminal (Terminal menu at the top → New Terminal)
- [ ] Type the following exactly and press Enter:
  ```
  npm install -g @anthropic-ai/claude-code
  ```
- [ ] A lot of text will scroll past — this is normal. Wait for it to finish.
- [ ] Type `claude --version` and press Enter to verify. You should see a version number.

---

### Step 6 — Install the GitHub CLI (lets Claude Code open pull requests)

The GitHub CLI lets Claude Code create pull requests from the terminal so you can review and approve changes before they are merged.

- [ ] Go to **cli.github.com**
- [ ] Click Download and follow the installer for your operating system
- [ ] After installing, open the VS Code terminal and type:
  ```
  gh auth login
  ```
- [ ] Answer the questions it asks:
  - Where do you use GitHub? Choose **GitHub.com**
  - How would you like to authenticate? Choose **Login with a web browser**
- [ ] It will display a short code. Copy it. Press Enter. Your browser will open — paste the code and confirm.
- [ ] Back in the terminal you should see "Logged in as [your username]". Done.

---

### Step 7 — Create your GitHub repository (version control)

GitHub stores every version of your code so nothing is ever lost and every change is tracked and reviewable.

- [ ] Go to **github.com** and sign in (or create a free account)
- [ ] Click the **+** icon in the top right corner → **New repository**
- [ ] Fill in:
  - Repository name: `puzzle-game`
  - Description: `Word logic puzzle mobile game`
  - Visibility: **Private**
  - Leave "Add a README file" unticked — leave everything else default
- [ ] Click **Create repository**
- [ ] You will land on a page showing your empty repository. The URL in your browser will look like `https://github.com/yourusername/puzzle-game`
- [ ] Save that URL into `credentials.txt` labelled "GitHub repo URL"

---

### Step 8 — Create your project folder and save the spec documents

This is where all your code will live on your computer.

- [ ] Open VS Code
- [ ] Go to File → Open Folder
- [ ] Navigate somewhere you are comfortable (Documents is fine)
- [ ] Create a new folder called `puzzle-game` and open it
- [ ] Inside that folder, create another folder called `specs`
- [ ] Download every spec document from this Claude.ai conversation and save them into the `specs` folder. The files you need are:
  - `master-development-plan.md`
  - `game-design-document.md`
  - `supabase-agent-spec.md`
  - `puzzle-generation-agent-spec.md`
  - `flutter-agent-spec.md`
  - `analytics-agent-spec.md`
  - `level-design-agent-spec.md`
  - `manager-agent-spec.md`
  - `review-agent-spec.md`
  - `testing-agent-spec.md`
- [ ] Check: in VS Code's left sidebar you should see a `specs` folder with all 10 files inside it

---

### Step 9 — Create your Supabase account and two cloud projects (your database)

Supabase is the database and backend that stores all player data — coin balances, progress, accounts, and everything else. You need three completely separate projects for three different environments. The free tier covers all three.

- [ ] Go to **supabase.com** and click **Start your project** to create a free account
- [ ] Once logged in, click **New project**

**Create Project 1 — pre-production (dev):**
- [ ] Organisation: choose the default one Supabase created for you
- [ ] Name: `puzzle-game-dev`
- [ ] Database password: create a strong password. Save it in `credentials.txt` as "Supabase dev DB password"
- [ ] Region: choose the region closest to you geographically
- [ ] Click **Create new project** and wait about 2 minutes
- [ ] When it finishes loading, click the **gear icon** (Settings) at the bottom of the left sidebar → then click **API**
- [ ] You will see three values. Save all of them into `credentials.txt`:
  - "Project URL" → save as "Supabase dev URL"
  - Under "Project API Keys", the "anon public" key → save as "Supabase dev anon key"
  - Under "Project API Keys", the "service_role secret" key → save as "Supabase dev service role key" — treat this like a password, never share it

**Create Project 2 — production:**
- [ ] Go back to the Supabase dashboard home (click the Supabase logo top left)
- [ ] Click **New project** again
- [ ] Name: `puzzle-game-prod`
- [ ] Same region, new password (save as "Supabase prod DB password")
- [ ] Save the URL, anon key, and service role key into `credentials.txt` with "prod" labels

> **Note:** You only need two cloud projects. Your task branch development uses a local database on your machine via Docker — no third cloud project needed.

---

### Step 10 — Enable anonymous sign-ins in both Supabase cloud projects

This allows players to start playing immediately without creating an account. Do this for both cloud projects — the local database handles it automatically.

For each of `puzzle-game-dev` and `puzzle-game-prod`:

- [ ] Open the project in the Supabase dashboard (click it from the main dashboard)
- [ ] Click **Authentication** in the left sidebar
- [ ] Click **Providers** in the sub-menu that appears
- [ ] Scroll down to find **Anonymous Sign-ins**
- [ ] Toggle the switch to **on** (it will turn green)
- [ ] Click **Save**
- [ ] Repeat for the other project

---

### Step 11 — Create your Mixpanel account (analytics)

Mixpanel tracks how players use the app — which levels they complete, where they get stuck, how often they use hints. The free tier handles up to 1 million events per month, which is plenty for launch.

- [ ] Go to **mixpanel.com** and click **Get started free**
- [ ] Create an account
- [ ] When prompted to create a project, name it `puzzle-game`
- [ ] After the project is created, click the **gear icon** (Settings) in the bottom left → **Project Settings**
- [ ] Find **Project Token** (it is a short string of letters and numbers)
- [ ] Save it into `credentials.txt` as "Mixpanel project token"

---

### Step 12 — Create your Sentry account (crash reporting)

Sentry alerts you when the app crashes and tells you exactly what went wrong and where. The free tier is plenty for development and early launch.

- [ ] Go to **sentry.io** and click **Get started**
- [ ] Create a free account
- [ ] Click **Create Project**
- [ ] In the list of platforms, choose **Flutter**
- [ ] Name the project `puzzle-game`
- [ ] After creating, Sentry will display your DSN. It looks like a URL: `https://abc123@o123456.ingest.sentry.io/789`
- [ ] Save it into `credentials.txt` as "Sentry DSN"

---

### Step 13 — Install Docker Desktop (runs your local database)

Docker is what runs Supabase on your machine during development. Every task branch uses a local database instead of a cloud one, keeping your cloud projects clean and your costs at zero.

- [ ] Go to **docker.com/get-started**
- [ ] Click **Download Docker Desktop for Windows**
- [ ] Run the installer and accept all defaults
- [ ] When asked about WSL 2 — click **Yes**. This is required for Docker on Windows.
- [ ] Restart your computer when prompted
- [ ] After restart, open **Docker Desktop** from the Start menu
- [ ] If it says "WSL needs updating" — open your VS Code terminal and run:
  ```
  wsl --update
  ```
  Then click **Try Again** in Docker Desktop
- [ ] Wait until the bottom left shows a green light and says **"Engine running"**
- [ ] You do not need a Docker account — click **Skip** if it asks you to sign in

> **Important habit:** Docker Desktop must be running before every Claude Code session. Open it first, wait for the green light, then open VS Code. If Docker isn't running, the local database won't start and the Manager Agent will hit errors.

---

### Step 14 — Install the Supabase CLI (manages your local and cloud databases)

The Supabase CLI is what the Manager Agent uses to create migrations, run the local database, and push schema changes to your cloud projects.

- [ ] Go to **github.com/supabase/cli/releases/latest**
- [ ] Scroll down to **Assets**
- [ ] Download the file ending in `windows-amd64.exe`
- [ ] Rename the downloaded file to `supabase.exe`
- [ ] Move it to `C:\Windows\System32`
- [ ] Open a new terminal in VS Code and verify:
  ```
  supabase --version
  ```
- [ ] You should see a version number like `2.75.0`

---

### Step 15 — Optionally install Windsurf (a better editor experience)

Windsurf is a code editor built specifically for AI-assisted development. It makes it easier to read and navigate what the agents build each day. It is not required — VS Code works perfectly fine — but if you find reviewing code feels overwhelming, Windsurf can help.

- [ ] If you want it: go to **codeium.com/windsurf** and subscribe to Pro ($15/month)
- [ ] Download and install Windsurf — it works just like VS Code and all the same steps apply
- [ ] You can switch to it at any time, even after starting development. Nothing in the project changes.

---

### Step 16 — Check your credentials file is complete

Before you start Claude Code, verify `credentials.txt` contains all of the following. If anything is missing, go back to the relevant step.

- [ ] GitHub repo URL
- [ ] Supabase dev URL, anon key, service role key, DB password
- [ ] Supabase prod URL, anon key, service role key, DB password
- [ ] Mixpanel project token
- [ ] Sentry DSN

> Note: You do not need Supabase credentials for the task environment — that runs locally on your machine and the Supabase CLI generates its own local keys automatically when you run `supabase start`.

---

### Step 17 — Start Claude Code for the first time

You are ready. From here the Manager Agent takes over. This is the last thing you do manually.

- [ ] Open VS Code (or Windsurf)
- [ ] Open the Terminal (Terminal menu → New Terminal)
- [ ] Navigate to your project folder by typing `cd` followed by the path. Examples:
  - macOS: `cd ~/Documents/puzzle-game`
  - Windows: `cd C:\Users\YourName\Documents\puzzle-game`
  - If you are unsure of the path, in VS Code go to File → Open Folder, open your puzzle-game folder, then open the terminal — it will automatically be in the right place
- [ ] Type `claude` and press Enter to start Claude Code
- [ ] When it loads and asks for input, paste this message exactly:

```
Read all files in the specs/ folder before doing anything else.
Then: we are starting Phase 1 — Project Setup. Create
specs/project-state.md to track project state, set up the git
repo structure, and begin Phase 1 work. You are the Manager Agent
— do the work directly, do not produce briefs for me to run.
Leave a TODO MAS for anything that genuinely needs my input.
Print all TODO MAS items at the end of the session.
```

The Manager Agent will read all specs, set up the repository, and at the end of the session print a TODO MAS list of anything it needs from you — likely your GitHub repo URL and credentials. Review that list, action each item, and you are underway.

---

### Step 18 — Set up branch protection in GitHub

**Do this after the Manager Agent completes its first session.** It will push the `main` and `dev` branches to GitHub during that session. Once it does, come back here.

- [ ] Go to your GitHub repository in your browser (the URL you saved in Step 7)
- [ ] Click **Settings** at the top of the repository page (not your account settings — the repo's own settings)
- [ ] Click **Branches** in the left sidebar
- [ ] Click **Add branch protection rule**
- [ ] In the "Branch name pattern" field, type `main` and set the following:
  - Tick: Require a pull request before merging
  - Tick: Require approvals, and set the number to **1**
  - Tick: Do not allow bypassing the above settings
  - Click **Create**
- [ ] Click **Add branch protection rule** again
- [ ] In the "Branch name pattern" field, type `dev` and set:
  - Tick: Require a pull request before merging
  - Tick: Do not allow force pushes
  - Click **Create**

This means nothing can ever reach `dev` or `main` without going through a pull request that you review and approve. The agents cannot bypass this — it is enforced by GitHub itself.


---

## Overview

This document defines every development phase from initial setup to launch. Each phase has a clear goal, specific deliverables, and a definition of done. No phase begins until the prior phase's definition of done is fully met.

The guiding principle: **always have a runnable app**. From Phase 2 onward, you should be able to fire up the app on a device or simulator at any point and see real, working software — not just code.

---

## Agent Assignments

| Agent | Spec Document | Owns |
|---|---|---|
| **Manager Agent** | `manager-agent-spec.md` | Task routing, agent briefing, project state — your primary interface |
| Supabase Agent | `supabase-agent-spec.md` | Database, RLS, Edge Functions, Auth |
| Puzzle Generation Agent | `puzzle-generation-agent-spec.md` | Word lists, constraints, CSP solver, JSON output |
| Flutter Agent | `flutter-agent-spec.md` | All UI, game states, drag mechanic, client SDK |
| Analytics Agent | `analytics-agent-spec.md` | Mixpanel, event tracking, session management |
| Level Design Agent | `level-design-agent-spec.md` | 50 hand-crafted puzzles, bossLevel design |
| **Review Agent** | `review-agent-spec.md` | Post-session review, regression detection, Definition of Done sign-off |
| **Testing Agent** | `testing-agent-spec.md` | Test suite authorship, execution, coverage reporting |

**Workflow:** Give tasks to the Manager Agent in plain English. It routes to the correct specialist. After every specialist session run the Review Agent. Run the Testing Agent after any session that introduces new logic. Nothing moves to the next phase without Review Agent sign-off.

---

## Phase Overview

| Phase | Name | Goal | Who |
|---|---|---|---|
| 1 | Project Setup | Repo, tooling, all services connected, hello world running | Flutter + Supabase |
| 2 | Foundation | Auth, DB tables, player profile, app boots with real data | Flutter + Supabase |
| 3 | Puzzle Engine | Word lists, constraints, 50 puzzles generated | Puzzle Generation + Level Design |
| 4 | Core Game | Drag mechanic, game states, submit, feedback | Flutter |
| 5 | Economy & Progression | Coins, hints, skips, world map, level complete | Flutter + Supabase |
| 6 | Analytics | All events firing to Mixpanel and Supabase | Analytics |
| 7 | The Vault | Runtime generation, vault entry, vault world map | Flutter + Puzzle Generation |
| 8 | Polish | Animations, sound, accessibility, performance | Flutter |
| 9 | Monetization | RevenueCat, coin shop, IAP flow | Flutter + Supabase |
| 10 | Pre-Launch | Testing, ASO, beta, submission | All |

---

## Phase 1 — Project Setup

**Goal:** Every tool and service is connected and a "hello world" app runs on a physical device or simulator.

**Duration estimate:** 3–5 days

---

### 1.1 Repository Setup (Flutter Agent)

- [ ] Initialize Flutter project: `flutter create puzzle_game`
- [ ] Set up project directory structure per `flutter-agent-spec.md`
- [ ] Initialize Git repository
- [ ] Create `.gitignore` — exclude `.env` files, build outputs, secrets
- [ ] Create `README.md` with project overview
- [ ] Add all dependencies to `pubspec.yaml`:
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    flame: latest
    supabase_flutter: latest
    flutter_riverpod: latest
    riverpod_annotation: latest
    go_router: latest
    mixpanel_flutter: latest
    purchases_flutter: latest  # RevenueCat
    onesignal_flutter: latest
    sentry_flutter: latest
    shared_preferences: latest
    flutter_animate: latest
    uuid: latest
  
  dev_dependencies:
    build_runner: latest
    riverpod_generator: latest
    flutter_test:
      sdk: flutter
  ```
- [ ] Run `flutter pub get`
- [ ] Verify project builds with no errors: `flutter build apk` and `flutter build ios`

---

### 1.2 Supabase Project Setup (Supabase Agent)

- [ ] Confirm both Supabase cloud projects exist: `puzzle-game-dev` and `puzzle-game-prod` (created in pre-phase setup)
- [ ] Install Supabase CLI: `npm install -g supabase`
- [ ] Initialize Supabase CLI in project: `supabase init`
- [ ] Link CLI to `puzzle-game-dev`: `supabase link --project-ref [dev-project-ref]`
- [ ] Note all credentials:
  - Project URL (dev)
  - Anon key (dev)
  - Service role key (dev) — store securely, never in code
  - Same for prod
- [ ] Enable anonymous sign-ins in Supabase Auth dashboard (both projects)
- [ ] Enable Apple OAuth provider (both projects)
- [ ] Enable Google OAuth provider (both projects)

---

### 1.3 Environment Configuration (Flutter Agent)

- [ ] Create `lib/core/config/env.dart` — reads environment variables using `--dart-define`
  ```dart
  class Env {
    static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    static const mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');
    static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  }
  ```
- [ ] Create `.env.development` with dev credentials (gitignored)
- [ ] Create `.env.production` with prod credentials (gitignored)
- [ ] Create VS Code launch configuration `launch.json` with dev env variables pre-filled
- [ ] Create run script `scripts/run_dev.sh`:
  ```bash
  flutter run \
    --dart-define=SUPABASE_URL=your_dev_url \
    --dart-define=SUPABASE_ANON_KEY=your_dev_key \
    --dart-define=MIXPANEL_TOKEN=your_token \
    --dart-define=SENTRY_DSN=your_dsn
  ```
- [ ] Verify secrets are NOT committed to Git: `git status` should never show `.env` files

---

### 1.4 Service Initialization (Flutter Agent)

- [ ] Create `lib/main.dart` with full initialization:
  ```dart
  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Sentry
    await SentryFlutter.init(
      (options) => options.dsn = Env.sentryDsn,
      appRunner: () => runApp(
        ProviderScope(child: const App()),
      ),
    );
    
    // Initialize Supabase
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    
    // Initialize Mixpanel
    await MixpanelAnalytics.instance.init(token: Env.mixpanelToken);
    
    // Initialize RevenueCat
    await Purchases.configure(PurchasesConfiguration(Env.revenueCatKey));
    
    // Initialize OneSignal
    OneSignal.initialize(Env.oneSignalAppId);
  }
  ```
- [ ] Verify: app launches without crashing
- [ ] Verify: no "missing key" errors in console

---

### 1.5 Hello World Screen (Flutter Agent)

- [ ] Create a minimal `HomeScreen` that displays:
  - App name (placeholder: "Puzzle Game")
  - "Hello World" text
  - Current Supabase connection status (connected / not connected)
  - Current auth status (guest / signed in / not authenticated)
- [ ] Verify app runs on:
  - [ ] iOS Simulator
  - [ ] Android Emulator
  - [ ] Physical iOS device (if available)
  - [ ] Physical Android device (if available)

---

### Phase 1 Definition of Done

- [ ] App launches on simulator and physical device without crashing
- [ ] Supabase connection confirmed (status shows "connected" in hello world screen)
- [ ] No secrets committed to Git
- [ ] All dependencies installed and resolving
- [ ] Both dev and prod Supabase projects created
- [ ] Build succeeds for both iOS and Android targets

---

## Phase 2 — Foundation

**Goal:** A player can launch the app, get an anonymous session automatically, and their profile exists in the database. The app shows real data from Supabase. You can fire up the app, see a home screen, and verify in the Supabase dashboard that a player_profiles row was created.

**Duration estimate:** 5–7 days

---

### 2.1 Database Schema (Supabase Agent)

Run all migrations in order against the dev Supabase project.

- [ ] Migration 001: Create enum types (`level_type`, `transaction_type`)
- [ ] Migration 002: Create `player_profiles` table
- [ ] Migration 003: Create `player_progress` table
- [ ] Migration 004: Create `coin_transactions` table
- [ ] Migration 005: Create `achievements` table
- [ ] Migration 006: Create `analytics_events` table
- [ ] Migration 007: Create `puzzles` table (empty for now — seeded in Phase 3)
- [ ] Migration 008: Apply all RLS policies per `supabase-agent-spec.md`
- [ ] Migration 009: Create all indexes
- [ ] Migration 010: Create stored procedures (`compute_coin_balance`, `migrate_anonymous_to_authenticated`)
- [ ] Migration 011: Create triggers (`update_updated_at`, `auto_enable_rls`)
- [ ] Verify: all tables visible in Supabase dashboard
- [ ] Verify: RLS enabled on all tables (green lock icon in dashboard)
- [ ] Verify: `compute_coin_balance` function runs without error in SQL editor

---

### 2.2 Auth Webhook — Auto Profile Creation (Supabase Agent)

- [ ] Deploy `create-player-profile` Edge Function
- [ ] Configure Auth webhook in Supabase dashboard: on `INSERT` to `auth.users`, trigger `create-player-profile`
- [ ] Test: create a test user manually in Supabase Auth dashboard → verify `player_profiles` row appears automatically
- [ ] Verify: anonymous sign-in creates a `player_profiles` row

---

### 2.3 Anonymous Session Flow (Flutter Agent)

- [ ] Create `lib/data/services/supabase_service.dart` per spec
- [ ] Create `lib/features/auth/providers/auth_provider.dart` (Riverpod)
- [ ] On app launch: call `supabaseService.ensureAnonymousSession()`
- [ ] Verify: anonymous session persists across app restarts (Supabase SDK handles this automatically)
- [ ] Verify in Supabase dashboard: `auth.users` table shows an anonymous user
- [ ] Verify in Supabase dashboard: `player_profiles` table shows a corresponding row

---

### 2.4 Player Profile Screen (Flutter Agent)

Replace the hello world screen with a real home screen that shows:

- [ ] "Welcome, Guest" (or display name if set)
- [ ] Current coin balance (fetched from `compute_coin_balance`)
- [ ] Current streak (fetched from `player_profiles`)
- [ ] Total words found (fetched from `player_profiles`)
- [ ] A placeholder "Start Game" button (not functional yet)
- [ ] A "Create Account" button that navigates to sign-up screen (not functional yet)

All data must come from real Supabase queries — no hardcoded values.

---

### 2.5 Sign Up / Sign In Screens (Flutter Agent)

Implement the full auth flow:

- [ ] `SignUpScreen` — email/password form + Sign in with Apple + Sign in with Google
- [ ] `SignInScreen` — returning player login
- [ ] On sign up: call `on-account-created` Edge Function to migrate anonymous data
- [ ] Deploy `on-account-created` Edge Function (Supabase Agent)
- [ ] Verify: creating an account preserves all guest data
- [ ] Verify: signing in on a "new" session restores all progress
- [ ] Error handling: network failure during sign-up shows friendly message

---

### 2.6 Cross-Device Sync Verification (Flutter Agent + Supabase Agent)

- [ ] Sign up with email on device A
- [ ] Complete some placeholder action that writes data (e.g. tap a "earn 10 coins" test button)
- [ ] Sign in on device B (or second simulator)
- [ ] Verify coin balance matches on device B
- [ ] Remove test button before Phase 3

---

### Phase 2 Definition of Done

- [ ] App launches and automatically creates an anonymous session
- [ ] `player_profiles` row visible in Supabase dashboard within 2 seconds of first launch
- [ ] Home screen shows real data from Supabase (coins, streak, words found — all 0 initially)
- [ ] Sign up creates an account and migrates anonymous data
- [ ] Sign in restores progress on a new device
- [ ] All RLS policies verified: logged in as user A cannot see user B's data
- [ ] No crashes, no unhandled exceptions in Sentry

---

## Phase 3 — Puzzle Engine

**Goal:** 50 hand-crafted puzzles exist as validated JSON. The puzzle generation engine runs offline and produces output. A debug screen in the app lets you load and display any puzzle (no game mechanic yet — just the data).

**Duration estimate:** 7–10 days

---

### 3.1 Word List Pipeline (Puzzle Generation Agent)

- [ ] Download SCOWL word list (size 60 for answers, size 80 for valid guesses)
- [ ] Download Google 20k common English words
- [ ] Implement `WordListFilter` per spec
- [ ] Generate and save `assets/word_lists/answer_words.txt` (~15,000 words)
- [ ] Generate and save `assets/word_lists/valid_guess_words.txt` (~50,000 words)
- [ ] Build all category lists in `assets/word_lists/category_lists/`
- [ ] Run tests: `dart test test/puzzle_engine/word_list_test.dart`
- [ ] All word list tests passing

---

### 3.2 Constraint Library (Puzzle Generation Agent)

- [ ] Implement all Tier 1 constraints (CategoryConstraint)
- [ ] Implement all Tier 2 constraints (letter rule constraints)
- [ ] Implement all Tier 3 constraints (wordplay)
- [ ] Implement all Tier 4 constraints (container/deletion)
- [ ] Build Tier 5 combined constraints dynamically
- [ ] Implement `ConstraintLibrary` registry
- [ ] Run tests: `dart test test/puzzle_engine/constraint_test.dart`
- [ ] All constraint tests passing
- [ ] Verify: every constraint has at least 10 valid answer words in the filtered list

---

### 3.3 CSP Solver (Puzzle Generation Agent)

- [ ] Implement `IntersectionStructure` builder
- [ ] Implement AC-3 arc consistency algorithm
- [ ] Implement backtracking search with MCV heuristic
- [ ] Implement MAC (Maintaining Arc Consistency)
- [ ] Implement `PuzzleValidator`
- [ ] Implement `PuzzleSerializer` (to/from JSON)
- [ ] Run tests: `dart test test/puzzle_engine/csp_solver_test.dart`
- [ ] All solver tests passing
- [ ] Performance verified: single puzzle generation under 2 seconds

---

### 3.4 Hand-Crafted Levels (Level Design Agent)

- [ ] Validate all 50 puzzles from `level-design-agent-spec.md` against the constraint library
- [ ] Fix any validation failures (designer notes flag some edge cases)
- [ ] Encode all 50 puzzles as JSON using `PuzzleSerializer`
- [ ] Add to `assets/puzzles/levels_001_200.json` (first 50 entries)
- [ ] Verify: every puzzle loads and deserializes correctly
- [ ] Verify: every puzzle has the documented valid solution

---

### 3.5 Pre-Generation CLI (Puzzle Generation Agent)

- [ ] Implement `DifficultyProfile.forLevel()` for levels 1–200
- [ ] Implement `PreGenerator` class
- [ ] Run CLI tool: `dart run tools/generate_puzzles.dart --output assets/puzzles/levels_001_200.json`
- [ ] Verify: 200 puzzles generated with no validation failures
- [ ] Verify: levels 1–50 match hand-crafted puzzles exactly (CLI uses those first)
- [ ] Seed puzzles into Supabase `puzzles` table via migration 013

---

### 3.6 Puzzle Debug Screen (Flutter Agent)

- [ ] Create a dev-only debug screen accessible from home screen (hidden in release builds)
- [ ] Lists all 200 puzzles with level number, type, intersection count
- [ ] Tap a puzzle → shows puzzle data as formatted JSON
- [ ] Shows: word slots, constraints, letter pool, intersections
- [ ] Does NOT show the solution (tests the player experience)
- [ ] Verify: all 200 puzzles load without errors

---

### Phase 3 Definition of Done

- [ ] `answer_words.txt` and `valid_guess_words.txt` exist and are correctly filtered
- [ ] All category lists populated
- [ ] All constraint tests passing (100% pass rate)
- [ ] All solver tests passing (100% pass rate)
- [ ] All 50 hand-crafted puzzles validated and serialized
- [ ] `levels_001_200.json` exists with 200 valid puzzles
- [ ] Puzzles seeded in Supabase `puzzles` table
- [ ] Debug screen loads all puzzles without errors
- [ ] Performance: puzzle load time under 500ms

---

## Phase 4 — Core Game

**Goal:** The full in-game experience works end-to-end. Player can drag letters, form words, submit, see feedback, complete a level. No coins, no progression — just the pure game mechanic working correctly on real puzzle data.

**Duration estimate:** 10–14 days

**This is the phase where you do your first real playtesting of the 50 levels.**

---

### 4.1 Flame Game Setup (Flutter Agent)

- [ ] Create `PuzzleGame` (FlameGame subclass)
- [ ] Implement `LetterTileComponent` with correct visual states (default, selected, locked, hinted)
- [ ] Implement `LetterPathComponent` — draws path between connected tiles in real time
- [ ] Implement drag detection: `onDragStart`, `onDragUpdate`, `onDragEnd`
- [ ] Verify: dragging finger across tiles highlights them in sequence
- [ ] Verify: 60fps maintained during drag on physical device

---

### 4.2 Game State Machine (Flutter Agent)

- [ ] Implement `GameState` model per spec
- [ ] Implement `GameNotifier` (Riverpod) per spec
- [ ] All `GamePhase` states implemented with correct transitions
- [ ] Verify: state changes trigger correct visual updates via Riverpod watch

---

### 4.3 Word Validation (Flutter Agent)

- [ ] Load `valid_guess_words.txt` into memory as a `Set<String>` on app start
- [ ] Implement dictionary validation (client-side, from loaded word set)
- [ ] Implement constraint validation (calls constraint library)
- [ ] Implement intersection validation
- [ ] Verify: correct word → `feedbackCorrect` state
- [ ] Verify: non-dictionary word → `feedbackWrongWord` state with correct message
- [ ] Verify: valid word, wrong constraint → `feedbackWrongConstraint` state with constraint name

---

### 4.4 Submit Button & Feedback UI (Flutter Agent)

- [ ] Implement `SubmitButton` widget
- [ ] Implement `FeedbackOverlay` widget
  - Red overlay + message for wrong word
  - Amber overlay + message for wrong constraint (includes constraint text)
  - Green flash for correct word
- [ ] Feedback auto-clears after 2 seconds
- [ ] Feedback message is readable, non-technical, friendly
- [ ] Verify: wrong word → red feedback → path resets → player can try again
- [ ] Verify: wrong constraint → amber feedback with specific constraint mentioned

---

### 4.5 Level Complete Flow (Flutter Agent)

- [ ] Implement `LevelCompleteScreen` per spec
- [ ] Show "Level XX Complete" header
- [ ] Show star rating (1–3 stars) based on hints used (no hints yet — always 3 stars in Phase 4)
- [ ] "Continue" button → load next level
- [ ] "Home" button → navigate to home screen
- [ ] Verify: completing all words triggers level complete after short delay

---

### 4.6 Game Screen (Flutter Agent)

- [ ] Implement `GameScreen` (wrapper around `PuzzleGame` + HUD)
- [ ] HUD shows: level number, placeholder coin balance (0)
- [ ] Implement back button with "Leave puzzle?" confirmation dialog
- [ ] Constraint labels display correctly for each word slot
- [ ] Letter pool displays correctly with all available letters
- [ ] Verify: navigating to `/game/1` loads and displays Level 1 correctly

---

### 4.7 Playtest Levels 1–50 (Manual Testing)

Play every level. For each level record:
- [ ] Does the level load correctly?
- [ ] Is the constraint text clear and unambiguous?
- [ ] Is the letter pool correct (no missing letters, correct decoy count)?
- [ ] Does the valid solution work (can be submitted successfully)?
- [ ] Does the difficulty feel appropriate for the level number?
- [ ] Does the level complete flow trigger correctly?
- [ ] Any bugs, edge cases, or confusing moments?

Document all findings. Fix before Phase 5.

---

### Phase 4 Definition of Done

- [ ] All 50 hand-crafted levels playable end-to-end
- [ ] Drag mechanic smooth at 60fps on physical device
- [ ] Both feedback states working correctly (red/amber) with correct messages
- [ ] Level complete screen working with correct star rating
- [ ] Back button with confirmation works
- [ ] Playtest of all 50 levels complete, all issues documented and resolved
- [ ] No crashes in Sentry during playtesting session

---

## Phase 5 — Economy & Progression

**Goal:** Coins are awarded and spent correctly. Hints and skips work. The world map shows real progress. Achievements and streaks track correctly. The full progression loop is playable.

**Duration estimate:** 7–10 days

---

### 5.1 Edge Functions — Economy (Supabase Agent)

- [ ] Deploy `on-level-complete` Edge Function
- [ ] Deploy `on-hint-used` Edge Function
- [ ] Deploy `on-level-skip` Edge Function
- [ ] Test each Edge Function manually using Supabase dashboard → Functions → test console
- [ ] Verify idempotency: calling `on-level-complete` twice with same key only awards coins once
- [ ] Verify: coin balance updates correctly in `player_profiles` via `compute_coin_balance`

---

### 5.2 Coin Integration (Flutter Agent)

- [ ] Connect `on-level-complete` Edge Function call to level complete flow
- [ ] Display coins earned on level complete screen with animation
- [ ] Display live coin balance in game HUD (reads from Supabase)
- [ ] Verify: completing Level 1 (standard) awards 10 coins
- [ ] Verify: completing a bossLevel awards 20 coins
- [ ] Verify: coin balance persists across app restarts

---

### 5.3 Hints (Flutter Agent)

- [ ] Implement `HintButton` in game HUD (shows coin cost)
- [ ] Connect to `on-hint-used` Edge Function
- [ ] Implement hint tile highlighting in `LetterTileComponent`
- [ ] Show constraint reminder text when hint is active
- [ ] Verify: requesting hint when balance < cost shows "insufficient coins" message
- [ ] Verify: hint highlights correct tiles without revealing full answer
- [ ] Verify: hint deducts correct coin amount

---

### 5.4 Skips (Flutter Agent)

- [ ] Implement skip button in game HUD (shows 50 coin cost)
- [ ] Connect to `on-level-skip` Edge Function
- [ ] Skipped level marked as complete with stars = 0 in progress
- [ ] Verify: skip deducts 50 coins
- [ ] Verify: skip is blocked if balance < 50

---

### 5.5 World Map (Flutter Agent)

- [ ] Implement `WorldMapGrid` with real progress data from Supabase
- [ ] Level nodes show correct state: locked, available, completed (with star count), bossLevel
- [ ] bossLevel nodes have distinct visual treatment (gold color, special icon placeholder)
- [ ] Tapping completed level shows completion stats
- [ ] Tapping available level → navigates to game screen
- [ ] Verify: completing Level 1 unlocks Level 2 on world map
- [ ] Verify: world map reflects actual progress from Supabase (not local state)

---

### 5.6 Achievements (Supabase Agent + Flutter Agent)

- [ ] Implement all achievement triggers in `on-level-complete` Edge Function
- [ ] Implement `AchievementsScreen`
- [ ] Achievement unlock banners appear on level complete screen
- [ ] Verify: "First Word" achievement unlocks on first level completion
- [ ] Verify: "Word Collector" unlocks at 100 total words
- [ ] Verify: "Boss Slayer" unlocks on first bossLevel completion
- [ ] Verify: achievements persist across devices

---

### 5.7 Streaks (Supabase Agent + Flutter Agent)

- [ ] Streak logic implemented in `on-level-complete` Edge Function
- [ ] Streak display in home screen header
- [ ] Verify: completing a level increments streak
- [ ] Verify: playing on consecutive days maintains streak
- [ ] Verify: missing a day resets streak to 1
- [ ] Verify: `longest_streak` updates correctly

---

### Phase 5 Definition of Done

- [ ] Coin economy working end-to-end (earn, spend, persist)
- [ ] Hints working with correct coin deduction and tile highlighting
- [ ] Skips working with correct coin deduction
- [ ] World map shows real progress
- [ ] All 20 achievements triggering correctly
- [ ] Streaks tracking correctly across sessions
- [ ] Full playtest of progression loop: start → earn coins → buy hint → complete bossLevel → check achievements
- [ ] No coin duplication bugs (idempotency confirmed)

---

## Phase 6 — Analytics

**Goal:** Every defined analytics event fires correctly to both Mixpanel and Supabase. The Mixpanel dashboard shows real data from playtesting sessions.

**Duration estimate:** 3–5 days

---

### 6.1 Analytics Service (Analytics Agent)

- [ ] Implement `AnalyticsService` per `analytics-agent-spec.md`
- [ ] Implement session management (30-minute timeout)
- [ ] Implement user identity (anonymous + authenticated)
- [ ] Implement all 16 event tracking methods

---

### 6.2 Event Integration (Analytics Agent + Flutter Agent)

Wire every event to its call site per the Call Site Reference in `analytics-agent-spec.md`:

- [ ] `app_open` — fires on app resume
- [ ] `level_start` — fires when puzzle loads
- [ ] `word_submitted` — fires on every submit attempt
- [ ] `hint_used` — fires on successful hint
- [ ] `level_complete` — fires on Edge Function success
- [ ] `level_abandoned` — fires on back button "Leave" confirm
- [ ] `level_skip` — fires on successful skip
- [ ] `vault_entered` — fires on first vault entry
- [ ] `achievement_unlocked` — fires for each achievement on level complete screen
- [ ] `streak_updated` — fires when streak changes
- [ ] `coin_transaction` — fires after every Edge Function returning new_balance
- [ ] `iap_purchase` — fires on RevenueCat purchase (Phase 9)
- [ ] `account_created` — fires on successful sign up
- [ ] `sign_in` — fires on successful sign in
- [ ] `shop_viewed` — fires on shop screen open (Phase 9)
- [ ] `settings_changed` — fires on any setting change

---

### 6.3 Verification (Analytics Agent)

- [ ] Play through 5 levels while monitoring Mixpanel Live View
- [ ] Verify all expected events appear in Mixpanel with correct properties
- [ ] Verify `word_submitted` does NOT include the actual word string (only `word_length`)
- [ ] Verify `analytics_events` table in Supabase populating correctly
- [ ] Verify no PII in Mixpanel events
- [ ] Build Level Funnel dashboard in Mixpanel
- [ ] Build Hint Usage dashboard in Mixpanel

---

### Phase 6 Definition of Done

- [ ] All 16 events firing with correct properties
- [ ] Events visible in Mixpanel Live View within 5 seconds of trigger
- [ ] Events visible in Supabase `analytics_events` table
- [ ] No PII in Mixpanel
- [ ] Level funnel dashboard shows data
- [ ] Hint usage dashboard shows data

---

## Phase 7 — The Vault

**Goal:** Players who complete Level 200 enter theVault and receive procedurally generated puzzles indefinitely.

**Duration estimate:** 5–7 days

---

### 7.1 Runtime Generator (Puzzle Generation Agent)

- [ ] Implement `RuntimeGenerator` per spec
- [ ] Verify: same userId + vaultLevel always produces same puzzle
- [ ] Verify: different vault levels produce different puzzles
- [ ] Verify: all generated puzzles pass validation
- [ ] Performance: runtime generation under 2 seconds on device

---

### 7.2 Vault Entry Flow (Flutter Agent)

- [ ] Implement `VaultScreen` with distinct visual identity
- [ ] Entry triggered after completing Level 200 (or latest hand-crafted level)
- [ ] "You've conquered the main game. Welcome to The Vault." entry moment
- [ ] Vault levels numbered Vault 1, Vault 2, etc.
- [ ] bossLevel pattern continues in vault (every ~10 vault levels)
- [ ] Infinite scroll — generate next batch as player scrolls

---

### 7.3 Update Re-routing (Flutter Agent)

- [ ] When new hand-crafted levels are added (e.g. 201–300), players in theVault are routed back to new hand-crafted content
- [ ] After completing new hand-crafted content, player returns to theVault
- [ ] Vault level number preserved — player resumes where they left off

---

### Phase 7 Definition of Done

- [ ] Runtime generator producing valid puzzles consistently
- [ ] Vault entry flow working end-to-end
- [ ] Update re-routing logic working
- [ ] Vault levels earning coins correctly (same economy as main game)
- [ ] Vault bossLevels triggering correctly

---

## Phase 8 — Polish

**Goal:** The game feels great. Animations are smooth. Sound is satisfying. The experience is accessible and performant on all target devices.

**Duration estimate:** 7–10 days

---

### 8.1 Animations (Flutter Agent)

- [ ] Tile connect animation: subtle scale pop on selection
- [ ] Correct word: tiles snap into place with satisfying animation
- [ ] Wrong word: tiles shake and reset (red tint)
- [ ] Wrong constraint: tiles shake and reset (amber tint)
- [ ] Level complete: stars fill in sequence, coins animate
- [ ] Achievement unlock: banner slides in from top
- [ ] bossLevel entry: subtle intensified visual treatment
- [ ] World map: locked level unlock animation on completion
- [ ] All animations use `flutter_animate` package
- [ ] All animations respect `MediaQuery.reducedMotion` for accessibility

---

### 8.2 Sound (Flutter Agent)

- [ ] Source/create audio files per `asset_paths.dart`:
  - `tile_connect.mp3` — soft tick (< 100ms)
  - `word_correct.mp3` — clean resolution tone
  - `word_wrong.mp3` — soft, non-harsh rejection
  - `level_complete.mp3` — satisfying completion sound
  - `boss_complete.mp3` — slightly more dramatic completion
- [ ] Implement sound on/off toggle in settings (saved in SharedPreferences)
- [ ] All sounds respect system volume
- [ ] Verify: sounds play correctly on both iOS and Android

---

### 8.3 Accessibility (Flutter Agent)

- [ ] All tap targets minimum 44x44 points
- [ ] All feedback messages wrapped in `Semantics` widgets for screen readers
- [ ] Color is never the only indicator (shapes and text accompany red/amber states)
- [ ] Font sizes respect system accessibility settings
- [ ] Verify: VoiceOver (iOS) and TalkBack (Android) can navigate the main screens

---

### 8.4 Performance (Flutter Agent)

- [ ] App cold start to interactive: under 2 seconds (measure on physical device)
- [ ] Drag mechanic: 60fps sustained (use Flutter DevTools Performance tab)
- [ ] Supabase reads: home screen loads in under 1 second on 4G
- [ ] Puzzle JSON load: under 500ms
- [ ] Fix any jank or frame drops identified in DevTools

---

### 8.5 Extended Playtesting (Manual)

- [ ] Full playthrough of levels 1–50 with sound and animations enabled
- [ ] Identify and fix any remaining UX friction points
- [ ] Test on low-end Android device (representative of lower-tier users)
- [ ] Test on older iOS device (iPhone X era)
- [ ] Test with slow network (throttle to 3G in simulator settings)

---

### Phase 8 Definition of Done

- [ ] All animations implemented and smooth (60fps)
- [ ] All sounds implemented and toggleable
- [ ] Accessibility requirements met
- [ ] Performance requirements met on physical device
- [ ] Extended playtest complete with no critical UX issues

---

## Phase 9 — Monetization

**Goal:** The coin shop works. Players can purchase coin bundles via IAP. AdMob interstitial and rewarded video ads are integrated with correct frequency capping. RevenueCat processes purchases correctly and awards coins. Paying players never see ads.

**Duration estimate:** 7–10 days

---

### 9.1 AdMob Setup (Flutter Agent)

AdMob is free — you earn money from impressions, you never pay anything.

- [ ] Create Google AdMob account at admob.google.com
- [ ] Create an AdMob app for iOS and a separate one for Android
- [ ] Create the following ad units in AdMob dashboard:
  - **Interstitial** — `puzzle_game_interstitial` (shown between levels)
  - **Rewarded Video** — `puzzle_game_rewarded` (watch ad to earn coins)
- [ ] Note all ad unit IDs (iOS and Android versions differ)
- [ ] Add `google_mobile_ads` Flutter package to `pubspec.yaml`
- [ ] Add AdMob App IDs to:
  - iOS: `Info.plist` → `GADApplicationIdentifier`
  - Android: `AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
- [ ] Initialize AdMob in `main.dart`:
  ```dart
  await MobileAds.instance.initialize();
  ```
- [ ] Configure App Tracking Transparency (ATT) for iOS:
  - Add `NSUserTrackingUsageDescription` to `Info.plist`
  - Request ATT permission on first launch before showing any ads
  - Use `app_tracking_transparency` Flutter package

---

### 9.2 Ad Frequency Logic (Flutter Agent)

**The rule:** Show an interstitial ad after every 4–5 levels completed. Never on a bossLevel completion (ruins the achievement moment). Never if the player is a paying user (has made any IAP purchase).

```dart
class AdFrequencyManager {
  static const int minLevelsBetweenAds = 4;
  static const int maxLevelsBetweenAds = 5;
  
  int _levelsSinceLastAd = 0;
  late int _nextAdThreshold;
  
  AdFrequencyManager() {
    _nextAdThreshold = _randomThreshold();
  }
  
  int _randomThreshold() {
    return minLevelsBetweenAds + 
           Random().nextInt(maxLevelsBetweenAds - minLevelsBetweenAds + 1);
  }
  
  bool shouldShowAd({
    required bool isBossLevel,
    required bool isPayingUser,
  }) {
    if (isPayingUser) return false;    // paying users never see ads
    if (isBossLevel) return false;     // never ruin a boss completion
    
    _levelsSinceLastAd++;
    
    if (_levelsSinceLastAd >= _nextAdThreshold) {
      _levelsSinceLastAd = 0;
      _nextAdThreshold = _randomThreshold(); // randomize next interval
      return true;
    }
    
    return false;
  }
}
```

The randomized 4–5 interval prevents players from predicting exactly when an ad will appear, which reduces preemptive session abandonment.

---

### 9.3 Interstitial Ad Integration (Flutter Agent)

Interstitial ads appear on the level complete screen, before navigating to the next level. The flow is:

```
Level complete → [if ad due] show interstitial → dismiss → continue to next level
Level complete → [if no ad due] continue directly to next level
```

Never block the level complete screen with an ad — show it as a transition between levels.

```dart
class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  
  // Ad unit IDs — use test IDs during development
  static const String _adUnitIdIos = 'ca-app-pub-xxxxx/xxxxx';
  static const String _adUnitIdAndroid = 'ca-app-pub-xxxxx/xxxxx';
  
  static String get adUnitId => 
      Platform.isIOS ? _adUnitIdIos : _adUnitIdAndroid;
  
  Future<void> loadAd() async {
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;
        },
        onAdFailedToLoad: (error) {
          _isAdReady = false;
          // Fail silently — never crash the game because an ad failed to load
        },
      ),
    );
  }
  
  Future<void> showAd({required VoidCallback onAdDismissed}) async {
    if (!_isAdReady || _interstitialAd == null) {
      onAdDismissed(); // no ad ready — proceed normally
      return;
    }
    
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isAdReady = false;
        loadAd(); // pre-load next ad immediately
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isAdReady = false;
        loadAd();
        onAdDismissed(); // fail gracefully
      },
    );
    
    await _interstitialAd!.show();
  }
}
```

**Pre-loading:** Always load the next ad immediately after showing one. This ensures the ad is ready when needed and minimizes the chance of a missed opportunity.

---

### 9.4 Rewarded Video Ad Integration (Flutter Agent)

Rewarded video ads are optional and player-initiated. The player watches an ad to earn bonus coins. Placement options:

- "Watch ad for 15 coins" button on the level complete screen
- "Watch ad for 5 coins" as an alternative to spending coins on a hint
- "Watch ad for 30 coins" on the shop screen as a free option

```dart
class RewardedAdService {
  RewardedAd? _rewardedAd;
  
  static const String _adUnitIdIos = 'ca-app-pub-xxxxx/xxxxx';
  static const String _adUnitIdAndroid = 'ca-app-pub-xxxxx/xxxxx';
  
  static String get adUnitId =>
      Platform.isIOS ? _adUnitIdIos : _adUnitIdAndroid;
  
  Future<void> loadAd() async {
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }
  
  Future<void> showAd({
    required int coinsToAward,
    required Function(int coins) onRewarded,
    required VoidCallback onDismissed,
  }) async {
    if (_rewardedAd == null) {
      onDismissed();
      return;
    }
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadAd();
        onDismissed();
      },
    );
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        // Award coins via Edge Function — same as any other coin transaction
        onRewarded(coinsToAward);
      },
    );
  }
}
```

**Important:** Coin awards from rewarded ads must go through the `on-rewarded-ad` Edge Function (see 9.6) — never awarded directly from the client. Same security model as all other coin transactions.

---

### 9.5 Paying User Ad Suppression (Flutter Agent)

Paying users never see ads. This is a critical trust signal — players who spend money should be rewarded with an ad-free experience immediately and permanently.

```dart
// In AdFrequencyManager and throughout ad decision logic
bool get isPayingUser {
  // Check RevenueCat customer info
  // Returns true if any IAP purchase has ever been made
  return ref.read(revenueCatProvider).hasActiveEntitlement;
}
```

- Any IAP coin bundle purchase → `isPayingUser = true` immediately
- All ad decision points check `isPayingUser` first
- This is also a conversion lever: "Buy any coin bundle to remove ads" is a natural upsell

---

### 9.6 Rewarded Ad Edge Function (Supabase Agent)

- [ ] Deploy `on-rewarded-ad` Edge Function
- [ ] Input: `{ user_id, ad_unit_id, coins_to_award, idempotency_key }`
- [ ] Validate: `coins_to_award` matches server-side config (not client-provided amount)
- [ ] Validate idempotency key — prevent double-award if callback fires twice
- [ ] INSERT positive coin transaction with `transaction_type = 'rewarded_ad'`
- [ ] Add `rewarded_ad` to `transaction_type` enum in Supabase schema

---

### 9.7 Analytics Updates (Analytics Agent)

Add two new ad-specific events:

**`interstitial_ad_shown`**
```dart
await _track('interstitial_ad_shown', {
  'level_number': levelNumber,
  'levels_since_last_ad': levelsSinceLastAd,
});
```

**`rewarded_ad_completed`**
```dart
await _track('rewarded_ad_completed', {
  'placement': placement, // 'level_complete', 'hint_alternative', 'shop'
  'coins_awarded': coinsAwarded,
  'coin_balance_after': coinBalanceAfter,
});
```

These let you track ad revenue correlation with retention — critical for understanding if your ad frequency is hurting engagement.

---

### 9.8 RevenueCat Setup

- [ ] Create RevenueCat account and project
- [ ] Connect iOS App Store Connect
- [ ] Connect Google Play Console
- [ ] Create coin bundle products:
  - `coins_500` — $0.99
  - `coins_1200` — $1.99
  - `coins_2500` — $3.99
  - `coins_6000` — $7.99
- [ ] Configure RevenueCat webhook → Supabase `on-iap-purchase` Edge Function
- [ ] Deploy `on-iap-purchase` Edge Function (Supabase Agent)

---

### 9.9 Shop Screen (Flutter Agent)

- [ ] Implement `ShopScreen` with two sections:
  - **Free coins:** "Watch an ad for 30 coins" (rewarded video)
  - **Coin bundles:** IAP options from RevenueCat
- [ ] Add "Buy coins to remove ads" messaging for non-paying users
- [ ] Paying users see shop without any ad mentions
- [ ] "Best value" indicator on highest coin-per-dollar bundle
- [ ] Handle purchase errors gracefully

---

### Phase 9 Definition of Done

- [ ] AdMob account created, ad units configured
- [ ] ATT permission prompt working on iOS
- [ ] Interstitial ads showing after every 4–5 levels (not bossLevels)
- [ ] Rewarded video available on level complete screen, hint button, shop
- [ ] Paying users (any IAP purchase) never see ads
- [ ] Coin awards from rewarded ads going through Edge Function
- [ ] All coin bundles configured in sandbox
- [ ] RevenueCat webhook triggering correctly
- [ ] Shop screen shows both free (ad) and paid (IAP) coin options
- [ ] Both ad formats tested with AdMob test ad unit IDs
- [ ] Ad analytics events firing correctly
- [ ] No crashes from failed ad loads

---

## Phase 10 — Pre-Launch

**Goal:** App is tested, submitted, and ready for public release.

**Duration estimate:** 14–21 days

---

### 10.1 Beta Testing

- [ ] Configure TestFlight (iOS) with internal testers (yourself + any others)
- [ ] Configure Google Play Internal Testing track
- [ ] Distribute to 5–10 external beta testers
- [ ] Collect feedback: difficulty curve, UX friction, bugs
- [ ] Fix critical bugs before submission
- [ ] Fix any level design issues identified by testers

---

### 10.2 App Store Assets

- [ ] App name (finalized from open decisions)
- [ ] App icon (1024x1024, no alpha)
- [ ] Screenshots (6.7" iPhone, 6.5" iPhone, 12.9" iPad — at minimum)
- [ ] App description (keyword-optimized per ASO research)
- [ ] Keywords field (100 characters)
- [ ] Privacy policy URL (required)
- [ ] Support URL

---

### 10.3 Google Play Assets

- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone, 7" tablet)
- [ ] Short description (80 characters)
- [ ] Full description (4000 characters)
- [ ] Content rating questionnaire

---

### 10.4 Pre-Submission Checklist

- [ ] Production Supabase project fully configured (schema, RLS, Edge Functions)
- [ ] Production environment variables set (not dev)
- [ ] Sentry configured for production
- [ ] Mixpanel production token configured
- [ ] RevenueCat production products configured
- [ ] Analytics events verified in production project
- [ ] All Sentry errors resolved or acknowledged
- [ ] App tested on iOS 15+ and Android 10+
- [ ] Privacy policy published at accessible URL
- [ ] GDPR/COPPA compliance reviewed (broad/family audience)
- [ ] App rating: 4+ (Apple) / Everyone (Google)

---

### 10.5 Submission

- [ ] Submit to App Store review (allow 1–3 business days)
- [ ] Submit to Google Play review (allow 1–3 business days)
- [ ] Monitor for review feedback
- [ ] Coordinate simultaneous release on both platforms

---

### Phase 10 Definition of Done

- [ ] App approved on App Store
- [ ] App approved on Google Play
- [ ] Live on both stores
- [ ] Monitoring: Sentry showing <1% crash rate
- [ ] Analytics: Mixpanel receiving real user events
- [ ] First day retention being tracked

---

## Summary Timeline

| Phase | Name | Estimated Duration | Cumulative |
|---|---|---|---|
| 1 | Project Setup | 3–5 days | Week 1 |
| 2 | Foundation | 5–7 days | Week 2–3 |
| 3 | Puzzle Engine | 7–10 days | Week 4–5 |
| 4 | Core Game | 10–14 days | Week 7–8 |
| 5 | Economy & Progression | 7–10 days | Week 9–10 |
| 6 | Analytics | 3–5 days | Week 11 |
| 7 | The Vault | 5–7 days | Week 12 |
| 8 | Polish | 7–10 days | Week 14 |
| 9 | Monetization | 5–7 days | Week 15–16 |
| 10 | Pre-Launch | 14–21 days | Month 5–6 |

**Target launch: Month 6–7** from project start.

---

## Open Decisions (from GDD)

These must be resolved before their relevant phase begins:

| Decision | Needed By | Notes |
|---|---|---|
| Game name | Phase 10 (App Store) | Affects ASO — do not rush |
| bossLevel visual icon | Phase 5 (World Map) | Placeholder acceptable in Phase 4 |
| theVault visual identity | Phase 7 | Placeholder acceptable in Phase 5 |
| Hint cost exact amount (5 or 10 coins) | Phase 5 | Decide based on Phase 4 playtesting |
| World theme final names | Phase 5 | Placeholder names in GDD are fine for dev |
| Ad strategy | ~~Phase 9~~ | RESOLVED: Interstitial every 4–5 levels, rewarded video optional, paying users ad-free |
| Star rating thresholds | Phase 5 | Confirm via Phase 4 playtesting |

---

*This is the master planning document. All phases must be executed in order. Definition of Done for each phase is non-negotiable before proceeding.*
