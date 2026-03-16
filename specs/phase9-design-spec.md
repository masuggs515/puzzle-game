# INTERCEPT
## Phase 9 — Design Polish Specification
### For Flutter Agent Handoff

---

## OVERVIEW

This spec applies the MERIDIAN visual language to the Intercept app as it exists after Phase 8. The game is a crossword tile-placement puzzle — players drag letter tiles from a pool into a crossword grid to satisfy word constraints. This is NOT a Wordle-style game. All screen descriptions reflect the actual implemented screens.

**Emotional target:** Focused. Nostalgic. Slightly mysterious. A 1978 cartographer's desk.

**App name:** INTERCEPT (update all UI strings from any placeholder names)

---

## FONTS — INSTALL FIRST

Download from Google Fonts (OFL license) and add to `assets/fonts/`:

- **Special Elite** — Regular only
- **Oswald** — Light (300), Regular (400), SemiBold (600)
- **Courier Prime** — Regular, Bold (700), Italic

Update `pubspec.yaml`:

```yaml
fonts:
  - family: SpecialElite
    fonts:
      - asset: assets/fonts/SpecialElite-Regular.ttf
  - family: Oswald
    fonts:
      - asset: assets/fonts/Oswald-Light.ttf
        weight: 300
      - asset: assets/fonts/Oswald-Regular.ttf
        weight: 400
      - asset: assets/fonts/Oswald-SemiBold.ttf
        weight: 600
  - family: CourierPrime
    fonts:
      - asset: assets/fonts/CourierPrime-Regular.ttf
      - asset: assets/fonts/CourierPrime-Bold.ttf
        weight: 700
      - asset: assets/fonts/CourierPrime-Italic.ttf
        style: italic
```

---

## COLOR TOKENS

Create `lib/core/theme/app_colors.dart` with these exact values:

### Light Mode — Parchment
```dart
static const parchment    = Color(0xFFD4C9A8); // primary background
static const aged         = Color(0xFFC2B48A); // secondary surfaces
static const deepAged     = Color(0xFFA89060); // borders, dividers
static const ink          = Color(0xFF1C1410); // primary text
static const inkFaded     = Color(0xFF3D2E1E); // secondary text
static const signal       = Color(0xFFC8651A); // primary accent, CTAs
static const signalDim    = Color(0xFF7A3D10); // muted accent
static const rust         = Color(0xFF8B3A1E); // destructive / error
static const tungsten     = Color(0xFFE8C87A); // highlights
static const verdigris    = Color(0xFF2A5C4E); // correct/confirmed
static const desk         = Color(0xFF2C1F0E); // app shell background
static const gridLine     = Color(0x1F1C1410); // rgba(28,20,16,0.12)
```

### Dark Mode — Night Operations
```dart
static const dmBg           = Color(0xFF111008);
static const dmSurface      = Color(0xFF1C1610);
static const dmSurfaceRaised = Color(0xFF241D12);
static const dmInk          = Color(0xFFD4C9A8);
static const dmInkFaded     = Color(0xFF8A7A58);
static const dmSignal       = Color(0xFFD4721F);
static const dmSignalDim    = Color(0xFF7A4010);
static const dmVerdigris    = Color(0xFF3A7A62);
static const dmGridLine     = Color(0x12C8A850); // rgba(200,168,80,0.07)
static const dmBorder       = Color(0x1AD4C9A8); // rgba(212,201,168,0.1)
static const dmBorderActive = Color(0x4DC8651A); // rgba(200,101,26,0.3)
```

---

## TYPOGRAPHY

Create `lib/core/theme/app_text_styles.dart`:

```dart
// Display
static const appName     = TextStyle(fontFamily: 'Oswald', fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.18 * 22);
static const displayXL   = TextStyle(fontFamily: 'Oswald', fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: 0.35 * 32);
static const displayLG   = TextStyle(fontFamily: 'Oswald', fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0.10 * 24);
static const displayMD   = TextStyle(fontFamily: 'Oswald', fontSize: 18, fontWeight: FontWeight.w400, letterSpacing: 0.10 * 18);
static const displaySM   = TextStyle(fontFamily: 'Oswald', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.12 * 14);

// Labels (Special Elite)
static const labelXL     = TextStyle(fontFamily: 'SpecialElite', fontSize: 13, letterSpacing: 0.02 * 13);
static const labelLG     = TextStyle(fontFamily: 'SpecialElite', fontSize: 11, letterSpacing: 0.12 * 11);
static const labelMD     = TextStyle(fontFamily: 'SpecialElite', fontSize: 10, letterSpacing: 0.14 * 10);
static const labelSM     = TextStyle(fontFamily: 'SpecialElite', fontSize: 9,  letterSpacing: 0.18 * 9);
static const labelXS     = TextStyle(fontFamily: 'SpecialElite', fontSize: 8,  letterSpacing: 0.14 * 8);

// Mono (Courier Prime)
static const monoMD      = TextStyle(fontFamily: 'CourierPrime', fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.05 * 13);
static const monoSM      = TextStyle(fontFamily: 'CourierPrime', fontSize: 10, letterSpacing: 0.08 * 10);
static const monoXS      = TextStyle(fontFamily: 'CourierPrime', fontSize: 9,  letterSpacing: 0.10 * 9);
static const tileLabel   = TextStyle(fontFamily: 'Oswald', fontSize: 20, fontWeight: FontWeight.w400, letterSpacing: 0.05 * 20);
static const constraintLabel = TextStyle(fontFamily: 'SpecialElite', fontSize: 11, letterSpacing: 0.12 * 11);
```

