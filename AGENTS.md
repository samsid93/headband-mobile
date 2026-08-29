# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

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

## Tilt Engine (Web) — 🔒 LOCKED, DO NOT MODIFY

**The user has explicitly confirmed this engine working on a real device and asked
that it never be touched again by unrelated work.** Every prior round of "fixing" it
made it worse — four separate rewrites shipped, each was a regression, each had to be
reverted. `onMotion()` and the `TILT` object in `headband-game-web.html` are frozen as
of commit `d66df9f`. Every other surface synced from it (`upload/`, `capacitor-app/www`,
the Android/iOS bundles) must carry the byte-identical function — the mobile app runs
the same JS as the web page, so there is only ever one engine to keep correct.

**If a task touches `headband-game-web.html` for an unrelated reason (fonts, layout,
auth, decks, anything), do not let an edit tool, a find/replace, or a "while I'm in
here" cleanup touch `const TILT={...}` or `function onMotion(e){...}`.** If the user
reports a tilt bug, that is the one case this rule lifts — and even then, diff against
the commit the user explicitly confirmed in THIS conversation, never against an earlier
commit picked because it looks plausible. That exact mistake (diffing against `a459f34`,
the original Capacitor migration commit that already had a broken baseline, instead of
`1d86851`, the actual confirmed state) is what produced the `a7d3016` regression.

Ground truth — both gates are load-bearing and both must stay:
```javascript
const TILT={
  THRESHOLD: 4.5,   RELEASE: 2.5,   COOLDOWN: 300,   SUSTAIN: 250,
  MAX_ROLL: 70,      // accelerometer: roll angle past which it's portrait, not a tilt
  GAMMA_MIN: 15,     // gyroscope: minimum |gamma| that still counts as landscape
  cooldownUntil: 0, armed: true, lastDir: null, sustainStart: 0, sustainDir: null,
  clearSustain(){this.sustainDir=null;this.sustainStart=0},
  reset(){this.cooldownUntil=0;this.lastDir=null;this.armed=true;this.clearSustain()}
}
```
```javascript
function onMotion(e){
  const g=e.accelerationIncludingGravity; if(!g) return;
  const ot=(screen.orientation&&screen.orientation.type)||'';
  const axisSign=ot==='landscape-secondary'?-1:1;
  const rawY=g.y||0, gy=rawY*axisSign;
  const roll=Math.atan2(Math.abs(rawY),Math.abs(g.x||0))*57.29577951308232;
  // ... playActive / charades-mode toggle ...
  if(!playActive){TILT.clearSustain();return;}
  if(!G.tiltEnabled){TILT.clearSustain();return;}
  if(G.roundOver){TILT.clearSustain();return;}
  if(!isLandscape()){TILT.clearSustain();return;}
  if(_devGamma < TILT.GAMMA_MIN){TILT.clearSustain();return;}   // gyroscope gate — KEEP
  if(roll>TILT.MAX_ROLL){TILT.clearSustain();return;}            // accelerometer gate — KEEP
  const now=Date.now(), mag=Math.abs(gy);
  if(!TILT.armed){ if(mag<=TILT.RELEASE) TILT.armed=true; TILT.clearSustain(); return; }
  if(now<TILT.cooldownUntil) return;
  if(gy >= TILT.THRESHOLD){ /* sustain -> doCorrect() */ }
  else if(gy <= -TILT.THRESHOLD){ /* sustain -> doSkip() */ }
  else{ TILT.clearSustain(); }
}
```
Triggers compare **absolute `gy`** against a symmetric `±THRESHOLD` — no baseline, no
calibration, no deviation-from-rest. That is the confirmed design; it is not a
simplification waiting to be improved.

The phone is held upright at the forehead; a tilt swings gravity from the `x` axis into
`y`. `axisSign` flips for `landscape-secondary` (handles a flipped phone, and covers iOS
where `orientation.lock()` silently fails). `DeviceOrientationEvent.requestPermission()`
must stay requested on iOS 13+ (separate from `DeviceMotionEvent`'s permission) or
`_devGamma` never leaves its initial `90` and the gyroscope gate is silently inert —
harmless (it just never blocks), but the debug readout would be misleading without it.

Every bail-out `return` in `onMotion()` calls `TILT.clearSustain()` first. Skipping that
leaves a stale `sustainStart`, so re-entering the tilted state later satisfies
`now - sustainStart >= SUSTAIN` immediately and fires with no real gesture.

Four reverted attempts, kept as a record of what NOT to retry:

| attempt | what broke |
|---|---|
| self-calibrating rest baseline (continuous tracking) | chased slow gestures; correct only fired at full portrait |
| removing the gyroscope gate | did not help, and dropped a real guard |
| re-arm watchdog (`REARM_TIMEOUT`) | made the harder direction unreliable |
| calibrated-neutral, captured once per opportunity (`a7d3016`) | on-device: tilt stopped working entirely |

Known, accepted, and asserted in the tests rather than "fixed" again: an off-centre
resting hold makes one direction nearer its threshold than the other, and a rest outside
`±RELEASE` can leave the latch un-armed. If the user reports a NEW tilt symptom, get
sensor readings before writing any code — `?tiltdebug=1` in a browser, or six taps in
the top-right corner of Home in the app — both print live `x/y/z`, `roll`, `gamma`,
`armed`, and keep updating while a guard is blocking. Every regression above came from
reasoning about axes instead of reading them.

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
