# Testing Agent Spec
**Project:** Intercept
**Agent Role:** Testing specialist — writes, maintains, and runs the test suite across all layers of the application. Owns unit tests, widget tests, integration tests, and Edge Function tests. Reports coverage and flags untested critical paths.  
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

## Core Principle

**Test what matters. Don't test everything.**

This is a solo indie game, not enterprise software. The goal is not 100% coverage — it's confident coverage of the things that would silently break and cost players or revenue. Every test written must justify its existence.

**Test ruthlessly:**
- Coin arithmetic and idempotency (money)
- Puzzle solvability (player experience)
- Constraint validation (core mechanic)
- Auth and data isolation (security)
- Feedback state correctness (red vs amber distinction)

**Test lightly:**
- UI layout and styling (changes too often, tested manually)
- Navigation flows (covered by manual playtesting)
- Sound and animation (not testable meaningfully in unit tests)

---

## Test Stack

| Layer | Tool | Purpose |
|---|---|---|
| Dart unit tests | `flutter test` | Puzzle engine, constraints, CSP solver, coin math |
| Flutter widget tests | `flutter test` | Game state machine, feedback states, game HUD |
| Supabase Edge Function tests | Deno test runner | Coin idempotency, RLS, Edge Function logic |
| Integration tests | `flutter_test` integration | End-to-end level completion flow |
| Manual test cases | Documented in this spec | Things automation can't cover |

---

## Project Test Structure

```
test/
  puzzle_engine/
    word_list_test.dart
    constraint_tier1_test.dart
    constraint_tier2_test.dart
    constraint_tier3_test.dart
    constraint_tier4_test.dart
    constraint_tier5_test.dart
    csp_solver_test.dart
    puzzle_validator_test.dart
    puzzle_serializer_test.dart
    difficulty_profile_test.dart
    runtime_generator_test.dart
  
  game/
    game_state_test.dart
    word_validation_test.dart
    intersection_validation_test.dart
    feedback_state_test.dart
    letter_pool_builder_test.dart
    ad_frequency_test.dart
  
  economy/
    coin_balance_test.dart
    hint_deduction_test.dart
    skip_deduction_test.dart
    achievement_trigger_test.dart
    streak_logic_test.dart
  
  analytics/
    event_schema_test.dart
    session_management_test.dart
    pii_guard_test.dart

supabase/
  tests/
    rls_test.ts
    on_level_complete_test.ts
    on_hint_used_test.ts
    on_level_skip_test.ts
    on_rewarded_ad_test.ts
    on_iap_purchase_test.ts
    coin_idempotency_test.ts

integration_test/
  level_completion_flow_test.dart
  auth_migration_test.dart
```

---

## Critical Test Suites

These must exist and pass before any phase is marked complete. No exceptions.

---

### Suite 1 — Constraint Validation

Every constraint must have tests covering: known-good words that pass, known-bad words that fail, edge cases (empty string, single letter, very long word), and filter performance on the full answer word list.

```dart
// test/puzzle_engine/constraint_tier1_test.dart

void main() {
  group('CategoryConstraint — Animals', () {
    late CategoryConstraint constraint;
    
    setUp(() {
      constraint = CategoryConstraint(
        id: 'is_animal',
        displayText: 'A type of animal',
        categoryName: 'animals',
      );
    });
    
    test('validates known animals', () {
      expect(constraint.validate('dog'), isTrue);
      expect(constraint.validate('eagle'), isTrue);
      expect(constraint.validate('whale'), isTrue);
      expect(constraint.validate('DOG'), isTrue); // case insensitive
    });
    
    test('rejects non-animals', () {
      expect(constraint.validate('table'), isFalse);
      expect(constraint.validate('blue'), isFalse);
      expect(constraint.validate(''), isFalse);
    });
    
    test('filter returns non-empty list from answer words', () {
      final words = WordListLoader.answerWords;
      final filtered = constraint.filterWordList(words);
      expect(filtered.length, greaterThan(50));
    });
  });
  
  group('CategoryConstraint — Colors', () {
    // same pattern for every category
  });
}
```

