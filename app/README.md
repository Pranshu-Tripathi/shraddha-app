# Shanti — भक्ति App

A **bhakti (Hindu devotional) Android app** for Tier‑1.5/2 India, built for
first‑time / low‑literacy smartphone users: large icons, Devanagari‑first text,
soft welcoming colours, and a temple‑like landing.

Flutter 3.44 / Dart 3.12 · **Android only.**

> **🛑 For any AI session / contributor:** read **[`CLAUDE.md`](CLAUDE.md)** and
> **[`docs/BACKEND_API.md`](docs/BACKEND_API.md)** first. They define the
> thin‑client rule, the backend contract, and the Android platform realities.

---

## Core principle — thin client

The app holds **routing + device/platform actions only. No business logic.**
All content and decisions come from the backend (**FastAPI** + CDN signed URLs;
see `docs/BACKEND_API.md`). Device/platform glue (setting wallpaper, ringtone,
local storage) necessarily lives in the app — that's not business logic.

```
lib/
├── main.dart / app.dart        # entry, MaterialApp.router, ServicesScope
├── config/   app_config.dart   # backend base URL + timeouts
│            sections.dart       # the home sections (presentation config)
├── theme/    app_colors.dart    # soft, welcoming palette
├── router/   app_router.dart    # go_router table (URL → screen)
├── api/      api_client.dart     # one dio client; errors → ApiException
│            services/…           # one service per backend area (call → DTO)
├── models/                       # DTOs (fromJson/toJson only)
├── widgets/  temple_header.dart  # soft abstract divine landing header
└── screens/                      # thin UI per section
```

## Sections (home)

| Hindi | English | id | What |
|---|---|---|---|
| दिव्य वॉलपेपर | Divine Wallpapers | `wallpaper` | AI god/goddess wallpapers; one‑tap set home+lock |
| भक्ति रिंगटोन | Bhakti Ringtones | `ringtone` | Devotional ringtones; set as ringtone |
| राशिफल | Daily Rashifal | `rashifal` | 12 rashis (static); tap to expand daily summary |
| ध्यान | Meditation | `meditation` | Mantras + one light backend‑timed mala animation |

The landing is a vertically scrollable list of these sections under a soft,
temple‑like header (abstract watercolor + glowing ॐ + marigold toran).

## Android platform realities (important)

- **Wallpaper (home+lock): one tap, no prompt** — `SET_WALLPAPER` is auto‑granted.
- **Ringtone: needs `WRITE_SETTINGS`** — a one‑time user toggle on a system screen.
- **No on‑uninstall hook exists** — we store all media in **app‑scoped storage**
  so the OS auto‑deletes it on uninstall.
- **Location:** no GPS prompt — send locale/region/timezone, geolocate by **IP**
  on the backend (campaign prioritization stays server‑side).

## Running

```bash
# new terminal (PATH is set in ~/.zshrc)
flutter emulators --launch shanti_pixel
cd ~/Desktop/shanti && flutter run
# physical device / LAN backend:
flutter run --dart-define=BACKEND_BASE_URL=http://<ip>:8000
```

## Toolchain (this Mac, Apple Silicon)

Flutter `~/development/flutter` · Android SDK `~/Library/Android/sdk` ·
JDK 17 `~/Library/Java/jdk-17*` · Android Studio `/Applications/Android Studio.app` ·
AVD `shanti_pixel`. PATH/`ANDROID_HOME`/`JAVA_HOME` exported in `~/.zshrc`.

## Before release

- Keep the production `applicationId` stable once uploaded to Play.
- Switch backend to HTTPS and remove `usesCleartextTraffic` (dev only).
