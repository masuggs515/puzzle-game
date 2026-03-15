# Flutter/Flame Agent Spec
**Project:** Intercept
**Agent Role:** Flutter/Flame specialist — owns all UI, game states, animations, drag mechanic, screen navigation, and Supabase SDK integration on the client side.  
**Document Version:** 0.1  
**Last Updated:** February 2026


---

## Agent Convention — TODO MAS

Any time you need human input, a decision, a credential, a review, or anything uncertain — leave a comment formatted exactly as:

```
// TODO MAS: [clear description of what is needed and why]
```

Use `//` in Dart/Flutter, `--` in SQL, `> TODO MAS:` in markdown. Never stall silently — leave a TODO MAS and keep working on everything else. At the end of your session, print a consolidated list of every TODO MAS you left so Adam can action them in one pass.

---

## Agent Context

You are a Flutter/Flame expert building the mobile client for a word/logic puzzle game. You own everything the player sees and touches. Your responsibilities are:

- All Flutter screens and navigation
- Drag-and-connect letter mechanic
- Game state management
- Animations and visual feedback
- Supabase SDK integration (reads only — all writes go through Edge Functions)
- RevenueCat SDK integration (IAP)
- OneSignal integration (push notifications)
- Sentry integration (crash reporting)
- Local puzzle JSON loading
- Coin balance display (computed from Supabase)

You do not write backend logic. You do not modify the Supabase schema. You do not touch the puzzle generation engine directly — you consume its output (JSON). When you need data written to the database, you call a Supabase Edge Function. Never write directly to coin_transactions, achievements, or analytics_events from Flutter.

---

## Tech Stack

| Tool | Version | Purpose |
|---|---|---|
| Flutter | Latest stable | UI framework |
| Flame | Latest stable | Game loop, drag mechanic |
| Supabase Flutter SDK | Latest stable | Auth, database reads, Edge Function calls |
| RevenueCat Flutter SDK | Latest stable | IAP and coin bundle purchases |
| OneSignal Flutter SDK | Latest stable | Push notifications |
| Sentry Flutter SDK | Latest stable | Crash reporting |
| flutter_riverpod | Latest stable | State management |
| go_router | Latest stable | Navigation |
| shared_preferences | Latest stable | Local settings (sound on/off, etc.) |
| flutter_animate | Latest stable | UI animations |

---

## Project Structure

