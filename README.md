# WildWatch

Citizen wildlife-sighting reporting, built to be **rebranded per animal, country,
and agency** from a single codebase. The first flavor — **Squirrel Watch PH** —
lets the public report invasive *Finlayson's squirrel* sightings to the
Philippines' DENR Biodiversity Management Bureau.

There is **no backend**. Each campaign delivers reports directly to its agency,
by email or by an HTTP API. Reports are stored on the device, so the app works
offline and keeps a history.

## The reuse model: campaigns

Everything campaign-specific lives in a single `Campaign` object. A new
animal/country/agency is a new config, not new code.

```
lib/campaign/
  campaign.dart            # the Campaign model + all its value types
  active_campaign.dart     # registry + which campaign this build ships as
  campaigns/
    squirrel_ph.dart       # Squirrel Watch PH → DENR-BMB (email)
    cane_toad_au.dart      # example: different animal/country → HTTP API
```

A `Campaign` defines:

| Area | What it controls |
| --- | --- |
| Branding | seed colour, accent, emoji badge, hero icon (the theme is generated from these tokens — no colour literals in widgets) |
| Species | the list people can pick from, with ID hints + the invasive target |
| Fields | extra campaign-specific questions appended to the form (text / number / choice / yes-no) |
| Agency | name, short name, website, phone |
| Submission | `email` (recipients + subject template) **or** `httpApi` (endpoint + headers) |
| Locale | the user-facing copy most worth translating (Tagalog-ready) |
| Safety | handling/safety notes shown prominently |

### Add a new campaign

1. Create `lib/campaign/campaigns/<your_campaign>.dart` with a `const Campaign`
   (copy `squirrel_ph.dart` as a template).
2. Register it in `lib/campaign/active_campaign.dart`:
   ```dart
   const campaignRegistry = {
     'squirrel-ph': squirrelPhCampaign,
     'your-campaign-id': yourCampaign,
   };
   ```
3. Run it:
   ```bash
   flutter run --dart-define=CAMPAIGN=your-campaign-id
   ```

For a published store build you'd also set the per-flavor app name/icon
(`android/app/src/main/AndroidManifest.xml` label, `ios/Runner/Info.plist`
`CFBundleDisplayName`) — these are build-wide, so use Android product flavors /
iOS schemes when shipping multiple campaigns from one repo.

## Submission (no backend)

`lib/submission/` contains a pluggable channel abstraction:

- **`EmailChannel`** — opens the device's email app pre-filled with the agency
  recipient, subject, body and the photo attached. The user taps *Send*. No SMTP
  credentials live in the app. Used by Squirrel Watch PH → `bmb@bmb.gov.ph`.
- **`HttpApiChannel`** — POSTs the report as multipart (`report` JSON part +
  photo file) to an agency API. Completes without user interaction, so the
  offline queue can flush it automatically.

`SubmissionManager` picks the channel from the active campaign, updates report
status, and (for HTTP campaigns) auto-flushes the queue when connectivity
returns.

## Features (MVP)

- Photo capture / gallery pick (saved to app storage as evidence)
- GPS + tap-to-place map pin on OpenStreetMap (no map API key), works with raw
  coordinates offline
- Offline-first: reports persist locally; HTTP campaigns auto-retry when online
- "My reports" history with per-report status (Draft / Queued / Submitted / Failed)
- Anonymous reporting with optional contact details for agency follow-up

## Project layout

```
lib/
  campaign/      campaign model, registry, flavor configs
  models/        Report, GeoPoint, ContactInfo + JSON
  data/          local report repository (SharedPreferences), device id
  services/      location (geolocator), photo (image_picker), connectivity
  submission/    channel abstraction, email + http channels, formatter, manager
  theme/         theme generated from campaign branding tokens
  features/      home, report (form + widgets), history (list + detail)
  widgets/       shared (brand badge, status chip)
  app_scope.dart dependency holder (InheritedWidget) — no state-mgmt package
  main.dart
```

## Run / build

```bash
flutter pub get
flutter run                                   # Squirrel Watch PH (default)
flutter run --dart-define=CAMPAIGN=cane-toad-au
flutter build apk --release                   # Android
flutter build ipa                             # iOS
flutter test
flutter analyze
```

> Note: email and on-device file storage need a real mobile device/simulator
> (they rely on `dart:io` and native plugins); the web target is not supported.

## Permissions

- **Android** (`AndroidManifest.xml`): `INTERNET`, `ACCESS_FINE/COARSE_LOCATION`,
  and a `mailto` intent query so the email app resolves.
- **iOS** (`Info.plist`): location-when-in-use, camera, and photo-library usage
  descriptions.

## Testing with an iOS Shortcut (deep links)

The app registers a custom URL scheme, so it can be launched straight into a
pre-filled report from an **iOS Shortcut** (or Android, or a browser). A
Shortcut's *Open URL* action triggers exactly the same path as
`xcrun simctl openurl`.

**Schemes:** `squirrelwatch://` (this flavor) and the universal `wildwatch://`.

**Routes:**

| URL | Opens |
| --- | --- |
| `squirrelwatch://report?…` | New report form, pre-filled from the query |
| `squirrelwatch://reports` | My reports / history |
| `squirrelwatch://` | Home |

**Prefill query params** (all optional): `species` (a species id, e.g.
`finlaysons-squirrel`), `lat` + `lng`, `locality`, `notes`, `name` / `phone` /
`email`, and any campaign field key (`count`, `behavior`, `habitat`,
`still_present`). Values must be URL-encoded.

Example:

```
squirrelwatch://report?species=finlaysons-squirrel&lat=14.5547&lng=121.0244&locality=Ayala%20Triangle%2C%20Makati&count=2&behavior=On%20power%20lines%20%2F%20cables&notes=Seen%20from%20office%20window
```

### Create the Shortcut (iPhone)

1. Open **Shortcuts** → **+** → **Add Action**.
2. Search **Open URL**, add it, and paste a URL like the one above.
3. Name it e.g. *“Report a squirrel”*, then **Done**. (Optionally pin it to the
   Home Screen or Share Sheet.)
4. Run it → Squirrel Watch PH opens with the report already filled in; review and
   send.

**Make it capture real GPS:** in the Shortcut, add **Get Current Location**, then
a **Text** action that builds the URL with the location interpolated
(`squirrelwatch://report?lat=[Latitude]&lng=[Longitude]`), and feed that into
**Open URL**. You can also add **Ask for Input** actions for the count, etc.

### Trigger it without a Shortcut

```bash
# iOS Simulator
xcrun simctl openurl booted "squirrelwatch://report?species=finlaysons-squirrel&count=2&locality=Makati"

# Android device/emulator
adb shell am start -a android.intent.action.VIEW -d "squirrelwatch://report?species=finlaysons-squirrel&count=2"
```

## Status / next steps

- Submission is wired and working for both channels. The `cane-toad-au` API URL
  is a placeholder — point it at the real endpoint when onboarding that campaign.
- Worth adding next: reverse-geocoding the pin to a readable address, app
  icons/splash per flavor, and full i18n (`intl`/`gen_l10n`) for the generic UI
  chrome (campaign copy is already swappable today).
