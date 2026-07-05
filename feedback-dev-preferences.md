---
name: feedback-dev-preferences
description: "How Usama wants changes approached — corrections, confirmed patterns, UI preferences"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8d33264d-7382-4a44-90a7-812c40255ccb
---

## Read changes.txt / brief docs before coding
When user says "check the file and fix" — always read the file first, summarise all points, then implement all in one pass.
**Why:** User provides consolidated change lists; missing one wastes a round trip.
**How to apply:** Never partially implement a changes list. Do all points or explicitly flag blockers.

## Single-file web app edits — use surgical Edit calls
headband-game-web.html is 2100+ lines. Don't rewrite the file. Use precise `Edit` with enough context to be unique.
**Why:** File is large; full rewrites risk data loss on the 600-word deck arrays.
**How to apply:** Always grep/read the target section before editing. Match exact whitespace.

## User tests live at https://whambam.games
Bug reports come from real device testing on that URL. When fixing bugs, think about actual mobile browser behaviour (iOS Safari, Android Chrome) not just desktop.
**Why:** Several bugs (fullscreen, orientation lock) behave differently on mobile vs desktop.
**How to apply:** For orientation/sensor bugs, consider iOS Safari limitations (no orientation.lock, no fullscreen API support).

## iOS Safari limitations — always account for them
- `screen.orientation.lock()` — NOT supported on iOS Safari
- `requestFullscreen()` — NOT supported on iOS Safari
- `DeviceMotionEvent.requestPermission` IS required on iOS 13+
**Why:** Game is tested on iOS devices; these APIs silently fail.
**How to apply:** Always add fallbacks. For orientation: use `_devGamma` physical sensor check. For fullscreen: show `#fs-btn` as fallback.

## Back buttons should be very visible and interactive
Circle back buttons were rejected — not interactive enough.
Confirmed: pill shape (`border-radius:20px`), "← Go back" text (arrow via `::before`), yellow flash on `:active` with scale(.88).
**Why:** User explicitly asked for more interactivity after first implementation.
**How to apply:** Any new back/nav button should follow the `.back-btn` pill pattern.

## Score/round-over screen = auto-rotate to portrait
Round over screen calls `lockPortrait()` automatically. No blocking overlay — score shows regardless. Device auto-rotates on Android/Chrome.
**Why:** User changed requirement — auto-rotate instead of asking user to manually rotate.
**How to apply:** `showScore()` calls `unlockOrient()` then `lockPortrait()`. No overlay. Score screen shows in any orientation.

## Play-back button (during gameplay) must be at bottom-center
Top-left position overlapped score panels. Bottom-center (`position:fixed;bottom:18px;left:50%;transform:translateX(-50%)`) is confirmed safe in all layouts.
**Why:** Top/left/right positions all conflict with score bubbles in landscape + portrait layouts.
**How to apply:** Don't move #play-back-btn to any corner. Keep bottom-center.

## Fullscreen button shows when not in fullscreen, hides during gameplay
`#fs-btn` bottom-right pill. Hidden when: in fullscreen, on screen-play, on screen-countdown.
**Why:** Fullscreen button during gameplay overlaps game UI.
**How to apply:** Always call `updateFSBtn()` when changing screens.

## Charades mode has landscape/portrait orientation choice
User added landscape option for Charades. `G.charadesOrientation = 'portrait' | 'landscape'`.
In landscape charades: use default HeadsUp landscape layout (side panels), NOT `.charades-mode` class.
**Why:** `.charades-mode` class forces vertical (portrait) layout, breaks landscape charades buttons.
**How to apply:** `classList.toggle('charades-mode', isCharades && G.charadesOrientation !== 'landscape')`.

## HeadsUp tilt: START button required before countdown
After landscape detected on rotate screen, don't auto-start. Show `▶ START!` button.
User taps START → proceed() → countdown → game.
**Why:** User requested explicit confirmation before round starts.
**How to apply:** `waitLandscape()` shows rotate screen, enables `#rotate-start-btn` when landscape detected. `onRotateStart()` triggers proceed().

## Accidental portrait-rotation tilt fix: use _devGamma
When orientation is locked to landscape, `isLandscape()` always returns true. Must use physical sensor.
`_devGamma = |DeviceOrientationEvent.gamma|`. Block tilt when `_devGamma < 35`.
**Why:** Without this, tilting phone to portrait during gameplay continuously fires skip/correct.
**How to apply:** Guard is in `onMotion()`: `if(_devGamma < 35) return;` — keep this, don't remove.

## Word count on deck cards: don't show raw word count
Showing "600 words" was removed. Instead show: "50 free" (no sub), "300 entries" ($0.99 sub), "600 entries" (All Access).
**Why:** User doesn't want to show total inventory until paid.
**How to apply:** Use `getDeckCntLabel(d)` helper in all deck grid renders.

## LET'S GO!!! countdown
When countdown hits 0: full yellow screen (#F7C948), big bold "LET'S GO!!!" text, no rocket emoji.
CSS classes `.cdscreen-go` + `.cdnum-go` toggled in JS. Reset after 700ms before starting game.
**Why:** User wanted more impactful visual for game start.

## Category label: green box above word card, word uppercase
`#w-deck` moved outside `.wcard` into `.wdeck-box` (green #2EE68A pill). Word text has `text-transform:uppercase`.
**Why:** User requested category visible separately in green, word in caps for easier reading.
