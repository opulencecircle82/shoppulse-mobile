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

Because the real logic lives on the website, **shipping a new feature or
bug fix there reaches every technician on their next page load** — no new
APK, no reinstall. This wrapper only needs rebuilding if the wrapper
itself changes (app icon, splash behavior, the camera/GPS bridging code).

## What's here

```
lib/
  config/app_config.dart      AppConfig.techAppUrl — the page this wrapper loads
  screens/webview_screen.dart The entire UI: a full-screen WebView, with
                               Android-specific callbacks for camera file
                               capture and geolocation permission
  main.dart                   App entry point
```

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
  needs the WebKit-specific equivalents added for camera/GPS.