```dart
// test/puzzle_engine/constraint_tier2_test.dart

void main() {
  group('SameFirstLastConstraint', () {
    final constraint = SameFirstLastConstraint();
    
    test('validates same first and last letter words', () {
      expect(constraint.validate('level'), isTrue);   // L...L
      expect(constraint.validate('radar'), isTrue);   // R...R
      expect(constraint.validate('kayak'), isTrue);   // K...K
      expect(constraint.validate('civic'), isTrue);   // C...C
      expect(constraint.validate('noon'), isTrue);    // N...N
      expect(constraint.validate('tenet'), isTrue);   // T...T
    });
    
    test('rejects words with different first and last', () {
      expect(constraint.validate('apple'), isFalse);
      expect(constraint.validate('flutter'), isFalse);
      expect(constraint.validate('dart'), isFalse);
    });
    
    test('edge cases', () {
      expect(constraint.validate('a'), isTrue);    // single letter
      expect(constraint.validate(''), isFalse);    // empty
    });
  });
  
  group('NoRepeatedLettersConstraint', () {
    final constraint = NoRepeatedLettersConstraint();
    
    test('validates words with no repeats', () {
      expect(constraint.validate('sphinx'), isTrue);
      expect(constraint.validate('vortex'), isTrue);
      expect(constraint.validate('blunt'), isTrue);
    });
    
    test('rejects words with repeated letters', () {
      expect(constraint.validate('apple'), isFalse);  // repeated P
      expect(constraint.validate('teeth'), isFalse);  // repeated T and E
      expect(constraint.validate('level'), isFalse);  // repeated L and E
    });
  });
  
  group('HasDoubleLetterConstraint', () {
    final constraint = HasDoubleLetterConstraint();
    
    test('validates words with adjacent double letters', () {
      expect(constraint.validate('teeth'), isTrue);   // TT and EE
      expect(constraint.validate('happy'), isTrue);   // PP
      expect(constraint.validate('grass'), isTrue);   // SS
      expect(constraint.validate('abbey'), isTrue);   // BB
    });
    
    test('rejects words with non-adjacent repeated letters', () {
      expect(constraint.validate('level'), isFalse);  // L...L not adjacent
      expect(constraint.validate('radar'), isFalse);  // R...R not adjacent
    });
    
    test('rejects words with no repeated letters', () {
      expect(constraint.validate('sphinx'), isFalse);
    });
  });
}
```

---

### Suite 2 — CSP Solver