```
lib/
  main.dart                         # app entry point, Supabase init, Sentry init
  app.dart                          # MaterialApp, GoRouter setup, theme
  
  core/
    constants/
      game_constants.dart           # hint cost, skip cost, coins per level, etc.
      asset_paths.dart              # all asset path strings
    theme/
      app_theme.dart                # colors, typography, spacing
      app_colors.dart               # color palette
    utils/
      seed_utils.dart               # seed generation for vault puzzles
      letter_pool_builder.dart      # builds letter pool per level
    
  data/
    models/
      puzzle_model.dart             # mirrors puzzle JSON structure
      player_profile_model.dart     # mirrors Supabase player_profiles
      achievement_model.dart        # achievement definitions + unlock state
      coin_transaction_model.dart   # coin transaction record
    repositories/
      puzzle_repository.dart        # loads puzzles from local JSON + Supabase
      player_repository.dart        # reads player data from Supabase
      coin_repository.dart          # reads coin balance from Supabase
      achievement_repository.dart   # reads achievements from Supabase
    services/
      supabase_service.dart         # Supabase client singleton, Edge Function calls
      revenuecat_service.dart       # IAP purchase handling
      onesignal_service.dart        # push notification setup
      sentry_service.dart           # error reporting
  
  features/
    auth/
      screens/
        splash_screen.dart          # checks auth state, routes to onboarding or home
        onboarding_screen.dart      # first launch experience
        sign_up_screen.dart         # account creation
        sign_in_screen.dart         # sign in
      providers/
        auth_provider.dart          # Riverpod auth state
    
    home/
      screens/
        home_screen.dart            # world map, coin balance, streak display
      widgets/
        world_map_grid.dart         # level grid with boss indicators
        level_node_widget.dart      # individual level node
        streak_banner.dart          # current streak display
        coin_balance_widget.dart    # coin balance display
      providers/
        home_provider.dart          # player progress, level unlock state
    
    game/
      screens/
        game_screen.dart            # main puzzle screen wrapper
      game/
        puzzle_game.dart            # Flame Game subclass
        components/
          letter_tile.dart          # draggable letter tile component
          word_slot.dart            # word slot component
          intersection_node.dart    # visual intersection indicator
          letter_path.dart          # drawn path between connected letters
          constraint_label.dart     # constraint text display
          letter_pool_display.dart  # available letters area
          submit_button.dart        # submit word button
          hint_button.dart          # hint button with coin cost
      widgets/
        game_hud.dart               # coins, level number, hint/skip buttons
        feedback_overlay.dart       # correct/wrong feedback messages
      providers/
        game_provider.dart          # full game state management
      models/
        game_state.dart             # all game state definitions
    
    level_complete/
      screens/
        level_complete_screen.dart  # post-level screen
      widgets/
        star_rating_widget.dart     # 1-3 star display
        coins_earned_widget.dart    # coins animation
    
    vault/
      screens/
        vault_screen.dart           # theVault entry/world map
      providers/
        vault_provider.dart         # vault level state
    
    achievements/
      screens/
        achievements_screen.dart    # all achievements list
      widgets/
        achievement_tile.dart       # single achievement row
      providers/
        achievements_provider.dart  # achievement unlock state
    
    shop/
      screens/
        shop_screen.dart            # coin bundle purchase screen
      providers/
        shop_provider.dart          # IAP products, purchase state
    
    settings/
      screens/
        settings_screen.dart        # sound, account, notifications
      providers/
        settings_provider.dart      # local settings state

assets/
  puzzles/
    levels_001_200.json             # pre-generated puzzles (from generation agent)
  word_lists/
    valid_guess_words.txt           # for client-side word validation
  fonts/
    [font files]
  images/
    [UI assets]
  audio/
    tile_connect.mp3                # letter tile connect sound
    word_correct.mp3                # correct word submit sound
    word_wrong.mp3                  # wrong word submit sound  
    level_complete.mp3              # level complete sound
    boss_complete.mp3               # boss level complete sound
```

---

## Game Constants

```dart
// lib/core/constants/game_constants.dart

class GameConstants {
  // Coin economy
  static const int coinsPerStandardLevel = 10;
  static const int coinsPerBossLevel = 20;
  static const int hintCost = 5;
  static const int skipCost = 50;
  
  // Letter pool transitions
  static const int decoyLettersIntroducedLevel = 25;
  static const int fullKeyboardLevel = 100;
  static const int decoyCountEarly = 2;    // levels 25–50
  static const int decoyCountMid = 4;      // levels 51–99
  
  // Validation
  static const int minWordLength = 3;
  static const int maxWordLength = 12;
  
  // Star rating thresholds
  static const int threeStarMaxHints = 0;
  static const int twoStarMaxHints = 2;
  // 1 star = 3+ hints
  
  // Animation durations
  static const Duration tileConnectDuration = Duration(milliseconds: 80);
  static const Duration wordSubmitDuration = Duration(milliseconds: 300);
  static const Duration levelCompleteDuration = Duration(milliseconds: 600);
  static const Duration feedbackDuration = Duration(milliseconds: 2000);
}
```

---

## App Theme

