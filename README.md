# Poke iOS Application

A native iOS wrapper for `https://poke.com/home` built with Swift and WKWebView. It strips away browser chrome, URL bars, and web artifacts to feel like a native iOS app.

---

## Features

- **Native App Feel**: Completely hides the URL bar, browser controls, and web headers.
- **Custom Black Launch Screen**: Displays a centered logo over a pure `#000000` black background with a smooth cross-fade transition on startup.
- **Custom Dashboard Layout**: Option 2 layout engine (`Automations` and `Integrations` side-by-side; `Mail` stretched full-width across the bottom; `Recipes` and `Message` removed).
- **Strict Button Haptics**: Contextual tactile feedback triggered strictly when pressing actual interactive buttons, card items, or avatar links.
- **KreatixDev Credit & Disclaimer**: Blended credit row inserted inside the About sheet pointing to `@KreatixDev` on X, accompanied by a clean disclaimer text.
- **External Route Protection**: Navigation to allowed routes (`/home`, `/about`, `/settings/*`, `/automations/*`, `/inbox/*`, `/integrations/*`) stays in-app. All external links or secondary routes automatically open in native Safari.
- **Clean Keyboard Integration**: Suppresses the Safari `^` `v` `Done` keyboard bar (`inputAccessoryView = nil`) while preserving the blinking typing caret (`caret-color: #007aff`).
- **Strict Anti-Zoom & Anti-Highlight**: Blocks pinch-zoom, double-tap zoom, long-press text selection, and context menus.

---

## Installation & Sideloading Guide

Because this is an unsigned `.ipa` build, you can sideload and sign it on your iOS device using any of the methods below.

### Method 1: Sideloadly (Windows / macOS) — Recommended

1. Download and install **[Sideloadly](https://sideloadly.io/)**.
2. Connect your iPhone to your computer via USB.
3. Download `Poke.ipa` from the **Releases** tab of this repository.
4. Drag and drop `Poke.ipa` into Sideloadly.
5. Enter your **Apple ID** email.
6. Click **Start** to sign and install the app onto your iPhone.
7. On your iPhone, go to **Settings > General > VPN & Device Management**, tap your Apple ID, and select **Trust**.

---

### Method 2: AltStore / SideStore (On-Device Automatic Refresh)

1. Install **[AltStore](https://altstore.io/)** or **[SideStore](https://sidestore.io/)** on your device.
2. Download `Poke.ipa` directly onto your iPhone.
3. Open **AltStore > My Apps**, tap the **+** button at the top left, and select `Poke.ipa`.
4. AltStore will sign and install the app using your Apple ID.

---

### Method 3: TrollStore (iOS 14.0 – 16.6.1 / 17.0) — Permanently Signed

If your iOS device supports **[TrollStore](https://github.com/opa334/TrollStore)**:
1. Download `Poke.ipa` on your iOS device.
2. Open `Poke.ipa` using TrollStore.
3. Tap **Install**.
4. The app will be permanently signed with no 7-day expiration limit.

---

### Method 4: LiveContainer / Scarlet / Esign

1. Download `Poke.ipa`.
2. Import `Poke.ipa` into **LiveContainer**, **Scarlet**, or **Esign**.
3. Sign using your preferred mobile provision or developer certificate and install.

---

## Disclaimer

This application is an independent client wrapper developed by KreatixDev. Not affiliated with Interaction or Cognition.
