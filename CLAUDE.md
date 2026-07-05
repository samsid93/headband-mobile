# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**HeadBand!** — forehead-guessing party game (charades-style). Three surfaces:
- `headband-game-web.html` — single-file web app (~2140 lines), live at https://whambam.games
- `mobile/` — Flutter app (iOS + Android), currently Phase B (not started — screens are stubs)
- `headband-admin.html` — UI prototype only, no backend connection

**Source of truth for roadmap:** `EXECUTION_PLAN.md` (Version 3.0)

## Flutter Commands

All commands run from the `mobile/` directory:

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter test test/widget_test.dart          # single test file
flutter build apk --release                 # Android APK
flutter build ios --release                 # iOS (Mac only)
```

CI runs `flutter clean && flutter build apk --release` on every push to `main` (see `.github/workflows/build_apk.yml`).

## Flutter Architecture

**State management:** Single `GameProvider` (ChangeNotifier) at the root via Provider. All game logic lives here — no other state management layer.

**Screen flow driven by `GameState` enum:**
```
home → setup → teams → ready → countdown → playing → score
```

**Key file roles:**
- `lib/providers/game_provider.dart` — all game logic, services wired here, `GameState` enum
- `lib/data/mock_data.dart` — hardcoded stub decks (7 decks, ~15 words each); **will be replaced by API calls in Phase B8** — do not expand this file
- `lib/data/models/game_models.dart` — `Deck` and `WordCard` models
- `lib/core/services/sensor_service.dart` — accelerometer; tilt threshold/debounce/cooldown logic
- `lib/core/services/audio_service.dart` — SFX playback via audioplayers
- `lib/core/services/voice_service.dart` — speech_to_text wrapper
- `lib/ui/screens/` — one file per screen; `overlays/` subdirectory for modal overlays

## Web App Architecture

`headband-game-web.html` is a single self-contained file — all HTML, CSS, and JS are inline. There is no build step.

**Edit rules:** Always use surgical `Edit` calls with enough surrounding context. Never rewrite the file. The 600-word deck arrays will be destroyed by a full rewrite.

**Global state object:** `G` — holds all runtime state (`G.gameStyle`, `G.wordPool`, `G.charadesOrientation`, etc.)

**Screen navigation:** `showScreen(id)` swaps visibility between `#screen-*` divs.

## Tilt Engine (Web)

Located in `onMotion()` in `headband-game-web.html`.

Key constants:
```javascript
TILT.THRESHOLD = 4.5   // ~27° required
TILT.SUSTAIN   = 250   // ms hold before firing
TILT.COOLDOWN  = 1500  // ms lockout after trigger
```

Critical guard — **do not remove:**
```javascript
if (_devGamma < 35) return;  // blocks tilt when phone goes portrait in landscape-locked mode
```

Dynamic axis: reads `screen.orientation.type` per frame; applies `axisSign = -1` for `landscape-secondary` to invert tilt direction. This handles flipped phones and covers iOS where `orientation.lock()` silently fails.

## iOS Safari Limitations

Always account for these — they silently fail and cause real device bugs:
- `screen.orientation.lock()` — **not supported**; use `_devGamma` physical check instead
- `requestFullscreen()` — **not supported**; `#fs-btn` pill is the fallback
- `DeviceMotionEvent.requestPermission` — **required** on iOS 13+

## Monetisation Model (Pre-Backend)

Access is currently gated via `localStorage` (web) / `SharedPreferences` (Flutter). The web implementation is the reference; Flutter must replicate it exactly before backend is added.

Word pools in priority order: `allaccess → sub/psub → tmp/ptmp → lifetime → none`

SharedPreferences keys mirror localStorage keys exactly (`hb_fw_{id}`, `hb_tmp_{id}`, `hb_sub_{id}`, `hb_ptmp_{id}`, `hb_psub_{id}`, `hb_allaccess_exp`).

All limits (50 free words, 30s/60s ad durations, etc.) will eventually come from `/api/config` — **do not hardcode them** in new Flutter code; use `AccessConfig` class constants that are populated from config.

## UI Conventions (Web)

- **Back buttons:** pill shape (`border-radius:20px`), "← Go back" text, yellow flash on `:active` with `scale(0.88)`. Class `.back-btn`. Never use circles.
- **Play-back button (`#play-back-btn`):** fixed `bottom:18px; left:50%; transform:translateX(-50%)` — never move to a corner, it conflicts with score panels.
- **Score screen:** always portrait; show `#score-rotate-overlay` (rotate-to-portrait message) in landscape, never the score content.
- **Word card:** category label in green `.wdeck-box` pill above card; word text `text-transform:uppercase`.
- **Deck word count label:** always use `getDeckCntLabel(d)` helper — never show raw word count.
- **Countdown final frame:** full yellow screen, "LET'S GO!!!" text. CSS classes `.cdscreen-go` + `.cdnum-go`.
- **HeadsUp start flow:** `waitLandscape()` → user taps `▶ START!` button → `proceed()` → countdown → game. Do not auto-start on landscape detection.
- **Fullscreen button (`#fs-btn`):** hidden during gameplay and countdown; always call `updateFSBtn()` when changing screens.

## Charades Orientation

`G.charadesOrientation = 'portrait' | 'landscape'`. In landscape Charades, use the default HeadsUp landscape layout — **not** `.charades-mode` class. That class forces vertical layout and breaks landscape button positioning:
```javascript
classList.toggle('charades-mode', isCharades && G.charadesOrientation !== 'landscape')
```

## Phase Status

| Phase | Status |
|-------|--------|
| Phase A (Web) | ✅ Complete |
| Phase B (Flutter) | Not started — B1 is next |
| Phase 0 (Backend) | Not started |
| Phase D (Admin backend) | Not started |

**Do not suggest backend-connected features** until Phase 0 is complete. The Flutter app and web game run entirely on local storage until then.

## Change Lists

When user says "check the file and fix" — always read `changes.txt` first, summarise all points, then implement everything in one pass. Never partially implement a change list.