```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Primary palette — deep jewel tones, calm and smart
  static const Color background = Color(0xFF1A1F3C);        // deep navy
  static const Color surface = Color(0xFF252B4A);           // slightly lighter navy
  static const Color primary = Color(0xFF4A90D9);           // clear blue
  static const Color accent = Color(0xFFE8C35A);            // warm gold
  static const Color accentSecondary = Color(0xFF52B788);   // sage green
  
  // Letter tiles
  static const Color tileDefault = Color(0xFF2E3560);       // dark tile
  static const Color tileSelected = Color(0xFF4A90D9);      // blue when in path
  static const Color tileConnected = Color(0xFF52B788);     // green when locked in
  
  // Feedback states
  static const Color feedbackCorrect = Color(0xFF52B788);   // green
  static const Color feedbackWrongWord = Color(0xFFE05555); // red — not a word
  static const Color feedbackWrongConstraint = Color(0xFFE8A020); // amber — wrong logic
  
  // Boss level indicator
  static const Color bossLevelGold = Color(0xFFE8C35A);
  static const Color bossLevelGlow = Color(0xFFFFE08A);
  
  // Text
  static const Color textPrimary = Color(0xFFEEF0FF);
  static const Color textSecondary = Color(0xFF8892B0);
  static const Color textDisabled = Color(0xFF4A5280);
}
```

---

## Navigation (GoRouter)

```dart
// lib/app.dart — route definitions

final router = GoRouter(
  routes: [
    GoRoute(path: '/',          builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/home',      builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/game/:levelNumber',
      builder: (context, state) => GameScreen(
        levelNumber: int.parse(state.pathParameters['levelNumber']!),
      ),
    ),
    GoRoute(
      path: '/vault/:vaultLevel',
      builder: (context, state) => GameScreen(
        vaultLevel: int.parse(state.pathParameters['vaultLevel']!),
      ),
    ),
    GoRoute(path: '/level-complete', builder: (_, state) => LevelCompleteScreen(extra: state.extra)),
    GoRoute(path: '/vault-entry',   builder: (_, __) => const VaultScreen()),
    GoRoute(path: '/achievements',  builder: (_, __) => const AchievementsScreen()),
    GoRoute(path: '/shop',          builder: (_, __) => const ShopScreen()),
    GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/sign-up',       builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/sign-in',       builder: (_, __) => const SignInScreen()),
  ],
  redirect: (context, state) {
    // If no auth session exists, ensure anonymous session is created
    // before routing to home
  },
);
```

---

## Game State Model

All possible states the game can be in. Each state has a distinct visual treatment.

```dart
// lib/features/game/models/game_state.dart

enum GamePhase {
  loading,          // puzzle loading from JSON/Supabase
  idle,             // puzzle displayed, no interaction yet
  dragging,         // finger actively connecting letters
  submitted,        // word submitted, awaiting feedback display
  feedbackCorrect,  // showing correct word feedback
  feedbackWrongWord,// showing "not a word" feedback (red)
  feedbackWrongConstraint, // showing "misses constraint" feedback (amber)
  hintActive,       // hint tiles highlighted
  levelComplete,    // all words solved
  paused,           // game paused (app backgrounded)
}

class GameState {
  final GamePhase phase;
  final Puzzle puzzle;
  final Map<int, String> solvedWords;       // slotId → word
  final List<int> currentPath;              // tile indices in current drag path
  final String currentWord;                 // word formed by current path
  final int hintsUsedThisLevel;
  final int attemptsThisLevel;
  final int? activeHintSlotId;              // which slot has hint active
  final Set<int> hintedTileIndices;         // tiles highlighted by hint
  final FeedbackMessage? feedbackMessage;   // current feedback to display
  final DateTime levelStartTime;
  final int coinBalance;
  
  bool get isComplete => solvedWords.length == puzzle.wordSlots.length;
  int get stars => _computeStars(hintsUsedThisLevel);
  
  static int _computeStars(int hintsUsed) {
    if (hintsUsed <= GameConstants.threeStarMaxHints) return 3;
    if (hintsUsed <= GameConstants.twoStarMaxHints) return 2;
    return 1;
  }
}

class FeedbackMessage {
  final FeedbackType type;
  final String message;
  final String? constraintText; // for wrong constraint feedback
  
  const FeedbackMessage({
    required this.type,
    required this.message,
    this.constraintText,
  });
}

enum FeedbackType { correct, wrongWord, wrongConstraint }
```