---

## SPACING & RADIUS

```dart
// app_spacing.dart
static const screenPadding = 16.0;
static const sectionGap    = 12.0;
static const cardPadding   = 12.0;
static const cellGap       = 5.0;

// app_radius.dart
static const screen = Radius.circular(28);
static const card   = Radius.circular(5);
static const cell   = Radius.circular(3);
static const button = Radius.circular(3);
static const modal  = Radius.circular(8);
static const tag    = Radius.circular(2);
```

**Keep everything angular.** Rounded corners undermine the field instrument aesthetic.

---

## TEXTURE SYSTEM

### GraphPaperBackground Widget
Create `lib/core/widgets/graph_paper_background.dart`:

```dart
// Light mode: major grid 20px + minor grid 4px
// Dark mode: major grid 20px only, amber tint
// Wrap ALL parchment-background screen bodies with this widget
```

Paint recipe (light):
```
linear-gradient(rgba(28,20,16,0.12) 1px, transparent 1px) — 20px
linear-gradient(90deg, rgba(28,20,16,0.12) 1px, transparent 1px) — 20px
linear-gradient(rgba(28,20,16,0.04) 1px, transparent 1px) — 4px
linear-gradient(90deg, rgba(28,20,16,0.04) 1px, transparent 1px) — 4px
```

### Transmission Tape Stripe
3px top border on clue/constraint cards:
```
repeating-linear-gradient(90deg, #c8651a 0px, #c8651a 3px, transparent 3px, transparent 6px)
```

### Desk Shell Background
App scaffold background = `#2c1f0e` with subtle wood grain overlay.

---

## COMPONENT REDESIGNS

### 1. Letter Tile (Pool Tile — Draggable)

The tile in the pool waiting to be placed:
```
size:       52×52px min (touch target)
background: #c2b48a (aged)
border:     1px solid rgba(28,20,16,0.25)
border-bottom: 3px solid rgba(28,20,16,0.35)  ← key depth effect
border-radius: 3px
font:       Oswald 400 20px, ink color
shadow:     0 2px 4px rgba(28,20,16,0.2)
```

On drag (lifted state):
```
scale:      1.08
shadow:     0 6px 16px rgba(28,20,16,0.35)
border:     1px solid signal #c8651a
```

### 2. Grid Cell (DragTarget)

Empty cell:
```
size:       52×52px (match tile)
background: rgba(28,20,16,0.04)
border:     1px solid rgba(28,20,16,0.12)
border-radius: 3px
micro-grid: 5px CustomPaint overlay (rgba(28,20,16,0.06))
```

Filled cell (tile placed):
```
background: rgba(200,101,26,0.08)
border:     1.5px solid #c8651a
letter:     Oswald 400 20px, ink
```

Intersection cell (empty):
```
background: rgba(200,101,26,0.06)
border:     1px dashed rgba(200,101,26,0.4)
corner mark: 6px gold triangle top-right (existing behavior — keep)
```

Intersection cell (filled):
```
background: rgba(200,101,26,0.15)
border:     2px solid #c8651a
corner mark: keep gold triangle
```

Validated correct:
```
background: #2a5c4e (verdigris)
border:     #2a5c4e
letter:     parchment #d4c9a8
```

Validated incorrect:
```
background: rgba(139,58,30,0.15)
border:     #8b3a1e (rust)
letter:     rust
```

### 3. Constraint Label

Displayed alongside word slots in the grid:
```
font:       SpecialElite 11px
color:      --inkFaded
prefix:     "▒ " before constraint text
background: transparent
```

Active/highlighted constraint:
```
color:      --signal
```

### 4. Submit Button
```
background:    #c8651a
border-radius: 3px
height:        48px
font:          Oswald 400 12px uppercase, 0.2em tracking
color:         --ink
label:         "TRANSMIT →"
```
Flat. No shadow, no gradient.

### 5. Clear All Button
```
background:    transparent
border:        1px solid rgba(28,20,16,0.2)
border-radius: 3px
height:        48px
font:          CourierPrime 10px uppercase
color:         rgba(28,20,16,0.45)
label:         "CLEAR"
```

