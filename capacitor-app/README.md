# Wham Bam — native apps (Capacitor)

Wraps the web game as native Android and iOS apps. Capacitor 8, `appId`
`games.whambam.app`.

## The web app is bundled, not fetched

Earlier versions set `server.url = https://whambam.games` in
`capacitor.config.json`, so the app rendered the **live site** and shipped no
web code of its own. That meant the app was always whatever had last been
deployed — and it broke offline.

It now bundles `headband-game-web.html` and its assets. `scripts/copy-web.mjs`
copies them from the repo root into `www/`, and `cap sync` copies `www/` into
each platform. Nothing is hand-maintained in `www/` — the script deletes
anything it did not write.

**After changing the web app, run `npm run sync`.** Skipping it means the apps
keep shipping the previous build.

```bash
npm ci
npm run sync            # copy web assets, then sync both platforms
npm run sync:android    # Android only
npm run sync:ios        # iOS only
npm run open:android    # opens Android Studio
npm run open:ios        # opens Xcode (macOS only)
```

## Auth redirects

`window.location.origin` is `https://localhost` inside the bundled app, which
Supabase rejects and which would bake a dead link into every confirmation and
password-reset email. `authRedirectTo()` in the web app therefore returns
`https://whambam.games/` whenever it detects the native shell.

Those round-trips finish in the system browser, not in the app. Making them
return to the app needs App Links / Universal Links (`assetlinks.json` and
`apple-app-site-association` served from the domain) — not set up yet.

## Build requirements

|          | Needs                                        | Can it build on this Windows machine? |
|----------|----------------------------------------------|---------------------------------------|
| Android  | JDK 21, Android SDK 36                       | Only after installing both            |
| iOS      | macOS, Xcode 16                              | **No** — `xcodebuild` is macOS-only   |

CI covers both:

- `.github/workflows/build-webview-apk.yml` — debug APK + release AAB on every
  push. The AAB is signed only if the `ANDROID_KEYSTORE_BASE64`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD` and `ANDROID_KEY_PASSWORD`
  secrets exist; otherwise it is emitted unsigned with a warning.
- `.github/workflows/build-ios.yml` — compiles iOS unsigned on a macOS runner,
  which proves the project and plugins build. An installable `.ipa` additionally
  needs an Apple Developer account, a distribution certificate and a
  provisioning profile.

## Known native gaps

- **Voice guessing does not work in either native app.** Neither Android WebView
  nor iOS WKWebView exposes `SpeechRecognition`. The UI detects this and now says
  so instead of telling players to "try Chrome". Fixing it properly needs a
  native speech plugin.
- **Purchases** route through RevenueCat when `PLATFORM.isNative`, and through
  Xsolla only on the web. That split is deliberate — Apple and Google require
  their own billing for digital goods.

## Regenerating icons and splash screens

Both platforms previously shipped Capacitor's stock blue logo. The current
artwork is generated from `bgless logo.png` onto the brand background `#0A0500`
(iOS icons must have no alpha channel, so they are flattened).