---

## Game Provider (Riverpod)

```dart
// lib/features/game/providers/game_provider.dart

@riverpod
class GameNotifier extends _$GameNotifier {
  
  @override
  GameState build({required int levelNumber, int? vaultLevel}) {
    // Load puzzle, initialize state
  }
  
  // ── Drag mechanic ──────────────────────────────────────────────
  
  void onTileDragStart(int tileIndex) {
    // Begin new path from this tile
    state = state.copyWith(
      phase: GamePhase.dragging,
      currentPath: [tileIndex],
      currentWord: _letterAt(tileIndex),
    );
  }
  
  void onTileDragEnter(int tileIndex) {
    if (state.phase != GamePhase.dragging) return;
    if (state.currentPath.contains(tileIndex)) return; // no revisiting tiles
    if (!_isAdjacentOrConnectable(state.currentPath.last, tileIndex)) return;
    
    state = state.copyWith(
      currentPath: [...state.currentPath, tileIndex],
      currentWord: state.currentWord + _letterAt(tileIndex),
    );
  }
  
  void onTileDragEnd() {
    // Path ends — word stays in place, awaiting submit
    // Do NOT validate here — wait for submit button
    state = state.copyWith(phase: GamePhase.idle);
  }
  
  void onPathCleared() {
    state = state.copyWith(
      currentPath: [],
      currentWord: '',
      phase: GamePhase.idle,
    );
  }
  
  // ── Submission ─────────────────────────────────────────────────
  
  Future<void> onSubmit(int targetSlotId) async {
    if (state.currentWord.isEmpty) return;
    if (state.phase == GamePhase.submitted) return; // prevent double submit
    
    state = state.copyWith(phase: GamePhase.submitted);
    
    final word = state.currentWord.toLowerCase();
    final slot = state.puzzle.wordSlots.firstWhere((s) => s.id == targetSlotId);
    
    // Step 1: Check dictionary
    final inDictionary = await _validateDictionary(word);
    if (!inDictionary) {
      _showFeedback(FeedbackType.wrongWord, '"${word.toUpperCase()}" isn\'t a word we recognize — try again.');
      return;
    }
    
    // Step 2: Check constraint
    final satisfiesConstraint = slot.constraint.validator.validate(word);
    if (!satisfiesConstraint) {
      _showFeedback(
        FeedbackType.wrongConstraint,
        '"${word.toUpperCase()}" is a real word, but it doesn\'t satisfy "${slot.constraint.displayText}".',
      );
      return;
    }
    
    // Step 3: Check intersection compatibility
    final intersectionValid = _validateIntersections(word, targetSlotId);
    if (!intersectionValid) {
      _showFeedback(
        FeedbackType.wrongConstraint,
        '"${word.toUpperCase()}" doesn\'t connect correctly with the crossing word.',
      );
      return;
    }
    
    // ── Correct ──
    final newSolvedWords = {...state.solvedWords, targetSlotId: word};
    final newAttempts = state.attemptsThisLevel + 1;
    
    state = state.copyWith(
      phase: GamePhase.feedbackCorrect,
      solvedWords: newSolvedWords,
      currentPath: [],
      currentWord: '',
      attemptsThisLevel: newAttempts,
    );
    
    // Check level complete
    if (newSolvedWords.length == state.puzzle.wordSlots.length) {
      await Future.delayed(GameConstants.wordSubmitDuration);
      _onLevelComplete();
    }
  }
  
  void _showFeedback(FeedbackType type, String message, {String? constraintText}) {
    state = state.copyWith(
      phase: type == FeedbackType.wrongWord 
          ? GamePhase.feedbackWrongWord 
          : GamePhase.feedbackWrongConstraint,
      currentPath: [],
      currentWord: '',
      attemptsThisLevel: state.attemptsThisLevel + 1,
      feedbackMessage: FeedbackMessage(type: type, message: message, constraintText: constraintText),
    );
    
    // Auto-clear feedback after duration
    Future.delayed(GameConstants.feedbackDuration, () {
      if (state.phase == GamePhase.feedbackWrongWord || 
          state.phase == GamePhase.feedbackWrongConstraint) {
        state = state.copyWith(phase: GamePhase.idle, feedbackMessage: null);
      }
    });
  }
  
  // ── Hints ──────────────────────────────────────────────────────
  
  Future<void> onHintRequested(int slotId) async {
    if (state.coinBalance < GameConstants.hintCost) {
      // Show insufficient coins UI
      return;
    }
    
    // Call Edge Function — deducts coins server-side
    final result = await ref.read(supabaseServiceProvider).callEdgeFunction(
      'on-hint-used',
      body: {
        'level_number': state.puzzle.levelNumber,
        'word_slot': slotId,
        'idempotency_key': _buildIdempotencyKey('hint', slotId),
      },
    );
    
    if (result['success'] == true) {
      state = state.copyWith(
        phase: GamePhase.hintActive,
        activeHintSlotId: slotId,
        hintedTileIndices: Set.from(result['hint_data']['valid_tile_indices']),
        hintsUsedThisLevel: state.hintsUsedThisLevel + 1,
        coinBalance: result['new_balance'],
      );
    }
  }
  
  // ── Skip ───────────────────────────────────────────────────────
  
  Future<void> onSkipRequested() async {
    if (state.coinBalance < GameConstants.skipCost) return;
    
    final result = await ref.read(supabaseServiceProvider).callEdgeFunction(
      'on-level-skip',
      body: {
        'level_number': state.puzzle.levelNumber,
        'level_type': state.puzzle.levelType.name,
        'idempotency_key': _buildIdempotencyKey('skip', 0),
      },
    );
    
    if (result['success'] == true) {
      // Navigate to level complete with skip indicator
      ref.read(routerProvider).go('/level-complete', extra: LevelCompleteArgs(
        levelNumber: state.puzzle.levelNumber!,
        stars: 0, // skipped
        coinsEarned: 0,
        wasSkipped: true,
      ));
    }
  }
  
  // ── Level Complete ─────────────────────────────────────────────
  
  Future<void> _onLevelComplete() async {
    state = state.copyWith(phase: GamePhase.levelComplete);
    
    final timeTakenMs = DateTime.now()
        .difference(state.levelStartTime)
        .inMilliseconds;
    
    // Call Edge Function — awards coins, updates streak, checks achievements
    final result = await ref.read(supabaseServiceProvider).callEdgeFunction(
      'on-level-complete',
      body: {
        'level_number': state.puzzle.levelNumber,
        'level_type': state.puzzle.levelType.name,
        'hints_used': state.hintsUsedThisLevel,
        'attempts_made': state.attemptsThisLevel,
        'words_found': state.solvedWords.length,
        'time_taken_ms': timeTakenMs,
        'stars': state.stars,
        'idempotency_key': _buildIdempotencyKey('complete', 0),
      },
    );
    
    await Future.delayed(GameConstants.levelCompleteDuration);
    
    ref.read(routerProvider).go('/level-complete', extra: LevelCompleteArgs(
      levelNumber: state.puzzle.levelNumber!,
      stars: state.stars,
      coinsEarned: result['coins_awarded'],
      achievementsUnlocked: List<String>.from(result['achievements_unlocked'] ?? []),
    ));
  }
  
  // ── Dictionary validation (client-side) ───────────────────────
  
  Future<bool> _validateDictionary(String word) async {
    // Load valid_guess_words.txt once, cache in memory
    final validWords = await ref.read(validWordSetProvider.future);
    return validWords.contains(word.toLowerCase());
  }
  
  bool _validateIntersections(String word, int slotId) {
    for (final intersection in state.puzzle.intersections) {
      int myPos, otherSlotId, otherPos;
      
      if (intersection.slotAId == slotId) {
        myPos = intersection.positionInA;
        otherSlotId = intersection.slotBId;
        otherPos = intersection.positionInB;
      } else if (intersection.slotBId == slotId) {
        myPos = intersection.positionInB;
        otherSlotId = intersection.slotAId;
        otherPos = intersection.positionInA;
      } else {
        continue;
      }
      
      if (!state.solvedWords.containsKey(otherSlotId)) continue;
      
      final otherWord = state.solvedWords[otherSlotId]!;
      if (myPos >= word.length || otherPos >= otherWord.length) return false;
      if (word[myPos] != otherWord[otherPos]) return false;
    }
    return true;
  }
  
  String _buildIdempotencyKey(String type, int reference) {
    final userId = ref.read(authProvider).userId;
    final level = state.puzzle.levelNumber ?? 'vault';
    return '$userId:$type:$level:$reference';
  }
}
```