```dart
// test/puzzle_engine/csp_solver_test.dart

void main() {
  late CspSolver solver;
  late List<String> answerWords;
  
  setUpAll(() async {
    answerWords = await WordListLoader.loadAnswerWords();
    final library = ConstraintLibrary.build(
      answerWords: answerWords,
      allValidWords: await WordListLoader.loadAllValidWords(),
    );
    solver = CspSolver(answerWords: answerWords, constraintLibrary: library);
  });
  
  test('solves simple 2-word 1-intersection puzzle', () {
    final skeleton = PuzzleSkeleton(
      slots: [
        WordSlot(id: 0, constraint: ConstraintAssignment(
          tier: 1, constraintId: 'is_animal',
          displayText: 'A type of animal',
          validator: CategoryConstraint(id: 'is_animal', displayText: '', categoryName: 'animals'),
        )),
        WordSlot(id: 1, constraint: ConstraintAssignment(
          tier: 1, constraintId: 'is_color',
          displayText: 'A color',
          validator: CategoryConstraint(id: 'is_color', displayText: '', categoryName: 'colors'),
        )),
      ],
      intersections: [
        Intersection(slotAId: 0, slotBId: 1, positionInA: 0, positionInB: 0),
      ],
    );
    
    final result = solver.solve(skeleton);
    expect(result, isNotNull);
    expect(result!.wordSlots[0].assignedWord, isNotNull);
    expect(result.wordSlots[1].assignedWord, isNotNull);
    
    // Verify intersection constraint satisfied
    final wordA = result.wordSlots[0].assignedWord!;
    final wordB = result.wordSlots[1].assignedWord!;
    expect(wordA[0].toLowerCase(), equals(wordB[0].toLowerCase()));
  });
  
  test('returns null for unsolvable puzzle', () {
    // Create a skeleton that cannot be solved:
    // Slot A must be a palindrome AND start with Q
    // Slot B must be an animal AND start with Q
    // AND they must share their last letter
    // This combination has no valid solution
    final skeleton = _buildImpossibleSkeleton();
    final result = solver.solve(skeleton, maxAttempts: 100);
    expect(result, isNull);
  });
  
  test('same seed produces same solution', () {
    final skeleton = _buildSimpleSkeleton();
    final result1 = solver.solve(skeleton, seed: 42);
    final result2 = solver.solve(skeleton, seed: 42);
    
    expect(result1?.wordSlots[0].assignedWord,
           equals(result2?.wordSlots[0].assignedWord));
  });
  
  test('different seeds can produce different solutions', () {
    final skeleton = _buildSimpleSkeleton();
    final results = <String>{};
    
    for (int seed = 0; seed < 20; seed++) {
      final result = solver.solve(skeleton, seed: seed);
      if (result != null) {
        results.add(result.wordSlots[0].assignedWord!);
      }
    }
    
    // At least 3 different answers across 20 seeds
    expect(results.length, greaterThan(2));
  });
  
  test('maxAttempts limit is respected', () {
    final stopwatch = Stopwatch()..start();
    solver.solve(_buildConstrainedSkeleton(), maxAttempts: 10);
    stopwatch.stop();
    
    // Should return quickly, not spin forever
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });
  
  test('all hand-crafted levels are solvable', () async {
    final puzzles = await PuzzleSerializer.loadAll('assets/puzzles/levels_001_200.json');
    
    for (final puzzle in puzzles.take(50)) { // test all 50 hand-crafted
      final skeleton = puzzle.toSkeleton();
      final result = solver.solve(skeleton);
      expect(result, isNotNull,
        reason: 'Level ${puzzle.levelNumber} has no valid solution');
    }
  });
}
```

---

### Suite 3 — Coin Economy (Most Critical)

```dart
// test/economy/coin_balance_test.dart

void main() {
  group('Coin balance computation', () {
    test('new player has zero balance', () async {
      final balance = await CoinRepository.getBalance(testUserId);
      expect(balance, equals(0));
    });
    
    test('balance equals sum of all transactions', () async {
      // Insert test transactions directly
      await testDb.insert('coin_transactions', {
        'user_id': testUserId,
        'amount': 10,
        'transaction_type': 'level_complete',
        'idempotency_key': 'test-key-1',
      });
      await testDb.insert('coin_transactions', {
        'user_id': testUserId,
        'amount': -5,
        'transaction_type': 'hint_used',
        'idempotency_key': 'test-key-2',
      });
      
      final balance = await CoinRepository.getBalance(testUserId);
      expect(balance, equals(5)); // 10 - 5 = 5
    });
    
    test('balance never goes negative via Edge Function', () async {
      // Player has 3 coins, tries to spend 5
      await _setBalance(testUserId, 3);
      
      expect(
        () => SupabaseService.callEdgeFunction('on-hint-used', body: {
          'user_id': testUserId,
          'level_number': 1,
          'word_slot': 0,
          'idempotency_key': 'test-insufficient',
        }),
        throwsA(isA<InsufficientCoinsException>()),
      );
      
      // Balance unchanged
      final balance = await CoinRepository.getBalance(testUserId);
      expect(balance, equals(3));
    });
  });
}
```

