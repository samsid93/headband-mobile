# Wham Bam — Game Enhancement Plan

> Implementation plan for all items in `suggestion.txt` (2026-07-04 audit).
> Target file: `headband-game-web.html` (single-file app — surgical edits only, never rewrite).
> Rule: every pass must leave the game fully playable. Test on phone after each pass.

---

## Pass 1 — Critical Fixes (est. 30 min)

### 1.1 Purge navy palette remnants
**Where:** CSS block, ~10 selectors.

| Selector | Current | Replace with |
|----------|---------|--------------|
| Canvas `draw()` fill | `#06060E` | `#0A0500` |
| `.sbubble` | `rgba(14,10,44,.9)` | `rgba(26,12,0,.9)` |
| `.tpill` | `rgba(22,18,64,.9)` | `rgba(34,18,0,.9)` |
| `#play-back-btn` | `rgba(7,5,26,.85)` | `rgba(18,8,0,.85)` |
| `.demo-phone` | `rgba(30,24,72,0.95)` | `rgba(46,24,0,.95)` |
| `.tbg` stroke | `rgba(30,24,82,.9)` | `rgba(46,24,0,.9)` |
| `.unlock-card` | `rgba(14,10,44,.97)` | `rgba(18,8,0,.97)` |
| `.fp-modal-wrap` | `rgba(14,10,44,.98)` | `rgba(18,8,0,.98)` |
| Auth modal backdrop | `rgba(7,5,26,0.92)` | `rgba(10,5,0,0.92)` |
| How-to modal backdrop | `rgba(6,6,14,.92)` | `rgba(10,5,0,.92)` |
| `#fs-btn` | `rgba(14,10,44,.9)` (check) | `rgba(18,8,0,.9)` |

**Verify:** screenshot home, play, score, modals — no cool-blue surfaces left.

### 1.2 Fix AudioContext leak in `beepNewWord()`
**Where:** `beepNewWord()` (~line 2024).
**Change:** delete its private `new AudioContext()`; expose a `beep()` or `newWord()` method from the SFX module (which already lazily creates one shared context) and call `SFX.newWord()` instead.
**Verify:** play 20+ words on iPhone Safari — sound must keep working.

### 1.3 Mute toggle (suggestion #10 / 2.1)
**Where:** SFX module + home screen.
- Add `let muted = localStorage.getItem('hb_muted')==='1'` inside SFX; guard `beep()` with `if(muted)return`.
- Expose `SFX.toggleMute()` returning new state.
- Add small 🔊/🔇 pill button top-right of home screen (mirror `.back-btn` styling).
**Verify:** toggle persists across reload; all SFX silent when muted.

---

## Pass 2 — Game Feel (est. 2-3 h)

### 2.1 Streak/combo system (#1)
**State:** add `G.streak = 0`.
- `doCorrect()`: `G.streak++`; `doSkip()` and round start: `G.streak = 0`.
- At streak 3, 5, 8: show banner overlay (reuse `.tov` overlay pattern) — `🔥 ON FIRE! x3`.
- SFX: pass streak to `SFX.correct(streak)` → raise base frequencies ~8% per streak step (cap at x8).
- Small streak counter chip on word card top-left (`#w-streak`), hidden below 2.
- **Color ladder (4.5):** banner background yellow (3) → orange (5) → red (8) → purple (10+).

### 2.2 Final-10-seconds tension mode (#2)
- `startTimer()` tick: at `G.sec === 10` add class `tension` to `#screen-play`; remove in `endRound()`.
- CSS `.tension::after`: fixed inset red vignette (`radial-gradient(transparent 55%, rgba(255,45,85,.25))`), pulsing via keyframes (compositor-safe: opacity only).
- Timer ring: add throb keyframe (scale 1→1.08) on `.tring` while `.tension`.
- SFX: `tensec()` already exists — add soft heartbeat double-beep each second under 10 (reuse countdown beep at low volume, 2 quick pulses).

### 2.3 Team hand-off splash (#3)
**Where:** `playAgain()` / between-turn path in team mode.
- New overlay div `#team-splash` (fullscreen, z-index below countdown): big team dot color wash + `📱 Pass the phone to {team}!` + `Tap when ready` button.
- Flow: score screen → Play Again (team mode) → splash → ready screen.
- Background = team color at 20% over warm black; team name in team color.
- Team colors already defined: blue `#0088FF`, orange `#FF6B00`, green `#00E87A`, purple `#CC44FF`, pink `#FF3399`, yellow `#FFD60A`.

### 2.4 Word card transition (#4)
- Wrap word swap in `showWord()`: add class `wswap-out` (translateX(-30px) + opacity 0, 120ms), set new text, then `wswap-in` (from +30px).
- Transform/opacity only — compositor-safe.
- Skip animation when tilt fires rapidly (if previous animation still running, jump-cut).

---

## Pass 3 — Color Identity (est. 1-2 h)

