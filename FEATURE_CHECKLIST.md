# Feature Checklist: Headband Mobile Parity

## 1. UI Screens & Navigation
- [ ] **Home Screen:**
    - Animated background (orbiting orbs)
    - App title ("HeadBand!"), subtitle, and badge labels
    - "Play Now" and "Leaderboard" buttons
- [ ] **Setup Screen:**
    - Game Mode selector (Classic vs. Team)
    - Deck selection grid with premium/lock indicators
    - Timer selection stepper and presets
    - Control toggles (Tilt, Voice, Skip-penalty)
    - "Continue" button
- [ ] **Team Setup Screen:**
    - Team names, player list management, and skip-penalty toggle
- [ ] **Rotate/Tilt Tutorial Screen:**
    - Animated phone demos showing tilt gestures
    - Landscape detection
- [ ] **Ready Screen:**
    - Game start button with countdown and tip cards
    - Permission request cards (Tilt, Mic)
- [ ] **Countdown Screen:**
    - Large animated countdown (3, 2, 1)
- [ ] **Game Screen:**
    - Landscape layout
    - Timer (ring arc)
    - Word card with tilt indicators
    - Correct/Skip buttons
    - Voice/Tilt feedback pills
- [ ] **Score Screen:**
    - Round breakdown/results
    - Leaderboard persistence
- [ ] **Unlock/Ad Overlay:**
    - Unlock premium deck logic (payment/ad placeholder)

## 2. Game Mechanics
- [ ] Round timer with automatic time-up trigger
- [ ] Skip penalty calculation (if enabled)
- [ ] Score tracking for teams
- [ ] Deck shuffling
- [ ] Persistent leaderboard (LocalStorage/SharedPreferences)

## 3. Sensors & Controls
- [ ] **Tilt Sensors:**
    - Landscape orientation enforcement
    - Device orientation mapping: Correct (top-up) vs. Skip (bottom-up)
    - Threshold-based event triggering with cooldown
- [ ] **Voice Recognition:**
    - Speech-to-text integration
    - Voice command mapping (Correct: Yes, Skip: No, etc.)
    - Visual feedback during listening/recognizing

## 4. Audio & Haptics
- [ ] **SFX Engine:**
    - Tap, Correct, Skip, Countdown, Time-up, Winner, etc.
- [ ] **Background:** Consistent with web app feel

## 5. CI/CD & Build
- [ ] GitHub Actions workflow for debug APK generation
