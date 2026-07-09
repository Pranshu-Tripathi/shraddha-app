# Play Store Security Review - Shraddha/Shanti Android App

Date: 2026-07-09
Last remediation update: 2026-07-09

Scope reviewed:
- Flutter app under `app/`
- Android manifest and Gradle release config
- Dart auth/session, API client, media download/upload, and native Android platform code

Notes:
- This is a static review, not a full penetration test or Play Console pre-launch report.
- The backend projects were not present in this workspace, so backend-side auth, storage, signed URL generation, and Play Integrity verification were not audited.
- Workspace instructions asked to initialize CodeGraph before deep code work, but `codegraph` was not available in this shell (`command not found`), so this review used direct source inspection.

## Executive Summary

The app is closer to Play Store readiness after remediation, but it is not fully ready until backend/payment validation and Play policy declarations are complete.

Fixed in the current working tree:

1. Release builds no longer use the debug signing config.
2. A GitHub Actions release workflow builds a signed APK and uploads it to GCS.
3. Release cleartext traffic was removed from the main manifest.
4. Session data moved from SharedPreferences to Keystore-backed secure storage.
5. Android backup/data extraction is explicitly disabled/excluded.
6. FileProvider sharing was narrowed to generated media only.
7. The app no longer locally mocks active subscriptions or payment success.
8. The production `applicationId` moved off `com.example.*`.

Still requiring backend/product/Play Console work:

1. The backend must enforce auth, subscription, payment verification, and Play Integrity checks.
2. Payment/subscription activation needs a real verified flow.
3. Backend-provided media URLs now get HTTPS/size/content-type checks, but expected CDN/storage hosts should still be allowlisted once final infrastructure is known.
4. `WRITE_SETTINGS` and wallpaper/ringtone behavior still need Play policy review and clear disclosures.
5. Play Data Safety disclosures still need to cover phone number, device ID, locale/device-context headers, selfie upload, generated media, and backend logging.

## Findings

### Critical - Release build uses the debug signing key

Status: Fixed in `app/android/app/build.gradle.kts` and guarded by `.github/workflows/android-release.yml`.

Evidence:
- `app/android/app/build.gradle.kts:29-32`

Original finding: the `release` build type used `signingConfigs.getByName("debug")`. The release build now uses a dedicated release signing config backed by CI/local environment variables and fails release tasks when signing values are missing.

Impact:
- Play release readiness blocker.
- Anyone with the debug key could potentially produce builds that appear to be signed by the same certificate outside normal release controls.

Recommended fix:
- Create a real upload signing key or use Play App Signing.
- Store signing credentials outside the repo, for example in `key.properties` excluded by `.gitignore` or CI secrets.
- Configure `release.signingConfig` to use the release/upload key only for release builds.

### Critical - Client-side mocked auth/subscription grants everyone active access

Status: Partially fixed. The app now calls `POST /v1/auth/register`, stores the returned token securely, sends bearer auth on backend calls, and no longer fakes payment/subscription activation. Final security still depends on the backend verifying subscription/payment state.

Evidence:
- `app/lib/api/services/auth_service.dart:3-5`
- `app/lib/api/services/auth_service.dart:10-13`
- `app/lib/api/services/auth_service.dart:23-33`
- `app/lib/state/session_controller.dart:72-77`

Original finding: `AuthService` was mocked and returned active subscriptions for arbitrary phone numbers. It now calls the backend register endpoint and no longer fakes subscription activation. The backend must still issue trustworthy tokens and enforce payment/subscription state.

Impact:
- Anyone can access subscribed/premium behavior without paying.
- Identity can be spoofed with only a phone number.
- Backend APIs cannot safely trust this app state.
- Play review may reject subscription/payment behavior if it bypasses proper purchase verification.

Recommended fix:
- Replace the mock service with real backend auth.
- Require server-issued, signed, non-predictable tokens.
- Verify subscription/payment state server-side, preferably using Google Play Billing purchase tokens if monetization uses Play billing.
- Never trust `subscription` state stored only on-device.

### High - Cleartext traffic is enabled for the whole app

Status: Fixed for release. Cleartext is only present in debug/profile manifests for development.

Evidence:
- `app/android/app/src/main/AndroidManifest.xml:7-11`
- `app/lib/config/app_config.dart:3-12`