---

## Flame Game — Letter Tiles

```dart
// lib/features/game/game/puzzle_game.dart

class PuzzleGame extends FlameGame with TapDetector, DragCallbacks {
  final Puzzle puzzle;
  final GameNotifier gameNotifier;
  
  late final List<LetterTileComponent> tiles;
  late final LetterPathComponent pathComponent;
  
  @override
  Future<void> onLoad() async {
    // Build tile grid from puzzle letter pool
    // Position tiles based on level type and screen size
    // Add path component for drag visualization
  }
  
  @override
  void onDragStart(DragStartEvent event) {
    final tile = _tileAtPosition(event.localPosition);
    if (tile != null) {
      gameNotifier.onTileDragStart(tile.index);
      tile.setSelected(true);
    }
  }
  
  @override
  void onDragUpdate(DragUpdateEvent event) {
    final tile = _tileAtPosition(event.localPosition);
    if (tile != null && !tile.isInCurrentPath) {
      gameNotifier.onTileDragEnter(tile.index);
      tile.setSelected(true);
      pathComponent.addPoint(tile.center);
      // Play tile connect sound
      FlameAudio.play(AssetPaths.tileConnect);
    }
  }
  
  @override
  void onDragEnd(DragEndEvent event) {
    gameNotifier.onTileDragEnd();
    // Path stays visible — word stays assembled until submit or clear
  }
}

class LetterTileComponent extends PositionComponent {
  final String letter;
  final int index;
  bool isInCurrentPath = false;
  bool isLocked = false; // locked into a solved word
  bool isHinted = false;
  
  @override
  void render(Canvas canvas) {
    final color = isLocked
        ? AppColors.tileConnected
        : isHinted
            ? AppColors.accent.withOpacity(0.6)
            : isInCurrentPath
                ? AppColors.tileSelected
                : AppColors.tileDefault;
    
    // Draw rounded rect tile
    // Draw letter centered
    // Draw subtle shadow
  }
  
  void setSelected(bool selected) {
    isInCurrentPath = selected;
    // Animate scale: slight pop on selection
  }
}
```

