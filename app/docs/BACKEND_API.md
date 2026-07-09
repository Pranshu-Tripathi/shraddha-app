# Shanti — Backend API Contract

> **Read this before building any feature that talks to the backend.**
> Shanti is a **thin client**: the app only does routing + device/platform
> actions. **All content and business logic live in the backend.**

**Backend stack:** **FastAPI** (Python) + **object storage/CDN** (Cloudflare R2 /
S3 / GCS) for media. FastAPI chosen for async I/O (many small mobile calls +
concurrent signed-URL generation), Pydantic validation, auto OpenAPI docs, and
Python parity with our other services. **Media is never streamed through the API**
— endpoints return **short-lived signed URLs** to the CDN.

> NOTE: this is a **new** FastAPI service, separate from the `magic` stock-scanner
> project. The earlier `whatsapp_hook` Flask endpoints were scaffolding only.

---

## 0. Auth & Session (no OTP)

The app identifies a user by **phone number only** — no OTP. On first launch it
sends the number and gets a session; **all content is gated on `subscription`**.

- `POST /v1/auth/register` → `{ "phone": "9876543210" }`
  → `{ "token", "phone", "subscription": "active" | "inactive", "expires_at": <iso|null> }`
- App stores `token` in Android Keystore-backed secure storage and sends it as
  `Authorization: Bearer` when calling protected endpoints.
- **Gate (go_router redirect):** no session → `/login`; signed in but `inactive`
  → `/subscribe`; `active` → full app.
- `subscription` is decided by the **backend / payment status**. Payment gateway
  is TBD; the app must not locally activate subscriptions without verified
  backend/payment state.

---

## 1. Conventions

- **Base URL:** `AppConfig.backendBaseUrl` (dev default `http://10.0.2.2:8000`).
  **HTTPS only in production.**
- **Versioning:** all routes under `/v1`.
- **Auth:** `Authorization: Bearer <device_token>` from `POST /v1/auth/register`.
  Recommended: also send a **Play Integrity** token header, verified server-side.
- **Device-context headers** (sent on every request — see §6). Used for
  **campaign prioritization by region (locale + server-side IP-geo, no GPS)** and
  for returning **perfectly-fitted images** (screen resolution).
- **Media:** endpoints return **signed URLs** (short TTL). The app downloads to
  **app-scoped storage** (auto-deleted on uninstall — see §7).
- **Errors:** JSON `{ "detail": "..." }`, standard HTTP status codes.

---

## 2. Wallpaper — दिव्य वॉलपेपर  (`section id: wallpaper`)

AI-generated wallpapers of Hindu gods & goddesses, prioritized by campaign/region.

- `GET /v1/wallpapers/home` → **zero-click** landing payload.
  ```json
  {
    "deities": [
      { "id": "ganesha", "name_hi": "गणेश", "name_en": "Ganesha",
        "priority": 10, "thumb_url": "<signed>", "wallpaper_count": 42 }
    ],
    "featured": [ /* Wallpaper objects, already prioritized */ ],
    "has_more": true
  }
  ```
  Backend orders `deities`/`featured` by **campaign rules keyed on region** (from
  IP-geo + `X-Region`/`X-Locale`). The app shows `featured` immediately and a
  **"और देखें / More gods"** entry when `has_more` (or the deity list is large).

- `GET /v1/wallpapers/deity/{deity_id}?cursor=<c>` → paginated list for one deity.
  ```json
  { "items": [ /* Wallpaper */ ], "next_cursor": "<c|null>" }
  ```

- **Wallpaper object:**
  ```json
  { "id": "wp_123", "deity_id": "ganesha", "title_hi": "...", "title_en": "...",
    "thumb_url": "<signed>", "aspect": 0.46, "tags": ["red","modern"] }
  ```

- `GET /v1/wallpapers/{id}/full?w={W}&h={H}&dpr={D}` → **perfectly-fitted** image.
  The app sends exact device pixel resolution so the backend returns/render an
  image sized for that screen.
  ```json
  { "image_url": "<signed, short TTL>", "width": 1080, "height": 2400,
    "expires_at": "<iso8601>" }
  ```

**App behavior:** tap thumb → full-screen viewer → **one tap sets BOTH home + lock
wallpaper** via `WallpaperManager` (FLAG_SYSTEM | FLAG_LOCK). `SET_WALLPAPER` is
auto-granted — **no runtime prompt**. The full image is downloaded to app-scoped
storage first.

---

## 2b. WhatsApp Status — स्टेटस बनाएँ  (`section id: status`, hero)

Devotional status templates; the user adds their photo and the **backend merges
it onto the template (by id)**.

- `GET /v1/status/templates` → prioritized template list:
  ```json
  { "items": [
    { "id": "morning", "title_hi": "शुभ प्रभात", "title_en": "Good Morning",
      "thumb_url": "<signed>",
      "slot": { "left": 0.18, "top": 0.36, "width": 0.64, "height": 0.36 } }
  ] }
  ```
  `slot` = relative 0..1 region where the user's photo is placed.

