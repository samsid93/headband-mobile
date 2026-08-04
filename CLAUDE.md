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
TILT.THRESHOLD = 4.5   // ~27° required to trigger
TILT.RELEASE   = 2.5   // ~15° — must return inside this to re-arm (hysteresis)
TILT.SUSTAIN   = 250   // ms hold before firing
TILT.COOLDOWN  = 300   // ms debounce after trigger
```

**The phone is held UPRIGHT at the forehead**, gravity across the `x` axis, `gy ≈ 0` at
rest. A tilt swings gravity from `x` into `y`. (The header comment in the source says
"flat/horizontal" — it is misleading. The gyroscope gate below passes during real play,
and it requires `|gamma| >= 15`, which only happens when the phone is upright.)

Portrait is rejected by the accelerometer alone:
```javascript
const roll = Math.atan2(Math.abs(rawY), Math.abs(g.x||0)) * 57.29578;
if (roll > TILT.MAX_ROLL) return;                          // 70deg+ = portrait
```

**Never gate tilt on `deviceorientation` (`_devGamma`).** It is a *separate, slower*
event stream from `devicemotion` and it throttles or stalls across orientation changes —
`_devGamma` then stays frozen at the last portrait value and blocks every tilt until some
later event lands. That is what "tilt dies after rotating to portrait and back, or goes
very slow" was. Successive thresholds of 35, 15 and 8 all failed for the same underlying
reason. `_devGamma` is now debug-only. `MAX_ROLL` covers portrait from the same 60 Hz
stream that drives the triggers, so it cannot go stale while triggers are being evaluated.

The old "Rotate to landscape — tilt disabled in portrait" banner was **removed**. It was
driven off the gyroscope threshold, so it flashed during deep-but-valid gestures and read
as the game fighting the player. It never blocked anything itself.

**Triggers compare ABSOLUTE `gy` against a symmetric `±THRESHOLD`.** This is the logic
confirmed working on a real device. Do not replace it from first principles — four
attempts did, each shipped a worse regression, each was reverted:

| attempt | what broke |
|---|---|
| self-calibrating rest baseline (continuous) | baseline chased slow gestures; correct only fired at full portrait |
| removing the gyroscope gate | did not help, and dropped a real guard |
| re-arm watchdog (`REARM_TIMEOUT`) | made the harder direction unreliable |
| calibrated-neutral, captured once per opportunity (commit `a7d3016`) | on-device: tilt stopped working entirely |

**Before touching this engine again**, diff it against the last commit the user
explicitly confirmed working in THIS conversation (grep the chat for "working fine" /
"perfectly working" and note which commit was current then) — not against an earlier
commit picked because it looks plausible. Restoring from the wrong reference is exactly
how the `a7d3016` regression happened: it was compared against `a459f34`, the *original*
Capacitor migration commit that already contained the broken baseline, instead of
`1d86851`, the actual confirmed-working state.

Known and accepted consequences, asserted in the tests so they are not "fixed" again:
an off-centre resting hold makes one direction nearer its threshold than the other,
and a rest outside `±RELEASE` can leave the latch un-armed. Change any of this **only
with sensor readings from a device** — `?tiltdebug=1` in a browser, or six taps in the
top-right of Home in the app.

<details><summary>superseded: deviation-from-baseline (do not reintroduce)</summary>
Nobody holds the phone level at their forehead, so resting `gy` is biased — on a real
device it sat around `-3`. Against a symmetric `±4.5` that makes the directions wildly
unequal: skip needed 1.5 more, correct needed 7.5, i.e. almost a full turn to portrait.
That was the long-running "skip fine, correct only works in portrait" fault.

```javascript
const dev = gy - TILT.restGy;                       // compare THIS, not gy
if (mag < TILT.THRESHOLD) TILT.restGy += dev * TILT.REST_ALPHA;
```
The baseline adapts only below `THRESHOLD` (a real gesture is at or beyond it, so it
cannot drag the baseline) and slowly (`REST_ALPHA` ~1 s). The band is `THRESHOLD` rather
than `RELEASE` so a baseline seeded from an unlucky first frame can still correct itself.

`REARM_TIMEOUT` (2 s) is a lockout watchdog. Re-arming normally needs the phone back
inside `±RELEASE`; if it is stuck outside for this long the baseline is assumed wrong and
is pulled toward the current reading, so a changed grip cannot kill tilt for the round.
It re-arms outright only when below `THRESHOLD`, so it can never re-arm into a repeat
mid-tilt.

**Tests must start from a settled hold** — jumping straight to a tilt seeds the baseline
*on* the tilt and measures zero deviation. `makeEngine()` settles for 900 ms by default.

</details>

**Do not "fix" this engine by reasoning about axes — measure.** `?tiltdebug=1` prints
live `x/y/z`, `roll`, `gamma`, `armed` and keeps updating while a guard is blocking.
Several regressions came from inferring the pose instead of reading it.

**Known limitation:** re-arming takes a single frame, so swinging the phone rapidly
across the threshold can retrigger. A `REARM_HOLD` of 250 ms fixed that but made the
harder-to-reach tilt direction unreliable, so it was reverted. Do not re-add it without
testing both directions on a real device.

**One trigger per gesture is enforced by `TILT.armed`, not by `COOLDOWN`.** After a
trigger the engine disarms until `|gy|` falls back inside `RELEASE`. Do not rely on
`COOLDOWN` to prevent repeat fires — it gates on elapsed time, not on the gesture
ending, so a phone *held* past the threshold (e.g. stood upright in portrait, where
gravity sits on the y axis at ~9.8) will re-fire forever once it lapses. That was a
real shipped bug: a runaway auto-skip loop. Raising `COOLDOWN` is not a fix for it.

All bail-out guards in `onMotion()` must call `TILT.clearSustain()` before returning.
Returning without clearing leaves a stale `sustainStart`, so re-entering the tilted
state seconds later satisfies `now - sustainStart >= SUSTAIN` immediately and fires
with no gesture at all.

`deviceorientation` needs its **own** iOS permission — `DeviceOrientationEvent.requestPermission()`
is separate from `DeviceMotionEvent.requestPermission()`. Without it `_devGamma` never
updates from its initial `90` and the portrait guard above is silently inert.

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
