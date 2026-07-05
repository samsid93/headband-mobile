---
name: project-headband
description: "HeadBand! party game — full project context, file locations, current state, architecture"
metadata: 
  node_type: memory
  type: project
  originSessionId: 8d33264d-7382-4a44-90a7-812c40255ccb
---

## What it is
HeadBand! — forehead-guessing party game (charades-style). Three platforms:
- **Web:** `headband-game-web.html` (single-file, live at https://whambam.games)
- **Mobile:** Flutter app in `mobile/lib/`
- **Admin:** `headband-admin.html` (UI prototype only, no backend yet)

## Execution plan
`EXECUTION_PLAN.md` — Version 3.0. Source of truth.
- **Phase A (Web):** ✅ COMPLETE
- **Phase B (Flutter):** Not started
- **Phase D (Admin backend):** Not started
- **Phase 0 (Backend infra):** Not started

## Web app — current state (headband-game-web.html, ~2140 lines)

### Decks (11 total, 600 words each)
Free: Movies, Animals, TV Shows, Celebrities, Food & Drink, Act It Out, Sports, Jobs
Premium: Bollywood Movies, Kids & Family, Crazy Impossible Movie Names
Words hardcoded (no API yet). Bollywood Songs deck was removed.

### Game modes
- **HeadsUp:** Landscape, tilt + voice to score
- **Charades:** Portrait OR Landscape (user picks orientation), buttons only

### Key features implemented
- Tilt engine: threshold 4.5, 250ms sustain, 1500ms cooldown, dynamic axis sign (landscape-primary vs secondary)
- `_devGamma` guard: blocks tilt when `|gamma| < 35°` — prevents portrait-rotation accidental triggers even when screen is orientation-locked
- Voice recognition (Chrome only)
- Teams (2–6), Classic and Team modes
- Paywall: 50 free lifetime words → 30s ad → 50 words/24hr → $0.99/yr 300 words
- Premium decks: 60s ad → 100 words/24hr → $0.99/yr 300 words
- All Access: $4.99/yr unlimited
- Interstitial ads between rounds (every 3 turns, 90s cooldown, 2 grace rounds)
- Leaderboard (localStorage)
- Wake lock, animated background, SFX

### Orientation flow
- HeadsUp: `waitLandscape(proceed)` → shows screen-rotate → user taps "▶ START!" button → countdown → gameplay
- Charades portrait: skips landscape check, starts directly
- Charades landscape: goes through waitLandscape same as HeadsUp
- Score screen: forces portrait via `lockPortrait()` — no blocking overlay, score shows regardless

### Fullscreen
- First click anywhere → tries `requestFullscreen()`
- `#fs-btn` (bottom-right pill) shows when not in fullscreen, hidden during gameplay/countdown
- Button disappears in fullscreen, reappears if user exits

### Back buttons
All screens have `← Go back` pill-shaped buttons (`.back-btn` class).
- `.back-btn`: fixed top-left, pill shape, `::before` injects arrow, yellow flash on `:active`
- `#play-back-btn`: fixed bottom-center during gameplay, calls `endRoundEarly()`

### Score/Round-over screen
- Forces portrait: `lockPortrait()` on showScore()
- Score rotate overlay removed — `lockPortrait()` handles auto-rotation, score shows in any orientation

## Word count display on deck cards
- No sub: `50 free` (free decks) or `` empty (premium)
- $0.99 sub active: `300 entries`
- $4.99 All Access: `600 entries` (actual word count)
- Helper: `getDeckCntLabel(d)`

## Key localStorage keys
`hb_fw_{id}`, `hb_tmp_{id}`, `hb_sub_{id}`, `hb_ptmp_{id}`, `hb_psub_{id}`, `hb_allaccess_exp`, `hb_unlocked`, `hb_lb`, `hb_howtoplay_seen`

## Flutter app — current state
Screens exist (HomeScreen, SetupScreen, TeamSetupScreen, ReadyScreen, GamePlayScreen, ScoreScreen).
7 stub decks in mock_data.dart. B1–B10 not implemented.
Services in place: audio_service, sensor_service, voice_service, leaderboard_service.

## Admin dashboard
headband-admin.html — UI prototype only. All data in localStorage, no backend connection.

**Why:** Backend (Phase 0) must be built before admin or Flutter can connect to real data.
**How to apply:** Don't suggest backend-connected features until Phase 0 is done.
