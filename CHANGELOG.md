# Changelog

All notable changes to the TappGo iOS SDK are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

One version covers all three frameworks — `Tapp`, `TappLiveActivities`, `TappWidgets` — and every release
rebuilds all three. A version's section names, under its own heading, each framework that changed; a framework
with no heading in a section shipped in that version rebuilt from unchanged source.

## [2.1.0] — 2026-09-27

Adds **home-screen widgets**, and ships the SDK as **three frameworks** instead of one. The second part is a
breaking change inside a minor version, deliberately: 2.0.0 shipped Live Activities only, this is the first
release with a second surface, and splitting now is what keeps a widgets-only app from linking ActivityKit
for ever after. **An app on `from: "2.0.0"` will not build against 2.1.0 until it follows the three steps
below** — pin `exact: "2.0.0"` until you are ready.

1. Replace the `TappGo` library with `Tapp`, plus `TappLiveActivities` and/or `TappWidgets`.
2. `import TappGo` → `import Tapp`, and import each surface where you use it.
3. Rename the surface calls — the README's API table maps every one.

### Changed — **breaking: one framework became three**

- **One framework became three.** `TappGo.xcframework` is now `Tapp` (core), `TappLiveActivities` and
  `TappWidgets`. Add the library for each surface you use; `Tapp` comes with whichever you pick. A
  widgets-only app no longer links ActivityKit, and a Live Activities-only app no longer links WidgetKit or
  App Intents.
- **The calls that belong to a surface moved onto it.** `Tapp.startLiveActivity` → `TappLiveActivities.start`,
  `Tapp.configureWidget` → `TappWidgets.configureExtension`, and so on — the README's API table maps every
  one. `Tapp.configure`, `Tapp.setUserID`, `Tapp.logout` and `Tapp.handleURL` are unchanged.
- **Each surface configures itself**, in either order with `Tapp.configure`. `TappAppConfiguration` lost its
  `liveActivities` field; `TappLiveActivities.configure(_:)` takes that configuration instead, because the
  core framework cannot name a type from a framework you may not have linked.
- **Picture in Picture ships in `TappWidgets`.** Its restore tap parks a deep link in the same inbox a
  widget tap uses, which is the one seam the two share.
- **Nothing changed for React Native, Cordova, Unity or Flutter hosts** beyond the version pin: the bridge
  ships inside `Tapp` and its JSON payloads are identical, including `configure`'s. Insulating wrappers from
  exactly this is what the bridge is for. One new failure code, `surfaceNotLinked`, answers a call belonging
  to a framework the app did not add.


### Widgets

- Render a server-configured widget from a native widget extension — `TappWidgets.configureExtension(_:)`
  with a `TappWidgetConfiguration`, then embed `TappSmallWidget()` / `TappMediumWidget()` in your `WidgetBundle`.
  The campaign, its screens, its artwork, and its rules come from the Tapp back office.
- **Interactive.** A tap runs the campaign's own logic on device — scratch, spin, reveal, advance a
  streak — and redraws, with no round trip through your app. Declaring `TappWidgetIntentsPackage` in an
  `AppIntentsPackage` is the whole host-side setup; there are no intent types to write.
- **Pre-warming from the app.** `TappAppConfiguration` takes a trailing `widgetIDs:` parameter naming the
  widgets this app hosts; `configure` fetches their configuration and artwork into the shared cache in the
  background, so the first render is real content instead of a placeholder. It is additive — a widget whose
  cache is cold still fetches on its own when it renders.
- One extension serves up to eight widgets, one per slot — `TappWidgetConfiguration(widgetIDs:appGroupIdentifier:)`
  with `TappWidgets.all`, or `TappSmallWidget(slot:)` / `TappMediumWidget(slot:)` — and several extensions may
  share one App Group. Content and assets are cached there encrypted at rest, as Live Activity content already
  was.
- A widget action that both advances the campaign and opens a deep link now does both.

### Fixed

- Widget designs place their elements as authored again. Layout work done for Live Activities in 2.0.0 had
  changed how a widget's positions were read, which moved every element toward the top-left of its
  container. Live Activity rendering is unchanged. No configuration change is needed on your side.

### Cross-platform (React Native, Cordova, Unity, Flutter)

- **The bridge covers widgets and Picture in Picture.** `TappBridge` grows eight members —
  `showNextWidgetEntry`, `moveToWidgetEntry`, `setWidgetCountdownDuration`, `setWidgetText`,
  `isWidgetInstalled`, `pendingWidgetLink`, `startPictureInPicture` and `stopPictureInPicture` — so a
  non-native host can drive a campaign, not just start a Live Activity. Same JSON-in, JSON-out envelope as
  the existing members, and additive: nothing already there changed.
- Five of them answer an object-wrapped `Bool` — `{"changed":…}`, `{"applied":…}`, `{"installed":…}`. In
  every case **`false` is a success** meaning nothing happened and there is nothing to undo; an id naming a
  widget, screen or node that does not exist comes back as an `invalidConfiguration` failure instead. Do not
  surface a `false` as an error.
- `pendingWidgetLink` **omits** its `link` key when nothing is waiting, rather than sending `null`, and
  never returns a failure. Reading it consumes the link.
- `isWidgetInstalled` accepts `{}` for the common single-widget case.
- Picture in Picture adds four error codes to the contract: `pictureInPictureUnsupported`,
  `pictureInPictureBackgroundAudioMissing`, `pictureInPictureVideoUnavailable`,
  `pictureInPictureStartFailed`. **Two things to know before you ship it:** starting a presentation sends
  the host app to the background using a **private API**, which App Review may reject *your* bundle over;
  and your app target's `Info.plist` must list `audio` under `UIBackgroundModes` or the call refuses.

### Public API

New, in `TappWidgets`: `TappWidgets.configureExtension(_:)`, `TappWidgetConfiguration`, `TappSmallWidget`,
`TappMediumWidget`, `TappWidgetIntentsPackage`, `TappPictureInPictureConfiguration`. New in `Tapp`:
`TappAppConfiguration.widgetIDs` (a trailing, defaulted initializer parameter). Moved from `Tapp` to
`TappLiveActivities`: every Live Activity call and type — see "Changed" above and the README's table.
Printing a public value shows what it holds, spelled by the SDK rather than by Swift's runtime: `print(error)`
reads `liveActivityAlreadyRunning: A Live Activity with id "wheel" is already showing…` where 2.0.0 printed
`liveActivityAlreadyRunning(id: "wheel")`, and a `TappLiveActivityState` prints its raw value, `active`.

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