```dart
// test/economy/coin_idempotency_test.dart

void main() {
  group('Level complete idempotency', () {
    test('double-calling on-level-complete with same key only awards once', () async {
      const key = 'idempotency-test-level-1-user-abc';
      
      // Call twice with identical key
      await SupabaseService.callEdgeFunction('on-level-complete', body: {
        'level_number': 1,
        'level_type': 'sprint',
        'hints_used': 0,
        'attempts_made': 1,
        'words_found': 2,
        'time_taken_ms': 45000,
        'stars': 3,
        'idempotency_key': key,
      });
      
      await SupabaseService.callEdgeFunction('on-level-complete', body: {
        'level_number': 1,
        'level_type': 'sprint',
        'hints_used': 0,
        'attempts_made': 1,
        'words_found': 2,
        'time_taken_ms': 45000,
        'stars': 3,
        'idempotency_key': key, // same key
      });
      
      final balance = await CoinRepository.getBalance(testUserId);
      expect(balance, equals(10)); // awarded once, not twice
      
      final transactions = await testDb
          .from('coin_transactions')
          .select()
          .eq('idempotency_key', key);
      expect(transactions.length, equals(1)); // only one row
    });
    
    test('hint idempotency', () async {
      await _setBalance(testUserId, 50);
      const key = 'idempotency-test-hint-1';
      
      await SupabaseService.callEdgeFunction('on-hint-used', body: {
        'level_number': 5,
        'word_slot': 0,
        'idempotency_key': key,
      });
      await SupabaseService.callEdgeFunction('on-hint-used', body: {
        'level_number': 5,
        'word_slot': 0,
        'idempotency_key': key, // same key
      });
      
      final balance = await CoinRepository.getBalance(testUserId);
      expect(balance, equals(45)); // deducted once (50 - 5 = 45)
    });
  });
}
```

---

### Suite 4 — Feedback State Correctness

This is the most important game mechanic distinction: red = not a word, amber = valid word but wrong constraint. Getting this backwards would be a confusing, game-breaking bug.

```dart
// test/game/feedback_state_test.dart

void main() {
  late GameNotifier gameNotifier;
  
  setUp(() {
    // Set up a test puzzle with a Tier 1 animal constraint
    gameNotifier = GameNotifier.forTesting(
      puzzle: TestPuzzles.simpleAnimalPuzzle(),
    );
  });
  
  group('Feedback state correctness', () {
    test('non-dictionary word produces wrongWord state', () async {
      gameNotifier.setCurrentWord('ZXQWVB'); // not a word
      await gameNotifier.onSubmit(slotId: 0);
      
      expect(gameNotifier.state.phase, equals(GamePhase.feedbackWrongWord));
      expect(gameNotifier.state.feedbackMessage!.type,
             equals(FeedbackType.wrongWord));
    });
    
    test('valid word wrong constraint produces wrongConstraint state', () async {
      // Slot 0 requires an animal. BLUE is a real word but not an animal.
      gameNotifier.setCurrentWord('BLUE');
      await gameNotifier.onSubmit(slotId: 0);
      
      expect(gameNotifier.state.phase, equals(GamePhase.feedbackWrongConstraint));
      expect(gameNotifier.state.feedbackMessage!.type,
             equals(FeedbackType.wrongConstraint));
      // Constraint text must appear in the feedback
      expect(gameNotifier.state.feedbackMessage!.constraintText, isNotNull);
    });
    
    test('valid word satisfying constraint produces correct state', () async {
      // Slot 0 requires an animal. BEAR is valid.
      gameNotifier.setCurrentWord('BEAR');
      await gameNotifier.onSubmit(slotId: 0);
      
      expect(gameNotifier.state.phase, equals(GamePhase.feedbackCorrect));
      expect(gameNotifier.state.solvedWords.containsKey(0), isTrue);
    });
    
    test('wrong word NEVER produces wrongConstraint state', () async {
      // Non-words must always get red, never amber
      for (final nonWord in ['ZZZZZ', 'QQQQ', 'XKCD', 'BLARG']) {
        gameNotifier.setCurrentWord(nonWord);
        await gameNotifier.onSubmit(slotId: 0);
        
        expect(
          gameNotifier.state.feedbackMessage!.type,
          isNot(equals(FeedbackType.wrongConstraint)),
          reason: '$nonWord should produce wrongWord not wrongConstraint',
        );
        
        gameNotifier.reset();
      }
    });
    
    test('correct word never produces wrong feedback', () async {
      for (final animal in ['CAT', 'DOG', 'BEAR', 'WOLF', 'EAGLE']) {
        gameNotifier.setCurrentWord(animal);
        await gameNotifier.onSubmit(slotId: 0);
        
        if (gameNotifier.state.phase == GamePhase.feedbackCorrect) {
          // If it was correct, make sure it didn't show wrong feedback first
          expect(gameNotifier.state.feedbackMessage?.type,
                 isNot(equals(FeedbackType.wrongWord)));
        }
        
        gameNotifier.reset();
      }
    });
  });
}
```