Original finding: the main manifest set `android:usesCleartextTraffic="true"`. The release manifest no longer allows cleartext traffic; only debug/profile manifests keep it for development.

Impact:
- User data, phone identifiers, device headers, and media requests can be exposed or modified on hostile networks when HTTP is used.
- Play Console and security scanners commonly flag global cleartext allowance.

Recommended fix:
- Keep `android:usesCleartextTraffic="true"` out of the release manifest.
- If local development needs HTTP, keep it only in `debug/AndroidManifest.xml` or use a debug-only network security config.
- Enforce `https://` in `AppConfig.backendBaseUrl` for release builds.

### High - Session token, phone number, subscription state, and device ID are stored in plaintext

Status: Fixed in app code. Session phone/token/subscription and device ID now use `flutter_secure_storage` with Android encrypted shared preferences.

Evidence:
- `app/lib/state/session_controller.dart:23-26`
- `app/lib/state/session_controller.dart:48-52`
- `app/lib/state/session_controller.dart:100-106`

Original finding: the app persisted phone number, token, subscription state, and a stable device ID in SharedPreferences. These values now use Keystore-backed secure storage.

Impact:
- Token theft on compromised devices.
- Privacy exposure of phone number and stable device ID.
- Subscription state can be tampered with locally if any app data modification path exists.

Recommended fix:
- Use Android Keystore-backed secure storage, for example `flutter_secure_storage`, for tokens.
- Store only low-risk display state outside secure storage.
- Treat local subscription state as cache only and revalidate server-side.

### High - Android backup/data extraction is not explicitly restricted

Status: Fixed in the main manifest and `data_extraction_rules.xml`.

Evidence:
- `app/android/app/src/main/AndroidManifest.xml:7-11`
- `app/lib/state/session_controller.dart:100-106`

The application element does not set `android:allowBackup`, `android:fullBackupContent`, or Android 12+ `android:dataExtractionRules`. Because session data is stored locally, backup defaults can leak phone/session/device identifiers into device/cloud backup flows.

Impact:
- Tokens and identifiers may be backed up or restored to another device.
- Privacy and account-boundary issues if restored data is trusted.

Recommended fix:
- Add backup/data extraction rules before release.
- Either set `android:allowBackup="false"` or exclude sensitive SharedPreferences/files from backups.
- Do not rely on restored local session state without backend revalidation.

### High - Special permissions and sensitive actions need Play policy justification

Status: Still open. Code keeps the features user-initiated, but Play policy/declaration work remains.

Evidence:
- `app/android/app/src/main/AndroidManifest.xml:3-6`
- `app/android/app/src/main/kotlin/com/example/shanti/MainActivity.kt:68-116`

The app requests `SET_WALLPAPER` and `WRITE_SETTINGS`. `WRITE_SETTINGS` is a special permission and the app opens Android settings to request it for ringtone changes. These features may be legitimate, but they increase Play review and user trust risk.

Impact:
- Play review may require a clear user-facing purpose and policy compliance.
- If compromised, these capabilities let the app alter device settings/wallpaper/ringtone.

Recommended fix:
- Keep these flows user-initiated only, with clear UI context.
- Verify the Play Console declaration/permission policy requirements for special app access.
- Consider whether ringtone setting can be optional or moved behind a separate explicit action.

### Medium - Backend-provided URLs are used without scheme/host/size validation

Status: Partially fixed. Media upload/download now enforces HTTPS in release builds, response size limits, and content-type prefixes. Host allowlisting should be added after final CDN/storage hosts are known.

Evidence:
- `app/lib/api/services/status_service.dart:29-42`
- `app/lib/screens/wallpaper_view_screen.dart:59-73`
- `app/lib/screens/ringtone_screen.dart:168-182`
- `app/lib/screens/status_result_screen.dart:87-101`

The app accepts signed upload/download URLs from the backend and uses `HttpClient` directly. It does not verify that URLs are HTTPS, belong to expected storage/CDN hosts, have acceptable content types, or are within maximum byte limits before writing to disk or processing media.

Impact:
- A compromised backend response or interception path could make the app upload/download to unexpected hosts.
- Large responses could consume disk or memory.
- Unexpected content could be saved as media and later shared or passed into platform APIs.

Recommended fix:
- Validate `uri.scheme == "https"` in release builds.
- Allowlist expected storage/CDN hostnames.
- Enforce maximum response sizes while streaming, not after full buffering.
- Verify content type and file signature before saving or setting wallpaper/ringtone.

