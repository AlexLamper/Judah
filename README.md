# Judah

A daily Bible verse widget with a lion cub companion. Judah grows from cub to
young lion to the Lion of Judah in about a week when you read your verse, pray
and read the chapter. Skip a day and he misses you.

- App: `judah_mobile/` (Flutter, iOS + Android, no account, everything on device)
- Domain: getjudah.com
- Bundle id: `com.getjudah.app` (widget extension `com.getjudah.app.JudahWidget`)
- App Group: `group.com.getjudah.app`

## How it fits together

| Part | Where |
| --- | --- |
| Growth, mood, scene and streak rules (unit-tested) | `lib/domain/judah_state.dart` |
| Daily verse picker, KJV/WEB Bible text | `lib/data/verses.dart`, `assets/` |
| Curated verses: 17 topics, 241 verses | `tools/verse_refs.py` -> `python3 tools/build_verses.py` |
| Placeholder Judah art (every stage x mood x scene) | `lib/ui/judah_art.dart` |
| Widget data + pre-rendered Judah pictures | `lib/services/widget_sync.dart` |
| Android widgets (small, medium, large) | `android/app/src/main/kotlin/com/getjudah/app/widget/` |
| iOS widget (small, medium, large, lock screen) | `ios/JudahWidget/` |
| Morning verse notification (local, no server) | `lib/services/notifications.dart` |
| RevenueCat (entitlement `pro`) | `lib/services/purchases.dart` |

The widgets work while the app is closed: the app stores the verses for the
next 14 days and one picture of Judah per mood and time of day, and the native
widget code applies the same mood/scene rules as `judah_state.dart`.

## Product rules

- Paywall: the app is free, the widgets need Judah Pro.
- Plans: yearly $19.99 with a 7-day free trial, plus monthly. No ads.
- Growth: a day counts once the verse is read. 3 days = young lion, 7 days =
  adult. Growth never resets; missing a whole day only makes Judah sad.
- Moods: happy, sad (a full day skipped), sleepy (22:00-05:00), praying (30
  minutes after a prayer, in the app only).

## Setup checklist

### Apple
1. App ID `com.getjudah.app` and `com.getjudah.app.JudahWidget`, both with the
   App Group `group.com.getjudah.app`.
2. App Store provisioning profile for each App ID.
3. App in App Store Connect: "Judah: Bible Verse Widget".
4. Subscriptions: yearly (7-day free trial) and monthly in one group.

### RevenueCat
1. Project "Judah", iOS + Android apps.
2. Entitlement `pro`, offering `default` with `$rc_annual` and `$rc_monthly`.
3. Design the paywall in the dashboard (the app shows it with `presentPaywall`).

### GitHub secrets
iOS: `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `KEYCHAIN_PASSWORD`,
`BUILD_PROVISION_PROFILE_BASE64`, `BUILD_PROVISION_PROFILE_WIDGET_BASE64`,
`APPLE_TEAM_ID`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`,
`APP_STORE_CONNECT_API_KEY_P8`, `REVENUECAT_APPLE_KEY`.

Android: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `REVENUECAT_GOOGLE_KEY`.

## Local development

```bash
cd judah_mobile
flutter pub get
flutter test
flutter run
```

Without RevenueCat keys, a debug build shows a "Debug: Pro without RevenueCat"
switch in Settings so the widgets can be tested.

Preview images of the art and screens:

```bash
flutter test test/preview_test.dart --dart-define=PREVIEW_DIR=/tmp/judah
```

## Bible text

KJV and the World English Bible (WEB) are both public domain. Note that the WEB
uses "Yahweh" where most translations say "the LORD".