---

### Suite 5 — Ad Frequency

```dart
// test/game/ad_frequency_test.dart

void main() {
  group('AdFrequencyManager', () {
    test('never shows ad to paying user', () {
      final manager = AdFrequencyManager();
      
      for (int i = 0; i < 100; i++) {
        expect(
          manager.shouldShowAd(isBossLevel: false, isPayingUser: true),
          isFalse,
          reason: 'Paying users should never see ads (check $i)',
        );
      }
    });
    
    test('never shows ad on boss level completion', () {
      final manager = AdFrequencyManager();
      
      for (int i = 0; i < 100; i++) {
        expect(
          manager.shouldShowAd(isBossLevel: true, isPayingUser: false),
          isFalse,
          reason: 'Boss levels should never show ads (check $i)',
        );
      }
    });
    
    test('shows ad within 4-5 level window for free user', () {
      final manager = AdFrequencyManager();
      int adCount = 0;
      int levelsSinceLastAd = 0;
      
      for (int i = 0; i < 50; i++) {
        levelsSinceLastAd++;
        final showAd = manager.shouldShowAd(
          isBossLevel: false,
          isPayingUser: false,
        );
        
        if (showAd) {
          // Ad interval must be 4 or 5
          expect(levelsSinceLastAd, inInclusiveRange(4, 5));
          levelsSinceLastAd = 0;
          adCount++;
        }
      }
      
      // Should have seen roughly 10-12 ads in 50 levels
      expect(adCount, inInclusiveRange(8, 14));
    });
    
    test('ad interval randomizes within bounds', () {
      final intervals = <int>[];
      
      for (int run = 0; run < 20; run++) {
        final manager = AdFrequencyManager();
        int count = 0;
        
        while (true) {
          count++;
          if (manager.shouldShowAd(isBossLevel: false, isPayingUser: false)) {
            intervals.add(count);
            break;
          }
        }
      }
      
      // Should see both 4 and 5 across 20 runs
      expect(intervals.contains(4) || intervals.contains(5), isTrue);
      expect(intervals.every((i) => i >= 4 && i <= 5), isTrue);
    });
  });
}
```

---

### Suite 6 — Analytics PII Guard

```dart
// test/analytics/pii_guard_test.dart

void main() {
  group('PII guard — word_submitted event', () {
    test('word_submitted never contains the actual word', () {
      final capturedEvents = <Map<String, dynamic>>[];
      
      // Mock the track function to capture events
      final analytics = AnalyticsService.forTesting(
        onTrack: (name, props) => capturedEvents.add({name: props}),
      );
      
      analytics.trackWordSubmitted(
        levelNumber: 1,
        levelType: 'sprint',
        word: 'ELEPHANT', // the actual word — should NOT appear in event
        constraintId: 'is_animal',
        constraintTier: 1,
        result: 'correct',
        attemptNumber: 1,
        wordSlotId: 0,
        timeOnLevelMs: 12000,
      );
      
      final event = capturedEvents.first['word_submitted'] as Map;
      
      // Must NOT contain the word
      expect(event.containsKey('word'), isFalse);
      expect(event.values.contains('ELEPHANT'), isFalse);
      expect(event.values.contains('elephant'), isFalse);
      
      // Must contain word_length
      expect(event.containsKey('word_length'), isTrue);
      expect(event['word_length'], equals(8)); // ELEPHANT has 8 letters
    });
    
    test('no event ever contains an email address pattern', () {
      final capturedEvents = <Map<String, dynamic>>[];
      final analytics = AnalyticsService.forTesting(
        onTrack: (name, props) => capturedEvents.add(props),
      );
      
      // Fire all events
      analytics.trackAccountCreated(
        method: 'email',
        wasGuest: true,
        levelsCompletedAsGuest: 5,
        coinBalanceAtConversion: 50,
      );
      
      final emailPattern = RegExp(r'[a-zA-Z0-9.]+@[a-zA-Z0-9.]+\.[a-zA-Z]+');
      
      for (final event in capturedEvents) {
        for (final value in event.values) {
          if (value is String) {
            expect(
              emailPattern.hasMatch(value),
              isFalse,
              reason: 'Event contains email-like string: $value',
            );
          }
        }
      }
    });
  });
}
```