### Medium - FileProvider exposes broad app file/cache roots for sharing

Status: Fixed. FileProvider now exposes only the generated `media/` directory, and native sharing rejects paths outside that directory.

Evidence:
- `app/android/app/src/main/res/xml/file_paths.xml:2-6`
- `app/android/app/src/main/kotlin/com/example/shanti/MainActivity.kt:137-148`

The FileProvider grants share access for the whole external files path, internal files path, and cache path. The provider is not exported, which is good, but any app code path that shares an arbitrary file path could grant another app read access to more data than intended.

Impact:
- Accidental sharing of non-media app files if a future code path passes the wrong path.
- Increased blast radius if app-internal file paths are ever influenced by untrusted input.

Recommended fix:
- Narrow FileProvider paths to a dedicated share directory, for example `cache/status_share/` or `external-files-path media/status/`.
- In Kotlin, reject paths that are not inside the approved share directory before calling `FileProvider.getUriForFile`.

### Medium - Persistent device ID uses non-cryptographic randomness and needs privacy handling

Status: Partially fixed. Device ID generation now uses `Random.secure()` and is stored securely. Privacy disclosure/reset policy remains a product/compliance item.

Evidence:
- `app/lib/state/session_controller.dart:49-52`
- `app/lib/state/session_controller.dart:93-97`
- `app/lib/api/device_context.dart:20-31`

The app generates a stable per-install device ID using `dart:math Random`, then sends it with device context headers. Even if intended as non-PII, a stable identifier can be personal data under privacy rules when linked to backend activity.

Impact:
- Tracking/privacy disclosure requirement.
- Non-cryptographic ID generation increases predictability if the ID is later used for trust decisions.

Recommended fix:
- Use cryptographic randomness if the ID must exist.
- Treat the ID as pseudonymous personal data in the privacy policy and data safety form.
- Do not use this ID as an authentication factor.
- Allow reset on logout/account deletion if it is tied to user state.

### Medium - Production package identity is still the template/example ID

Status: Fixed. The Android namespace and `applicationId` are now `com.shraddha.shanti`.

Evidence:
- `app/android/app/build.gradle.kts:7-20`

Original finding: the namespace and `applicationId` used `com.example.shanti`. They now use `com.shraddha.shanti`.

Impact:
- Play Store package identity is permanent once published.
- `com.example.*` looks like a development build and may create ownership/trademark issues.

Recommended fix:
- Choose the final production application ID before any Play upload, for example a domain-controlled package name.
- Update `namespace`, `applicationId`, FileProvider authority expectations, and any backend/package allowlists together.

### Low - Backend URL can be exposed in user-facing error messages

Status: Fixed. Production-facing network errors are now generic.

Evidence:
- `app/lib/api/api_client.dart:115-122`

Network errors include the full backend base URL. This is useful in development, but production users do not need infrastructure hostnames in error messages.

Impact:
- Minor information disclosure.
- Less polished production UX.

Recommended fix:
- Use generic production error messages.
- Keep detailed endpoint information only in logs or debug builds.

## Positive Observations

- The main launcher activity is exported because it has the launcher intent filter, which is expected.
- The FileProvider itself is `android:exported="false"`.
- The app does not request broad storage permissions such as `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, or `MANAGE_EXTERNAL_STORAGE`.
- Default backend base URL is HTTPS.
- Media is stored in app-scoped external storage, which is safer than public shared storage for app-owned files.

## Suggested Release Checklist

- Replace debug signing with real Play upload/release signing.
- Remove global cleartext traffic from the release manifest.
- Replace mocked auth/subscription/payment code with real server-side validation.
- Move tokens to Keystore-backed secure storage.
- Add backup/data extraction rules that exclude sensitive data.
- Validate all backend-provided media and signed URLs by scheme, host, size, and content type.
- Narrow FileProvider paths to a dedicated share-only directory.
- Confirm `WRITE_SETTINGS` and wallpaper/ringtone features meet Play policy requirements.
- Keep `applicationId` stable after the first Play upload.
- Complete Play Data Safety disclosures for phone number, device ID, locale/region/timezone/screen metadata, selfie upload, generated images, and any backend analytics/logging.
- Run `flutter analyze`, Android lint, dependency vulnerability checks, and a Play Console internal testing/pre-launch report before production release.
