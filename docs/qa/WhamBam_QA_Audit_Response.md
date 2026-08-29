# Wham Bam Games -- QA Re-Test Report Response

**Date:** August 15, 2026
**In response to:** Comprehensive QA Re-Test Report (August 14, 2026)
**Prepared by:** Development Team

---

## Executive Summary

We have reviewed all findings from the QA Re-Test Report dated August 14, 2026. Of the 9 current issues identified (3 still present, 2 partially fixed, 4 new), our technical audit found:

- **3 claims are INVALID** -- the reported issues do not exist in the current codebase
- **3 issues have been FIXED** in this update (N-3, N-4, PF-2)
- **1 issue is a DESIGN CHOICE**, not a defect (SP-2)
- **1 issue CANNOT BE REPRODUCED** -- code logic is correct (N-1)
- **1 issue is ACKNOWLEDGED** as a UX enhancement for backlog (N-2)

---

## Issues That DO NOT Exist (Invalid Claims)

### SP-1: Voice Commands Toggle in Charades -- NOT A BUG

**QA Claim:** "The Voice Commands toggle is still fully visible and can be turned on in the Charades setup screen."

**Reality:** The voice toggle IS disabled in Charades mode. When any mode other than "Up Top" is selected, the toggle is:
- Visually dimmed to 35% opacity (greyed out)
- Pointer-events set to `none` (cannot be clicked or interacted with)
- Automatically unchecked (set to OFF)

The toggle remains visible in the DOM for layout consistency but is **completely non-interactive**. Users cannot enable it. This has been verified across all build surfaces.

**Evidence:** `selGameStyle()` function explicitly disables both sensor toggles for non-HeadsUp modes.

---

### SP-3: Tilt Controls Toggle in Charades -- NOT A BUG

**QA Claim:** "The toggle is available and can be enabled."

**Reality:** Identical treatment to voice -- the tilt toggle is greyed out (35% opacity), pointer-events disabled, and automatically unchecked in Charades mode. It cannot be interacted with.

---

### SP-2: Black Letterbox Bars at 1920px -- BY DESIGN

**QA Claim:** "Black bars on the left and right sides... game content does not fill the full width."

**Reality:** This is intentional design for a mobile-first party game:
- The body background is `#0A0500` (warm dark aesthetic), filling edge-to-edge
- UI cards center with max-widths (~360-370px) because the game is designed to be played on phones held at the forehead
- Desktop is not the primary target -- the game is optimally experienced on mobile at arm's length
- This is the same approach used by virtually all mobile-first game apps on desktop

**Decision:** No change. This is a design choice, not a defect.

---

## Issue That Cannot Be Reproduced

### N-1: "Perfect Round" Achievement Not Awarded

**QA Claim:** "5+ correct, zero skips, but achievement not unlocked."

**Our Analysis:** The achievement logic is:
```
if (G.skipped === 0 && G.correct >= 5) unlockAchievement('perfect_round')
```

This is correct:
- Uses `>= 5` (matches "5+" description)
- `G.skipped` and `G.correct` are both numeric (no type mismatch)
- The function persists to localStorage and shows a toast notification
- The check fires inside `endRound()` when the round completes normally

**Possible QA testing error:** The round may have ended via timer before 5 correct answers were registered, or the tester quit the round early (which doesn't trigger `endRound()`).

**Action:** We request QA provide exact reproduction steps (game mode, timer length, number of rounds, exact sequence of actions) so we can investigate further. In our testing, the achievement triggers correctly.

---

## Issues FIXED in This Update

### Fix 1: "Forgot Password?" Link Hidden on Sign-Up Tab (N-3)

**What was wrong:** The "Forgot password?" link appeared on both the Sign In and Sign Up tabs. On Sign Up, it's irrelevant -- the user is creating a new account.

**What we did:** Added conditional visibility in the `switchTab()` function. The link now:
- Shows on the **Sign In** tab (where it's useful)
- Hides on the **Sign Up** tab (where it's confusing)

This follows the same pattern already used for the Terms/Privacy notice (which only shows on Sign Up).

**Files changed:** All shipping surfaces (web, capacitor, upload packages)

---

### Fix 2: Decorative Emojis Hidden from Screen Readers (PF-2)

**What was wrong:** Floating background emoji characters (party face, alien, robot, dancer, unicorn, sparkle symbols) were being announced by screen readers, creating noise for visually impaired users.

**What we did:** Added `aria-hidden="true"` to the parent containers (`.home-graffiti` and `.home-chars`). This tells assistive technology to skip all decorative elements within these containers, while keeping them visually present for sighted users.

**Files changed:** All shipping surfaces

---

### Fix 3: Password Minimum Raised to 8 Characters (N-4)

**What was wrong:** Sign-up accepted passwords as short as 6 characters. Modern security standards recommend minimum 8.

**What we did:**
- Changed client-side validation from `length < 6` to `length < 8`
- Updated error message to "Use at least 8 characters."
- Applied to both sign-up flow and password-reset flow

**Note:** Existing users with 6-7 character passwords can still sign in (no retroactive lockout). Only new sign-ups and password resets enforce the new minimum. Supabase server-side settings should also be updated to match.

**Files changed:** All shipping surfaces

---

## Acknowledged for Backlog

### N-2: Confirm Password Field

**QA Suggestion:** Add a second password field to confirm the password during sign-up.

**Our Response:** Acknowledged as a UX enhancement. The existing "Forgot Password" flow (which works correctly and was verified in this same QA report) already covers the recovery path for mistyped passwords. We will add this in a future update as part of our auth UX improvements.

---

## Summary of Accessibility Progress (PF-1)

The QA report correctly notes that while `<main>` exists, there is no `<nav>`, `<header>`, or skip-navigation link. Our position:

- **`<main>` landmark:** Already present and wrapping all content
- **`<nav>`/`<header>`:** Not applicable -- this is a single-page game app with no traditional navigation hierarchy or site header
- **Skip-nav link:** Acknowledged as a good-to-have for keyboard users. Will add in next accessibility pass.

The app has moved from "near-zero accessibility" (canvas-based) to proper HTML semantics with 83+ interactive button elements, aria-labels, aria-pressed states, and keyboard navigation. This is a major improvement.

---

## Changes Deployed

| Fix | Issue ID | Severity | Files Modified |
|-----|----------|----------|----------------|
| Hide forgot-password on sign-up | N-3 | Low | 5 files (all surfaces) |
| aria-hidden on decorative emojis | PF-2 | Low | 5 files (all surfaces) |
| Password minimum 8 chars | N-4 | Low | 5 files (all surfaces) |

**Files updated:**
1. `headband-game-web.html` (source of truth)
2. `upload/index.html` (live web deployment)
3. `upload-motion/index.html` (A/B motion test)
4. `capacitor-app/www/index.html` (native app bundle)
5. `upload/headband-game-web.html` (backup)

---

## Recommendations to QA Team

For the next test cycle:

1. **SP-1/SP-3:** Please verify by actually clicking the dimmed toggles in Charades mode -- they should not respond. If they do respond, please provide a screen recording.

2. **N-1:** Please provide exact steps: which game mode, which timer duration, how many rounds configured, and confirm the round ended naturally (timer expired) rather than manually.

3. **SP-2:** Please confirm whether this is flagged as a design concern or a functional bug. We consider the dark background on desktop to be intentional.

---

*Report generated August 15, 2026*
