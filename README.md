# ShopPulse Mobile (Flutter) — Technician App WebView Wrapper

This is a **thin native wrapper**, not the app itself. The actual
technician flow (login, today's task, checklist, mandatory live camera +
GPS proof capture) lives in the website at
`shoppulse-web/src/app/tech/` and is loaded full-screen inside a
`WebView`. This project's only job is bridging two things that web page
can't do on its own inside a WebView on Android:

- Opening the device **camera** (never the gallery) when the page's file
  input is tapped, via `image_picker`.
- Granting **GPS** access to the page's `navigator.geolocation` calls.
- Running a **native background location service** (see below) so Live
  Field Map keeps showing a technician's position even with the app
  backgrounded or the screen locked — something no browser tab or WebView
  can do on its own, foreground-only `watchPosition()` calls included.

Because the real logic lives on the website, **shipping a new feature or
bug fix there reaches every technician on their next page load** — no new
APK, no reinstall. This wrapper only needs rebuilding if the wrapper
itself changes (app icon, splash behavior, the camera/GPS/location
bridging code).

## What's here

```
lib/
  config/app_config.dart      AppConfig.techAppUrl — the page this wrapper loads
  screens/webview_screen.dart The entire UI: a full-screen WebView, with
                               Android-specific callbacks for camera file
                               capture, geolocation permission, and a
                               JavaScriptChannel bridge to native

android/app/.../kotlin/com/shoppulse/shoppulse_mobile/
  MainActivity.kt             MethodChannel handler: starts/stops the
                               foreground service on request from Dart
  LocationTrackingService.kt  Foreground service — FusedLocationProviderClient
                               posts position every 30s straight to
                               POST /api/staff/live-location (see the web
                               app), authenticated by a staff-scoped
                               location_token, not the Supabase session
                               (which the native side can't refresh)
```

### How the background tracking bridge works

1. The `/tech` web page calls `window.ShopPulseNative.postMessage(...)`
   after sign-in/out (see `shoppulse-web/src/lib/tech/nativeBridge.ts`) —
   that global only exists inside this WebView, so it's a no-op in a
   normal browser.
2. `webview_screen.dart`'s JavaScriptChannel receives that message and
   calls the Dart `MethodChannel` (`shoppulse/location_service`).
3. `MainActivity.kt` starts/stops `LocationTrackingService` accordingly.
4. The service runs independently of the WebView/Activity — a real
   Android foreground service with a persistent notification (required
   by Android for background location), so it keeps running when the
   app is backgrounded or the screen is locked.

## 1. Install the Flutter SDK

Follow https://docs.flutter.dev/get-started/install for your OS. Then verify:

```bash
flutter doctor
```

## 2. Install dependencies

```bash
flutter pub get
```

## 3. Run it

```bash
flutter run
```

Loads `AppConfig.techAppUrl` (defaults to
`https://shoppulse-web.vercel.app/tech`). To point at a different
deployment (e.g. a preview URL) for testing:

```bash
flutter run --dart-define=TECH_APP_URL=https://your-preview-url.vercel.app/tech
```

## 4. Build a release APK

```bash
./scripts/build_release.sh
```

Builds `build/app/outputs/flutter-apk/app-release.apk`. Publish it to the
GitHub release the web dashboard's Download button points at — this only
needs doing again when the wrapper itself changes, not for feature work
on the `/tech` web app:

```bash
gh release upload v0.1.0-skeleton build/app/outputs/flutter-apk/app-release.apk --clobber
```

## Known gaps

- No offline queueing — a failed upload/network blip currently just shows
  an error and lets the tech retry (same as before, now handled on the
  web page instead of natively).
- No push notifications for newly assigned jobs.
- The `job-photos` storage bucket is public (matches the pattern used for
  shop logos); tightening it to signed URLs is a reasonable follow-up if
  photo privacy becomes a concern.
- iOS isn't wired up yet — `webview_flutter`'s geolocation/file-selector
  bridging in `webview_screen.dart` is currently Android-only
  (`AndroidWebViewController`). An iOS build would load the page fine but
  needs the WebKit-specific equivalents added for camera/GPS. The native
  background location service is Android-only too (`LocationTrackingService.kt`).
- Background location tracking can't be verified in an emulator reliably —
  test on a real device: sign in, background the app or lock the screen,
  and confirm the persistent "ShopPulse is sharing your location"
  notification stays up and the technician's dot keeps moving on Live
  Field Map.
- No token rotation/revocation UI yet for `location_token` — it's set
  once at row creation and never expires. Fine for now (it can only be
  used to write that one staff member's live location, nothing else),
  but worth adding a "regenerate" action if a device is ever lost.