---

### Suite 7 — RLS Isolation (Supabase)

```typescript
// supabase/tests/rls_test.ts
// Run with: deno test supabase/tests/rls_test.ts

import { createClient } from '@supabase/supabase-js';
import { assertEquals } from 'https://deno.land/std/testing/asserts.ts';

Deno.test('user A cannot read user B player_profiles', async () => {
  const userAClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  const userBClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  
  await userAClient.auth.signInAnonymously();
  await userBClient.auth.signInAnonymously();
  
  const userBId = (await userBClient.auth.getUser()).data.user!.id;
  
  // User A tries to read User B's profile
  const { data, error } = await userAClient
    .from('player_profiles')
    .select()
    .eq('auth_id', userBId);
  
  assertEquals(data?.length, 0); // RLS should return empty, not error
});

Deno.test('user cannot directly insert into coin_transactions', async () => {
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  await client.auth.signInAnonymously();
  const userId = (await client.auth.getUser()).data.user!.id;
  
  const { error } = await client.from('coin_transactions').insert({
    user_id: userId,
    amount: 99999,
    transaction_type: 'level_complete',
    idempotency_key: 'exploit-attempt',
  });
  
  // Must fail — only Edge Functions can write to coin_transactions
  assertEquals(error?.code, '42501'); // insufficient privilege
});

Deno.test('user cannot read another users coin_transactions', async () => {
  const userAClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  const userBClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  
  await userAClient.auth.signInAnonymously();
  await userBClient.auth.signInAnonymously();
  
  const { data } = await userAClient
    .from('coin_transactions')
    .select();
  
  // Should only see own transactions (or empty if none)
  const userBId = (await userBClient.auth.getUser()).data.user!.id;
  const hasUserBData = data?.some(t => t.user_id === userBId) ?? false;
  assertEquals(hasUserBData, false);
});
```

---

## When to Run Tests

| Trigger | Test suites to run |
|---|---|
| After any Dart/Flutter code change | `flutter test` (all suites) |
| After any Supabase schema change | RLS tests + Edge Function tests |
| After any Edge Function change | That function's test + coin idempotency |
| Before marking any phase complete | Full suite |
| Before App Store submission | Full suite + integration tests |

---

## Coverage Targets

| Area | Target | Rationale |
|---|---|---|
| Constraint validation | 100% | Core mechanic — every constraint must be tested |
| CSP solver | 95% | Complex algorithm — near-complete coverage |
| Coin arithmetic | 100% | Money — zero tolerance for untested paths |
| Idempotency | 100% | Money — zero tolerance |
| Feedback state machine | 100% | Core UX — red vs amber distinction is critical |
| RLS policies | 100% | Security — every table must be tested |
| Analytics PII guard | 100% | Legal/trust — every event must be verified |
| Ad frequency | 90% | Revenue — frequency logic must be correct |
| Flutter widgets | 60% | Changes frequently — focus on game states |
| Navigation | 30% | Covered by manual playtesting |

---

## Testing Agent Session Brief

When Adam wants to run a Testing Agent session:

```
Read specs/testing-agent-spec.md and specs/project-state.md.
The [Agent Name] just completed [description of work].
Write and run tests for [specific area].
Report coverage, failures, and any TODO MAS items.
```

---

## Test Report Format

```markdown
# Test Report
Date: [date]
Triggered by: [what agent session this follows]

## Results Summary
Total tests: [N]
Passing: [N]
Failing: [N]
Skipped: [N]

## Coverage
[Area]: [X]% (target: [Y]%)

## Failures
[List each failure with file, test name, expected vs actual]

## New Untested Paths Identified
[List any code paths introduced this session that have no test coverage]
[Flag which are in critical areas — recommend Testing Agent session to cover them]

## TODO MAS Items
[List all TODO MAS comments left this session]
```

---

*Tests exist to give Adam confidence, not to slow development. Write them for the things that matter, run them after every session, and keep them passing. A failing test is a blocker — it does not get skipped.*
