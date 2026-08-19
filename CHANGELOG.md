# Changelog

All notable changes to the TappGo iOS SDK are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] — 2026-08-19

The first public release. TappGo renders remote, server-configured content on Apple's Live Activities:
the campaign, its screens, its artwork, and its countdowns are configured in the Tapp back office and
delivered to the device, so changing what a card shows does not require a new app build.

### Live Activities

- Start, update, and end activities from the host app — `Tapp.startLiveActivity(id:entryID:seconds:)`,
  `Tapp.updateLiveActivity(id:entryID:seconds:)`, `Tapp.endLiveActivity(id:entryID:seconds:)`. Each call
  addresses a card by the `id` it was started with and the screen by its `entryID`, both from the
  server-side configuration; the app never assembles, holds, or passes content.
- **Push-to-start and per-activity push updates.** The SDK registers the device's push-to-start token and
  each activity's update token, so a campaign can raise and update a card while the app is closed.
- `seconds` drives every countdown in the design. On `start` and `update` it is a duration for the card's
  clock; on `end` it is a dismissal delay that only says how long the finished card lingers.
- Content the device has cached renders immediately, and a running activity is brought onto newer content
  as it arrives — a countdown resumes rather than restarting.
- Frame-animation fonts, bundled in your extension and registered by the SDK.
- Content and assets are cached in the App Group, encrypted at rest, and shared with your extension.

### Identity and analytics

- `Tapp.setUserID(_:)` and `Tapp.logout()`.
- `Tapp.activeLiveActivities()` — what the system currently has up for your app.
- `Tapp.handleURL(_:)` — hand it every URL your app opens and taps on Tapp cards are attributed.
- Product analytics are reported for you; there is no tracking API to call.

### Public API

`Tapp.configure(_:)`, `Tapp.configureLiveActivity(appGroupIdentifier:)`, `Tapp.setUserID(_:)`,
`Tapp.logout()`, `Tapp.startLiveActivity(id:entryID:seconds:)`,
`Tapp.updateLiveActivity(id:entryID:seconds:)`, `Tapp.endLiveActivity(id:entryID:seconds:)`,
`Tapp.activeLiveActivities()`, `Tapp.handleURL(_:)`, `TappLiveActivity`, `TappAppConfiguration`,
`TappLiveActivityConfiguration`, `TappLiveActivityInfo`, `TappError` — plus a flat Obj-C/JSON bridge
facade used by the React Native, Cordova, Unity, and Flutter wrappers.

### Distribution

- A single signed `TappGo.xcframework` (device and simulator), consumed via Swift Package Manager.
- Ships an Apple privacy manifest declaring the SDK's data collection and required-reason API use, so your
  app's privacy report accounts for it without you describing the binary on its behalf.
- The device dSYM is embedded, so Tapp frames in your crash reports are symbolized.