### 6. Hint Button
```
label:      "Field Assist  5 ◈"
background: rgba(200,101,26,0.1)
border:     1px solid rgba(200,101,26,0.2)
radius:     3px
font:       SpecialElite 9px
color:      --signal
```
Disabled when balance < 5: opacity 0.4.

### 7. Primary Navigation (Bottom Bar)
```
background:    --ink (#1c1410)
height:        56px
top border:    1px with dashed signal pattern
```

| Tab | Glyph | Label |
|-----|-------|-------|
| Home / World Map | ⌖ | BASE |
| Achievements | ◈ | DOSSIER |
| Shop | ◆ | SUPPLY |
| Settings | ◎ | FIELD |

Inactive: parchment at 30% opacity. Active: signal orange glyph + label.

---

## SCREEN-BY-SCREEN IMPLEMENTATION

### Home Screen (World Map)

Background: parchment + graph paper texture.

Header:
```
"INTERCEPT" in Oswald 600 22px ink
subtitle: "Field Transmission Decoder" in SpecialElite 9px inkFaded
coin balance: "340 ◈" in CourierPrime 700 right-aligned, signal orange
```

Level grid (50 levels):
- Each level cell: 56×56px, 3px radius
- **Locked:** aged background, padlock glyph, opacity 0.5
- **Available:** parchment background, signal border, level number in Oswald
- **Completed (1-star):** verdigris tint, ★☆☆
- **Completed (2-star):** verdigris, ★★☆
- **Completed (3-star):** verdigris, ★★★
- **Boss level:** signal orange border + "⌖" glyph overlay
- Boss levels at 10, 20, 30, 40, 50

Section headers between groups of 10: `"SECTOR 01"` in SpecialElite 8px uppercase with `◆` rule dividers.

### Game Screen

Background: parchment + graph paper texture.

Header bar (on desk shell background):
```
← back button (ink color)
"SIGNAL #12" in Oswald 400 14px
level type badge in CourierPrime 7px
coin balance right-aligned
```

Crossword grid: centered, with constraint labels on edges.
- Horizontal word: constraint label LEFT of first cell, SpecialElite 11px
- Vertical word: constraint label ABOVE first cell, rotated -90° or inline
- Grid has graph paper micro-grid behind cells

Tile pool:
```
background: rgba(28,20,16,0.06)
border: 1px solid rgba(28,20,16,0.1)
border-radius: 5px
padding: 12px
label: "▒ AVAILABLE TILES" in SpecialElite 8px uppercase inkFaded
tiles: Wrap widget, 5px gap
```

"All tiles placed" message: SpecialElite 10px inkFaded, centered.

Bottom bar:
```
"TRANSMIT →" full-width primary button
"CLEAR" secondary button (right side, smaller)
```

Feedback banner (when shown):
- Correct: verdigris background, parchment text, "DECODED ✓"
- Incorrect: rust background, parchment text, specific error message
- Font: SpecialElite 11px

### Level Complete Screen