- `POST /v1/status/merge` — **multipart**: fields `template_id`, `w`, `h`; file
  `photo`. The backend composites the photo onto the template at the requested
  size and returns the **finished status image bytes** (or a signed URL).

**App behavior:** tap template → capture photo (front camera, `image_picker`) →
upload → post the merged image to **WhatsApp Status** via a native `ACTION_SEND`
intent (FileProvider + `setPackage("com.whatsapp")`, system-chooser fallback).
Saved to app-scoped storage. Until the backend exists, the app composites the
status locally as a fallback.

---

## 3. Ringtone — भक्ति रिंगटोन  (`section id: ringtone`)

- `GET /v1/ringtones/catalog?cursor=<c>`
  ```json
  { "items": [ { "id": "rt_1", "title_hi": "...", "title_en": "...",
                 "duration_s": 31, "preview_url": "<signed>", "tags": ["aarti"] } ],
    "next_cursor": "<c|null>" }
  ```
- `GET /v1/ringtones/{id}/file` → `{ "audio_url": "<signed>", "mime": "audio/mpeg", "duration_s": 31 }`

**App behavior:** download audio to app-scoped storage → set via `RingtoneManager`
+ `MediaStore`. **Requires `WRITE_SETTINGS`** — a one-time grant the user toggles
on a system screen (Android does not allow this silently). The app deep-links them
there once, then sets seamlessly.

---

## 4. Rashifal — राशिफल  (`section id: rashifal`)

- The **12 rashis are STATIC on-device** (key, name_hi/en, symbol, date-range).
- `GET /v1/rashifal/today?lang=hi` → all signs in one call:
  ```json
  { "date": "2026-06-01",
    "items": {
      "mesh": { "summary_hi": "...", "lucky_color_hi": "लाल", "lucky_number": 9, "rating": 4 },
      "vrishabha": { ... }
    } }
  ```
  (Or `GET /v1/rashifal/today?rashi=mesh` for one.)

**App behavior:** single page, all 12 rashi cards; tapping expands the card to show
that sign's short daily summary.

---

## 5. Meditation — ध्यान  (`section id: meditation`)

- `GET /v1/meditation/mantras`
  ```json
  { "items": [
    { "id": "om", "title_hi": "ॐ", "title_en": "Om", "deity": "shiva",
      "duration_s": 180, "audio_url": "<signed>",
      "total_beads": 27, "bead_timings_s": [0, 6.6, 13.2, 19.8, ...] }
  ] }
  ```
  `bead_timings_s`: timestamps (seconds, synced to the audio) at which the
  **rudraksha mala advances one bead**. `total_beads` e.g. 27 / 108.

**App behavior:** ONE lightweight custom-painted **rudraksha mala** animation that
advances a bead at each timestamp while the mantra audio plays (audio cached in
app-scoped storage). No per-mantra animation assets → minimal app size.

---

## 6. Device-context headers (sent on every request)

Used for **campaign prioritization** and **image fitting**. No GPS / no PII.

| Header | Example | Purpose |
|---|---|---|
| `X-App-Version` | `0.1.0+1` | feature gating |
| `X-Platform` | `android` | platform |
| `X-Locale` | `hi-IN` | language + region |
| `X-Region` | `IN` | coarse region (campaigns) |
| `X-Timezone` | `Asia/Kolkata` | scheduling / region hint |
| `X-Screen-W` / `X-Screen-H` | `1080` / `2400` | perfect-fit images |
| `X-Density` | `2.75` | DPR |
| `X-Device-Id` | `<anon uuid>` | anonymous, stable per install |

> **Location strategy:** precise region comes from **server-side IP geolocation**
> combined with `X-Locale`/`X-Region`. We do **not** request GPS permission.
> Keep the **campaign → region** mapping entirely in the backend.

---

## 7. Security expectations

- **HTTPS/TLS only** (HSTS). Optional **TLS certificate pinning** in the app.
- **Auth:** bearer device token + **Play Integrity** attestation verified server-side.
- **Signed URLs** (short TTL) for ALL media; **no public buckets**.
- **Rate limiting** per device/IP.
- **Pydantic** validation on every input; reject unknown fields.
- **No secrets in the app**; store the device token in secure storage.
- **No PII**: region via IP only; anonymous device id; no precise location.

---

## 8. Storage & uninstall cleanup

- **There is no on-uninstall code hook in Android.** The requirement "delete our
  media on uninstall" is satisfied by storing **all downloaded media in app-scoped
  storage** (`getExternalFilesDir(...)`), which the OS **auto-deletes on uninstall**.
- A wallpaper/ringtone the user **applied** system-wide is owned by the OS
  afterward — the app does not (and must not) revert the user's choice on uninstall.