### 3.1 Deck-tinted gameplay (4.1)
- Add `color` field to each deck object in `DECKS` (hex matching existing per-deck card colors: movies `#DC2D2D`, animals `#1EC850`, tv `#AA28FF`, famous `#FFB400`, food `#FF6900`, actitout `#FF286E`, sports `#0082FF`, jobs `#00BEA5`, bollywood `#E600B4`, kids `#3CDC64`, crazy `#8C3CF0`).
- In `beginRound()`: set CSS custom property `--deck` on `#screen-play` → used by `.wdeck-box` background and `.wcard` border.
- Keep card body yellow (readability) — only border + category pill take deck color.

### 3.2 Countdown color ramp (4.2)
- `runCountdown()` tick: 3 = yellow gradient (current), 2 = orange (`#FF9500→#FF6B00`), 1 = red-pink (`#FF2D55→#FF3399`). LET'S GO frame unchanged.
- Implement as classes `.cd-3/.cd-2/.cd-1` on `#cd-num`.

### 3.3 Team-colored rounds (4.3)
- Reuse `--deck` pattern: set `--team` custom property on `#screen-play` during team turns.
- Timer ring stroke (above 50% remaining), team bar text, correct-flash tint use `var(--team)`.
- Classic mode: unchanged (yellow).

### 3.4 Score podium colors (4.4)
- `showScore()` team results: rank 1 card gets gold border + `--gY` glow (exists via `.winner`), add silver (`#B0B0C0`) border rank 2, bronze (`#CD7F32`) rank 3.
- Rank emoji: 🥇🥈🥉.

---

## Pass 4 — Polish & Retention (est. 2-3 h)

### 4.1 Score count-up (#5)
- `showScore()`: animate score/correct/skip numbers 0→value over 800ms (requestAnimationFrame, ease-out).
- New personal best: fire existing `spawnParticles`-style confetti burst full-screen + `SFX.winner()`.

### 4.2 Haptics (#6)
- Helper `buzz(pattern)`: `if(navigator.vibrate)navigator.vibrate(pattern)`.
- correct `[30]`, skip `[15,30,15]`, tensec `[10]`, timeup `[80,40,80]`.
- No-op on iOS web (API absent) — Capacitor Haptics plugin later for app build.

### 4.3 Golden word (#8)
- In `beginRound()` after slicing `G.words`: mark last entry `golden:true`.
- `showWord()`: if golden → card gold gradient + `⭐ GOLDEN WORD — 2x!` hint.
- `doCorrect()`: golden → `G.correct += 2` and overlay `✓ +2 GOLDEN!`.
- Skip-deduct unaffected.

### 4.4 Daily featured deck (#9)
- `const daily = DECKS[(new Date().getFullYear()*372+new Date().getMonth()*31+new Date().getDate()) % DECKS.length]`.
- "⭐ Today's Deck" ribbon on that deck card in setup grid + home screen chip under Play button.
- Free decks only (filter premium unless unlocked).

### 4.5 Local achievements (#7)
- `localStorage` key `hb_achv` (JSON array of ids).
- Check in `endRound()`: `perfect_round` (0 skips, ≥5 words), `speed_demon` (≥10 correct), `on_fire` (streak ≥8), `first_win` (team mode win), `century` (100 lifetime corrects — track `hb_total_correct`).
- Toast on unlock (reuse `showToast`, prefix 🏅). Achievements list rendered at bottom of leaderboard screen.

---

## Anytime — Hygiene

| Item | Fix |
|------|-----|
| 1.3 XSS | Add `esc(s)` helper (`s.replace(/[&<>"']/g, …)`); use in `renderPlayers()` + any Supabase display_name injection |
| 1.4 Canvas sleep | In `goTo()`: `bgActive = ['screen-home','screen-setup',…].includes(id)`; canvas `draw()` early-returns rAF when false; floaty spawner checks same flag |
| 1.5 Defer SDK | Add `defer` to Supabase script tag (verify `getSharedSB()` guards handle late load — they do) |
| 1.6 Styled confirm | Replace `confirm()` in `clearLB()` with small modal (reuse `.fp-modal-wrap` pattern) |
| 1.7 OG tags | Add `<meta property="og:title/description/image">` + `<meta name="description">` in head; og:image = logo.png absolute URL |

---

## Constraints (from CLAUDE.md — do not violate)

- Surgical `Edit` calls only; never rewrite file (600-word deck arrays).
- Compositor-safe animation only (transform/opacity/clip-path).
- `#play-back-btn` stays bottom-center. Back buttons stay pill-shaped.
- Score screen stays portrait. `updateFSBtn()` on every screen change.
- Don't touch tilt guard `if(_devGamma < 35) return;`.
- No backend-dependent features until Phase 0.

## Testing checklist per pass

- [ ] iPhone Safari (worst-case: no orientation.lock, no requestFullscreen)
- [ ] Android Chrome
- [ ] Capacitor WebView (fs-btn hidden, AndroidBridge orientation)
- [ ] Team mode 3+ teams full game loop
- [ ] Charades portrait + landscape
- [ ] Muted state persists, no console errors