---

## Screen Specifications

### Splash Screen
- Checks for existing Supabase session
- Creates anonymous session if none exists
- Routes to `/onboarding` on first launch, `/home` otherwise
- Shows app logo with subtle fade-in animation
- Duration: 1.5 seconds max, proceeds as soon as auth check completes

### Onboarding Screen
- 3 swipeable cards explaining the core mechanic
- Card 1: "Drag letters to form words"
- Card 2: "Each word must satisfy a logical clue"
- Card 3: "Words share letters where they cross"
- Skip button always visible
- "Start Playing" CTA on final card → `/home`
- Only shown once (flag in SharedPreferences)

### Home Screen
- World map grid as main content (scrollable)
- Top bar: streak count (flame icon + number), coin balance
- Level nodes: locked (gray), available (colored), completed (star indicator), bossLevel (gold with distinct icon)
- Tap available level → navigate to `/game/:levelNumber`
- Tap completed level → show completion stats, option to replay
- FAB or nav item for: Achievements, Shop, Settings

### Game Screen
- Full screen Flame game area (letter tiles + path)
- Constraint labels displayed beside each word slot
- HUD overlay: level number, coin balance, hint button (cost shown), skip button
- Feedback overlay appears above tiles
- Submit button prominently placed below tile area
- Back button with confirmation dialog ("Leave puzzle? Progress will be lost")