Background: desk shell (#2c1f0e) + amber coordinate grid overlay (subtle).

Center stamp:
```
"TRANS-\nMITTED" stamp — Oswald 600 11px uppercase
border: 3px solid signal
inner border: 1px signal at 30% opacity, inset 4px
rotate: -3deg
color: signal orange
size: 80×80px
```

Word reveal:
```
font: Oswald 300 32px
color: parchment
letter spacing: wide (0.35em)
underline: 2px signal orange
```

Stats row (attempts / coins earned / stars):
```
CourierPrime 10px uppercase
values in Oswald 400 18px
```

Star rating: 3 stars, filled = tungsten #e8c87a, empty = aged.

Buttons:
- "NEXT SIGNAL →" primary (signal orange)
- "← RETURN TO BASE" secondary

### Achievements Screen

Background: parchment + graph paper.

Header: `"◈ DOSSIER"` in Oswald 600, ink.

Achievement cards:
```
background: rgba(28,20,16,0.06)
border: 1px solid rgba(28,20,16,0.1)
border-radius: 4px
padding: 12px
```
- Unlocked: verdigris left border (3px), full opacity
- Locked: opacity 0.5, padlock icon
- Name: SpecialElite 13px ink
- Description: CourierPrime 10px inkFaded
- Reward: "50 ◈" in signal orange CourierPrime 700

### Shop Screen

Background: parchment + graph paper.

Header: `"◆ FIELD SUPPLY"` in Oswald 600.

"Watch Ad" card:
```
background: rgba(200,101,26,0.08)
border: 1px solid rgba(200,101,26,0.2)
border-radius: 5px
label: "▒ FREE FRAGMENTS"
CTA: "Watch for 30 ◈"
```

Coin bundle cards:
- Grid 2×2
- Each: aged background, bundle name in Oswald, price in Oswald, coin amount in signal orange
- "BEST VALUE" badge: signal orange, Courier Prime 7px, 2px radius

"Remove ads" banner: ink background, parchment text, signal border.

---

## GLYPH USAGE

| Glyph | Usage in Intercept |
|-------|-------------------|
| ⌖ | Home/Base nav tab, boss level marker |
| ◈ | Dossier/Achievements tab, coin currency symbol |
| ◆ | Shop tab, decorative dividers |
| ◎ | Settings tab |
| ▒ | Section label prefix on cards |
| ● | Live/active indicator (animated blink) |
| → | CTA navigation arrows |

Currency format: `340 ◈` — number first, symbol after, always signal orange.

---

## ANIMATIONS

All animations: subtle and restrained. No bounce, no spring, no overshoot.

| Event | Animation | Duration | Easing |
|-------|-----------|----------|--------|
| Tile pick up | Scale 1.0→1.08, shadow increase | 80ms | ease-out |
| Tile place | Scale 1.08→1.0 | 80ms | ease-out |
| Tile swap | Quick crossfade of letters | 120ms | ease-in-out |
| Invalid submit | TranslateX ±4px × 3 (shake grid) | 300ms | ease-in-out |
| Correct submit | Each cell: verdigris flood fill left to right | 80ms stagger | ease-out |
| Incorrect submit | Each wrong cell: rust tint flash | 200ms | ease-in-out |
| Level complete stamp | Scale 0.85→1.0, opacity 0→1 | 400ms, delay 200ms | ease-out |
| Word reveal | Each letter opacity 0→1 | 100ms per letter, 80ms stagger | ease-out |
| Modal appear | Opacity 0→1, translateY 12→0px | 220ms | ease-out |
| Modal dismiss | Opacity 1→0, translateY 0→8px | 180ms | ease-in |
| Coin count-up | Count animation | 600ms | ease-out |
| Screen transition | Lateral slide + fade | 280ms | ease-in-out |

**Reduced motion:** Replace all translates and scales with opacity fade (150ms).

---

## MODALS

All modals:
```
background:   --ink (#1c1410)
border-radius: 8px
top stripe:   3px transmission tape (dashed signal)
backdrop:     rgba(28,20,16,0.85) with blur(4px)
```

### Leave Puzzle Confirmation
```
Title:  "ABANDON SIGNAL?" (Oswald 400 18px parchment)
Body:   "Your tile placements are saved." (SpecialElite 13px inkFaded)
CTA:    "Leave" (rust)
Cancel: "Stay on signal" (text link, signal)
```

### Hint Confirmation (Field Assist)
```
Title:  "Request Field Assist"
Body:   "Reveal one letter position. Costs 5 ◈."
Balance: "Current balance: 340 ◈"
CTA:    "Confirm — spend 5 ◈"
Cancel: "Stand down"
```

### Skip Confirmation
```
Title:  "Skip This Signal?"
Body:   "Costs 50 ◈. Signal marked as skipped."
CTA:    "Skip — spend 50 ◈" (rust)
Cancel: "Stay on signal"
```

---

## SPLASH SCREEN

Dark desk background only. Centered:
```
[◆ rule ◆]
INTERCEPT  ●
"Field Transmission Decoder · Est. 1978"
```

Staggered fade-in: title 500ms → tagline 400ms delay 400ms → coordinates 300ms delay 800ms.
Signal dot (●) blinks: opacity 1→0.15→1 loop 1400ms.

Auto-advance at 2.5s.

---

## IMPLEMENTATION ORDER

Agent should implement in this order to avoid rework:

1. Install fonts + update pubspec.yaml
2. Create `app_colors.dart`, `app_text_styles.dart`, `app_spacing.dart`, `app_radius.dart`
3. Create `GraphPaperBackground` widget
4. Apply theme to `main.dart` ThemeData
5. Game screen — tiles and grid (highest visual impact)
6. Home screen — world map
7. Level complete screen
8. Achievements screen
9. Shop screen
10. Bottom navigation bar
11. Modals and overlays
12. Splash screen
13. Animations (last — don't block layout work)

---

## DO NOT CHANGE

- Game logic, validation, puzzle engine — untouched
- Supabase service, providers, notifiers — untouched
- Navigation routing — untouched
- Test suite — must remain 237/237 passing after design work
- Ad placements and RevenueCat wiring — untouched

---

## OPEN QUESTIONS (deferred — do not implement)

- Territory map on home screen
- Lore layer / transmission source
- Sound design (typewriter keys, static, confirmation tone)
- App icon design
- Sign in with Google / Apple
- Localization

---

*INTERCEPT Design Spec v1.0 — Phase 9 Flutter Agent Handoff*
*Based on MERIDIAN Design Specification v1.0, adapted for tile-placement crossword mechanic*