### Level Complete Screen
- "Level [XX] Complete" header
- Star rating (1–3 animated stars filling in sequence)
- Coins earned display with coin animation
- Achievement unlock banners if any triggered (slide in from top)
- Two buttons: "Continue" (→ next level) and "Home" (→ world map)
- No ads, no share prompt, no excessive animation

### The Vault Screen
- Distinct visual treatment — darker, more mysterious than main world map
- "You've conquered the main game. Welcome to The Vault."
- Numbered vault levels with same boss indicator pattern
- Infinite scroll — generate next batch as player scrolls

### Achievements Screen
- Categorized list: Progression, Word Count, Skill, Streaks, Economy, Mastery
- Each achievement: icon, name, description, progress bar if incomplete, coin reward
- Unlocked achievements show unlock date
- Locked achievements show progress (e.g. "47 / 100 levels complete")

### Shop Screen
- Coin bundle options (from RevenueCat products)
- Current coin balance prominently displayed
- Each bundle: coin amount, price, best value indicator
- Purchase flow via RevenueCat SDK
- No subscription products in v1 — coin bundles only

---

## Supabase Service

```dart
// lib/data/services/supabase_service.dart

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // ── Auth ───────────────────────────────────────────────────────
  
  Future<void> ensureAnonymousSession() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
  }
  
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  
  String? get currentUserId => _client.auth.currentUser?.id;
  
  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }
  
  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(OAuthProvider.apple);
  }
  
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }
  
  // ── Data reads (RLS enforced — returns only current user's data) ──
  
  Future<Map<String, dynamic>?> getPlayerProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    return await _client
        .from('player_profiles')
        .select()
        .eq('auth_id', userId)
        .maybeSingle();
  }
  
  Future<int> getCoinBalance() async {
    final result = await _client
        .rpc('compute_coin_balance', params: {'p_user_id': currentUserId});
    return result as int? ?? 0;
  }
  
  Future<List<Map<String, dynamic>>> getPlayerProgress() async {
    return await _client
        .from('player_progress')
        .select()
        .order('level_number');
  }
  
  Future<List<Map<String, dynamic>>> getAchievements() async {
    return await _client
        .from('achievements')
        .select()
        .order('unlocked_at');
  }
  
  // ── Edge Function calls ────────────────────────────────────────
  
  Future<Map<String, dynamic>> callEdgeFunction(
    String functionName, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: body,
    );
    
    if (response.status != 200) {
      Sentry.captureException(
        Exception('Edge function $functionName failed: ${response.status}'),
      );
      throw Exception('Server error — please try again');
    }
    
    return Map<String, dynamic>.from(response.data);
  }
  
  // ── Analytics event write ──────────────────────────────────────
  
  Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {
    await _client.from('analytics_events').insert({
      'user_id': currentUserId,
      'session_id': _currentSessionId,
      'event_name': eventName,
      'properties': properties,
    });
  }
}
```

---

## Letter Pool Builder

```dart
// lib/core/utils/letter_pool_builder.dart

class LetterPoolBuilder {
  static List<String> buildPool({
    required List<String> solutionWords,
    required int levelNumber,
    required String seed,
  }) {
    final rng = Random(seed.hashCode);
    
    // Always include all letters needed for the solution
    final requiredLetters = solutionWords
        .join()
        .toLowerCase()
        .split('');
    
    if (levelNumber < GameConstants.decoyLettersIntroducedLevel) {
      // Exact letters only — shuffle for presentation
      return requiredLetters..shuffle(rng);
    }
    
    if (levelNumber >= GameConstants.fullKeyboardLevel) {
      // Full alphabet
      return 'abcdefghijklmnopqrstuvwxyz'.split('');
    }
    
    // Add decoy letters
    final decoyCount = levelNumber < 50
        ? GameConstants.decoyCountEarly
        : GameConstants.decoyCountMid;
    
    final allLetters = List.of(requiredLetters);
    final alphabet = 'abcdefghijklmnopqrstuvwxyz'.split('');
    
    int added = 0;
    while (added < decoyCount) {
      final candidate = alphabet[rng.nextInt(26)];
      if (!allLetters.contains(candidate)) {
        allLetters.add(candidate);
        added++;
      }
    }
    
    return allLetters..shuffle(rng);
  }
}
```

---

## Auth Flow — Anonymous to Authenticated Migration

```dart
// lib/features/auth/screens/sign_up_screen.dart

Future<void> _onSignUp(String email, String password) async {
  final anonymousUserId = supabaseService.currentUserId;
  
  // 1. Create new account
  await supabaseService.signUpWithEmail(email, password);
  final newUserId = supabaseService.currentUserId!;
  
  // 2. Migrate anonymous data server-side
  final result = await supabaseService.callEdgeFunction(
    'on-account-created',
    body: {
      'anonymous_user_id': anonymousUserId,
      'new_auth_id': newUserId,
    },
  );
  
  if (result['success'] == true) {
    // Migration successful — navigate home
    context.go('/home');
  } else {
    // Migration failed — show error, preserve anonymous session
    _showError('Account creation failed. Your progress is safe — please try again.');
  }
}
```

---

## Performance Requirements

- App cold start to interactive: under 2 seconds
- Level load time: under 500ms
- Drag responsiveness: 60fps minimum, 120fps target on capable devices
- Letter tile connect feedback: under 80ms from finger contact to visual response
- Supabase reads on home screen: cached locally, refreshed on background resume
- Puzzle JSON loaded once at startup, stored in memory for session duration

---

## Error Handling

- All Supabase calls wrapped in try/catch with Sentry reporting
- Edge Function failures show user-friendly message: "Something went wrong — your progress is safe"
- Network offline detection: game playable offline, syncs when connection restored
- If level complete Edge Function fails: retry up to 3 times, then queue locally and retry on next app launch
- Never lose a player's level completion due to a network error

---

## Accessibility

- Minimum tap target size: 44x44 points on all interactive elements
- All feedback messages readable by screen readers (Semantics widgets)
- Color is never the only indicator — shapes and text accompany all color feedback
- Font sizes respect system accessibility settings

---

## Deliverable Checklist

Before this agent's work is considered complete:

- [ ] All screens implemented per spec
- [ ] Flame drag mechanic working smoothly at 60fps
- [ ] All game states implemented with correct transitions
- [ ] Both feedback states (red/amber) working with correct messages
- [ ] Hint system integrated with Edge Function
- [ ] Skip system integrated with Edge Function
- [ ] Level complete flow integrated with Edge Function
- [ ] Anonymous session created on first launch
- [ ] Anonymous → authenticated migration working end-to-end
- [ ] Coin balance reads correctly from Supabase
- [ ] Letter pool transitions at levels 25 and 100
- [ ] bossLevel visual treatment on world map
- [ ] theVault entry after level 200
- [ ] RevenueCat IAP integrated on Shop screen
- [ ] Sentry crash reporting initialized
- [ ] All analytics events firing (see Analytics agent spec)
- [ ] Performance requirements met
- [ ] Tested on iOS and Android physical devices

---

*This spec is the single source of truth for the Flutter/Flame agent. Do not make architectural decisions not covered here — raise them in the GDD first.*
