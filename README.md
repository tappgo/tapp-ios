# Tapp — iOS SDK

Tapp shows **remote, server-configured content** on Apple's Live Activities and home-screen widgets —
prize reveals, scratch cards, wheels, countdowns, streaks, campaign cards. The campaign, its screens, its
artwork, and its clocks live in the Tapp back office and are delivered to the device, so **changing what a
surface shows does not require a new app build**. Widget taps are interactive: a tap runs the campaign's
own logic and redraws, with no round trip through your app.

## Install

In Xcode: **File → Add Package Dependencies…**, then enter

```
https://github.com/tappgo/tapp-ios
```

and choose **Up to Next Major Version** from `2.1.0` — the first release carrying the modular SDK.

Or, in a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tappgo/tapp-ios", from: "2.1.0")
]
```

**Then add the library for each surface you use**, to your app target *and* to the matching extension
target:

| Library | Add it when | Brings |
|---|---|---|
| `TappLiveActivities` | your app shows Live Activities | the Live Activity binary + `Tapp` |
| `TappWidgets` | your app ships Tapp widgets, or uses Picture in Picture | the widget binary + `Tapp` |
| `Tapp` | neither of the above, which is unusual | the core binary alone |

**You only link what you use.** A widgets-only app never links the Live Activity binary and never links
ActivityKit; a Live Activities-only app links neither WidgetKit nor App Intents. That is why the SDK is
three frameworks rather than one, and adding the right libraries is all it asks of you — `Tapp` comes along
with whichever you pick.

**One version covers all three.** Every release rebuilds and ships all three frameworks under the package
version, whether or not each one changed — the release notes say which did. A version whose changelog names
only `TappWidgets` still carries new `Tapp` and `TappLiveActivities` binaries, built from unchanged source.

**React Native, Cordova, Unity and Flutter hosts add the same libraries.** `TappBridge` ships inside `Tapp`,
so the whole JSON facade is present in every build; a call belonging to a framework you did not add answers
`{"ok":false,"code":"surfaceNotLinked"}` rather than failing to resolve a selector.

> Upgrading from 2.0.0? The single `import TappGo` becomes one import per library you added, and the calls that
> belong to a surface moved onto it — `Tapp.startLiveActivity` is `TappLiveActivities.start`. The table
> under [The public API, in full](#the-public-api-in-full) maps every one. `Tapp.configure`, `setUserID`,
> `logout` and `handleURL` are unchanged.

## Requirements

|  |  |
|---|---|
| App target deployment | **iOS 15.0** or later — the floor for *linking* the SDK |
| Runtime | **iOS 17.2** or later — the floor for the SDK *doing anything* (see below) |
| Widget / Live Activity extension target | **iOS 17.2** or later — this one is a build requirement, not a runtime one |
| Xcode | 16.4 or later |
| Swift | 6 (the binary is built with library evolution, so older Swift language modes can consume it) |

**The two iOS numbers are deliberately different.** A framework whose minimum is 17.2 cannot be linked by
an iOS 15 app at all, which would block you from integrating over a feature you may not be using. So the
SDK links into an iOS 15 app and, on anything below 17.2, **does nothing**: every
entry point returns its neutral answer — `handleURL` returns `false`, `TappLiveActivities.active()` returns
`[]`, `TappLiveActivities.start` returns an empty id, the widget commands and `TappWidgets.isInstalled` return `false`,
`TappWidgets.pendingLink()` returns `nil`, `validateToken` returns an invalid answer, and `configure`,
`setUserID`, `logout` and the Picture in Picture calls return without throwing. There is no error to
handle: you call `configure` at launch from code that should not branch on the OS version, and there is
nothing you could do about the answer.

Your **extension** targets are different — each must be 17.2 or later, because the types they render are
annotated `@available(iOS 17.2, *)`. They fail to build below that rather than failing at launch.

## Quickstart

Read [the integration guide](https://documentation.tappgo.com/v2/native/integration) before you ship. The entitlements, `Info.plist` keys, and
bundled fonts each target needs are not inferable from a binary, and the asymmetry between the app's
entitlements and the extension's is the most common cause of a card that renders placeholders forever. The
snippets below are orientation; that page is the contract.

**In the app**, early in its lifecycle:

```swift
import Tapp
import TappLiveActivities   // only if you use them
import TappWidgets          // only if you use them

try Tapp.configure(
    TappAppConfiguration(
        appGroupIdentifier: "group.com.acme.app",
        widgetIDs: ["your-widget-id"],
        appID: "your-app-id"
    )
)
TappLiveActivities.configure(TappLiveActivityConfiguration(appID: "your-app-id"))
TappWidgets.configure()
```

**Each surface configures itself, and the order does not matter.** `Tapp.configure` names what every
surface shares; a surface that configures after it is set up as it registers. Call only the ones you added
— a library you did not add has no symbol to call.

Naming `widgetIDs`, or calling a surface's `configure`, is what opts that feature into **pre-warming**:
its configuration and artwork are fetched into the shared cache in the background, so the first render is
real content instead of a placeholder.

Hand the SDK every URL your app opens, so taps on Tapp cards are attributed:

```swift
ContentView()
    .onOpenURL { url in
        guard !Tapp.handleURL(url) else { return }
        // …your own deep links…
    }
```

**In the widget extension** — a native widget extension target, on every platform, including React
Native, Cordova, Unity and Flutter:

```swift
import WidgetKit
import SwiftUI
import AppIntents
import TappWidgets

@main
struct AcmeWidgetBundle: WidgetBundle {

    init() {
        try? TappWidgets.configureExtension(
            TappWidgetConfiguration(widgetID: "your-widget-id",
                                    appGroupIdentifier: "group.com.acme.app")
        )
    }

    var body: some Widget {
        TappMediumWidget()
        TappSmallWidget()
    }
}

// Surfaces the SDK's widget App Intents to this extension. This is the whole setup for
// interactive widgets — no intent types to declare, no registration call.
struct AcmeIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [TappWidgetIntentsPackage.self] }
}
```

**One extension can serve up to eight widgets.** Pass their ids in slot order —
`TappWidgetConfiguration(widgetIDs: ["wheel-1", "scratch-1"], appGroupIdentifier: …)` — and write
`TappWidgets.all` as the body, or `TappSmallWidget(slot:)` / `TappMediumWidget(slot:)` to pick sizes per
slot. A placed widget is known by its slot, so append new ids and never reorder the list. Several extensions
may also share one App Group. The extension authenticates and fetches on its own when it renders, so it needs the same App Group **and** the
`keychain-access-groups` entitlement — see the integration guide.

**In the Live Activity extension**, typically in your `WidgetBundle`:

```swift
import WidgetKit
import SwiftUI
import TappLiveActivities

@main
struct AcmeLiveActivityBundle: WidgetBundle {

    init() {
        try? TappLiveActivities.configureExtension(appGroupIdentifier: "group.com.acme.app")
    }

    var body: some Widget {
        TappLiveActivity()
    }
}
```

**Then drive activities from the app:**

```swift
try await TappLiveActivities.start(id: "flash-sale", entryID: "screen-1", seconds: 30 * 60)
try await TappLiveActivities.update(id: "flash-sale", entryID: "screen-1", seconds: 300)
try await TappLiveActivities.end(id: "flash-sale", entryID: "screen-1")
```

Every call names the card by the `id` it was started with and the screen by its `entryID`, both from your
server-side configuration — your app never assembles, holds, or passes content. `seconds` on `start` and
`update` is how long the design's countdowns run; on `end` it is a dismissal delay, which is a different
thing that happens to share a name. Details in [the integration guide](https://documentation.tappgo.com/v2/native/integration).

Identity, when you have it:

```swift
try Tapp.setUserID("your-player-id")
try await Tapp.logout()
```

## Driving a widget campaign

**The widget never advances on its own.** Which screen a player sees next is your app's decision, made when
it knows what they just did — a spin resolved, a prize was banked, a cooldown should restart. All of these
are synchronous, and they redraw the widget for you.

```swift
try TappWidgets.showNextEntry()                                   // walk the screens, wrapping at the end
try TappWidgets.moveToEntry(widgetID: "wheel-1", entryID: "screen_2")   // jump straight to one
```

`TappWidgets.showNextEntry()` fans out to every widget you declared in `widgetIDs`, because a claim has to reach
all of them. `TappWidgets.moveToEntry(widgetID:entryID:)` is the opposite kind of statement, so it names one widget and touches only
that one. `entryID` is the screen's `id` from your server-side configuration; its casing is ignored.

**Editing content the back office marked editable.** A screen's designer marks a node `"editable": true`,
and only then do these rewrite it. The edit lands in the stored screen, so it survives app restarts and
cache refreshes, and is replaced when the server publishes a new version of that screen — server content
always wins.

```swift
try TappWidgets.setCountdownDuration(widgetID: "wheel-1", entryID: "screen_1",
                                    nodeID: "Countdown", seconds: 90)
try TappWidgets.setText(widgetID: "wheel-1", entryID: "screen_1",
                       nodeID: "title", text: "3 spins left!")
```

Setting a duration also **restarts the countdown from now**. `nodeID` is the `id` your document gives the
node, and unlike `entryID` its casing matters.

**Reading the four `Bool`s.** Every call above returns whether anything actually happened, and `false` is
never an error: the campaign names a single screen, the widget was already on the screen you asked for,
nothing has been fetched yet, or the node is not marked editable. There is nothing to undo and nothing to
report. An id naming a widget, screen, or node that does not exist **throws** instead — a typo answering
`false` forever would read as "already there" and never get diagnosed.

### The claim flow

A payload's claim button carries a link with no scheme — nothing `openURL` can resolve — so the tap brings
your app forward and parks the link. Collect it when the app becomes active:

```swift
.onChange(of: scenePhase) { _, phase in
    guard phase == .active, let link = TappWidgets.pendingLink() else { return }

    guard let token = URLComponents(url: link, resolvingAgainstBaseURL: false)?
        .queryItems?.first(where: { $0.name == "token" })?.value else { return }

    Task {
        let answer = await TappWidgets.validateToken(token: token, widgetID: "wheel-1")
        guard answer.isValid else { return }
        grant(answer.prize)                 // you bank the prize; only you know whether it landed
        _ = try? TappWidgets.showNextEntry() // then drive the campaign on
    }
}
```

`TappWidgets.pendingLink()` is **consume-once** — a claim is an event, not a state, and re-reading it on the next
foreground would advance the campaign twice for one tap. A link that *does* carry a scheme is opened by the
system instead and reaches your own `onOpenURL`.

`validateToken` **never throws**, and `isValid == false` also means "couldn't ask" — no network, a server
error, an unconfigured SDK. Treat it as *do not grant*, not as proof of tampering, and retry when
connectivity returns if that distinction matters to you. `widgetID` picks the widget-scoped session whose
bearer authenticates the request.

### Before you prompt someone to add the widget

```swift
if try TappWidgets.isInstalled() == false {
    showAddWidgetTutorial()
}
```

An add-widget prompt shown to somebody who already added it is the most visible way an integration can look
broken. Omit `widgetID` to ask about any declared widget — what an app with one widget wants — or name one
to ask about it alone. It reads a timestamp the extension already wrote, so it costs no network and no
refresh budget; call it on every foreground if that suits you.

**The two answers are not equally strong, and this is not live state.** iOS publishes no list of placed
widgets, so the SDK reads the one thing only a live widget produces — WidgetKit asking it to render.

- A **`false`** for a widget that never rendered is certain. Nothing else writes the timestamp.
- A **removal takes up to ~30 hours** of powered-on time to surface. This is a slow signal for
  re-engagement, not a live one for a UI that has to be right this second.
- A **`true` can outlive the widget**: iOS also requests timelines for a widget it might merely *suggest*
  in the Smart Stack, and an extension cannot tell those apart from a placed widget's.

Treat it as a strong hint whose `false` is trustworthy, and hang nothing destructive off either answer.

## Picture in Picture

Plays a muted, looping video in the system's floating window — the bubble iOS carries out to the Home
Screen. The window belongs to iOS: it draws it, and the user drags, resizes and dismisses it.

```swift
try await TappWidgets.startPictureInPicture(
    TappPictureInPictureConfiguration(videoURL: url, deepLink: URL(string: "acme://offers/42"))
)
await TappWidgets.stopPictureInPicture()
```

> **Starting a presentation backgrounds your app, and that uses a private API.** That is how the window
> gets out of your app, and there is no flag to disable it — without it there is no feature. App Review may
> reject **your** bundle over it, possibly long after you integrate. If that is not a trade you want, do not
> call this.

> **Your app target's `Info.plist` must list `audio` under `UIBackgroundModes`.** Without it iOS stops the
> window the moment the app is backgrounded, so the call refuses with
> `pictureInPictureBackgroundAudioMissing` rather than starting something that cannot survive the thing it
> exists for. It goes on the **app** target, not an extension.

**Starting interrupts other audio even though the video is silent** — iOS grants the background execution
this depends on only to an app that owns the audio session outright, so music the user had playing stops.
The session is handed back when the window comes down.

The presentation ends when the user returns to your app by any route. Only the bubble's own restore control
also delivers `deepLink`, and it arrives at **`TappWidgets.pendingLink()`** — the same inbox a widget tap
uses, so if you already collect one you collect this with no new code. `stopPictureInPicture()` never
throws, and stopping with nothing running is a no-op rather than an error.

## Errors

Every throwing call throws `TappError`. **Branch on `code`, not on `message`** — the code is a stable
string, and the wording may change in any release.

| `code` | What it means |
|---|---|
| `notConfigured` | `Tapp.configure(_:)` has not run. |
| `invalidConfiguration` | An argument was blank, or named a widget, screen, or node that does not exist. `message` says which. |
| `liveActivitiesUnavailable` | Disabled in Settings, or the app is missing `NSSupportsLiveActivities`. |
| `liveActivityStartFailed` | The system refused the start. |
| `liveActivityAlreadyRunning` | That `id` is already showing that screen. Update it, end it, or start a different `entryID`. |
| `pictureInPictureUnsupported` | The device cannot show Picture in Picture. |
| `pictureInPictureBackgroundAudioMissing` | The app target declares no `audio` background mode. |
| `pictureInPictureVideoUnavailable` | The URL is not playable. |
| `pictureInPictureStartFailed` | No active window scene, a start already in flight, the video never started playing, or the start was abandoned: the user returned to the app, or the presentation was stopped or failed, before it finished. `message` carries the reason. |

Across the bridge (React Native, Unity, Flutter, Cordova) three more codes exist that a native host never
sees: `invalidRequest` (the request JSON did not decode, or missed a field), `unexpected` (a failure the
bridge was not taught; `message` carries the detail) and `surfaceNotLinked` (a call into a module this build
does not link).

`TappError` conforms to `LocalizedError`, so `error.localizedDescription` reads properly — it returns
`message` verbatim rather than a second wording that would drift from it. Printing one (`print(error)`,
`"\(error)"`) gives `code` and `message` together — `notConfigured: Tapp is not configured…` — so a log line
names the failure as well as describing it.

## The public API, in full

| Symbol | |
|---|---|
| `Tapp.configure(_:)` | Configure the SDK in the app. Also opts the named features into pre-warming. |
| `TappLiveActivities.configure(_:)` | Configure Live Activities in the app, in either order with `Tapp.configure`. Never throws. |
| `TappWidgets.configure()` | Attach the widget surface in the app, in either order with `Tapp.configure`. Takes no arguments — the widget ids are `Tapp.configure`'s. |
| `TappWidgets.configureExtension(_:)` | Configure a widget extension: up to eight widget ids, one per slot. |
| `TappLiveActivities.configureExtension(appGroupIdentifier:)` | Configure a Live Activity extension. |
| `Tapp.setUserID(_:)` | Record the player. Returns as soon as the id is written; the session settles in the background, so do not present it as "sign-in complete". |
| `Tapp.logout()` | End the session and return to a guest one. |
| `Tapp.handleURL(_:)` | Offer a URL to the SDK. `false` means it is yours to handle. |
| `Tapp.sdkVersion` | The version the loaded binary reports to the back office. |
| `TappLiveActivities.start(id:entryID:seconds:)` | Start a card. Returns the system activity id. |
| `TappLiveActivities.update(id:entryID:seconds:)` | Reload the card that `id`/`entryID` names. A pair that is not running is a no-op, not a failure. |
| `TappLiveActivities.end(id:entryID:seconds:)` | End it. Here `seconds` is a dismissal delay. |
| `TappLiveActivities.active()` | Every Tapp card the system reports, as `[TappLiveActivityInfo]`. |
| `TappWidgets.showNextEntry()` | Advance every declared widget to its next screen. |
| `TappWidgets.moveToEntry(widgetID:entryID:)` | Move one widget straight to a named screen. |
| `TappWidgets.setCountdownDuration(widgetID:entryID:nodeID:seconds:)` | Set an editable countdown and restart it from now. |
| `TappWidgets.setText(widgetID:entryID:nodeID:text:)` | Set an editable component's text. |
| `TappWidgets.isInstalled(widgetID:)` | Whether the player added the widget. `widgetID` is optional. |
| `TappWidgets.pendingLink()` | The link a widget tap or a Picture in Picture restore parked. Consume-once. |
| `TappWidgets.validateToken(token:widgetID:)` | Ask the server whether a claim token is valid. Never throws. |
| `TappWidgets.startPictureInPicture(_:)` / `TappWidgets.stopPictureInPicture()` | The floating video window. |
| `TappAppConfiguration` · `TappWidgetConfiguration` · `TappLiveActivityConfiguration` · `TappPictureInPictureConfiguration` | What you hand the four `configure`-shaped calls. |
| `TappSmallWidget()` / `TappSmallWidget(slot:)` · `TappMediumWidget()` / `TappMediumWidget(slot:)` · `TappLiveActivity()` | The views you place in a `WidgetBundle`; a widget names the slot of the `TappWidgetConfiguration` it draws, and no argument means slot 0. |
| `TappWidgets.all` | Every configured slot as one `WidgetBundle` body, for an extension that would rather not list them by hand. |
| `TappWidgetIntentsPackage` | Surfaces the SDK's App Intents to your widget extension. |
| `TappLiveActivityInfo` · `TappLiveActivityState` | What `TappLiveActivities.active()` returns. `state` is an **open set** — keep a value you do not recognise and treat it as still running; only `ended` and `dismissed` mean finished. |
| `TappTokenValidation` | What `validateToken` returns: `isValid`, and `prize` / `userID` when there are any. |
| `TappError` | Every throwing call's error. Branch on `code`. |

## React Native, Cordova, Unity and Flutter

The wrappers are thin bindings over this binary, each in its own repository and pinned to a native version.
Every app-side call above is available to them through `TappBridge`, which ships inside `Tapp` — a flat facade taking and returning
**JSON strings** — `{"ok":true,"value":…}` or `{"ok":false,"code":…,"message":…}`, where `code` is the same
string the table above lists.

`TappBridge.sdkVersion()` is the call to make first when a wrapper is new and everything is suspect: it
needs no configuration, touches no device state, cannot fail for anything you could have got wrong, and a
well-formed reply proves the whole chain — symbol resolved, string marshalled, reply parsed. Assert its
`version` against the native version your wrapper claims to embed, and a mismatched pairing is caught at
integration time rather than by a missing symbol much later.

**Widgets and Live Activities are always native**, on every platform: your host app ships a real iOS widget
extension that links this framework and calls `TappWidgets.configureExtension(_:)` in Swift. The bridge covers the
app side only, which is why there is no `configureWidget` on it. Each wrapper ships extension templates and
a setup script that establishes the App Group joining the two.

The wrappers vendor these same frameworks, so each release's dSYM archives (below) symbolicate their
crashes too.

## Verifying the binaries

**Every** xcframework — `Tapp`, `TappLiveActivities`, `TappWidgets` — is signed with Tapp's
Apple Distribution identity. Xcode records that identity the first time you build against one and fails the
build if it ever changes. To check one yourself:

```bash
codesign -dvvv --extract-certificates Tapp.xcframework && shasum -a 256 codesign0
```

The certificate's SHA-256 fingerprint is:

```
7756e7ab2d48948c3ce04bac8520fefca9691e22b42171fd83577e1df0fa6b0a
```

## Symbolicating crash reports

The frameworks ship stripped, so Tapp frames in a crash report are raw addresses until the matching debug
symbols are added. Every release carries them beside the binaries: `<Module>-<version>-dSYMs.zip` for `Tapp`
and for each of `TappWidgets` and `TappLiveActivities` you link. Upload them to your crash reporter with your
app's own symbols (`upload-symbols` for Crashlytics, `sentry-cli debug-files upload` for Sentry), or unzip
them anywhere Spotlight indexes for Xcode's Organizer — always the dSYMs of the exact release you ship.

Have a raw crash report whose Tapp frames you can't read? Send it to us (see [Support](#support)) and we'll
symbolicate it.

## Privacy

The SDK ships an Apple **privacy manifest** (`PrivacyInfo.xcprivacy`) inside `Tapp` and inside `TappWidgets`,
declaring its data collection and its use of required-reason APIs. Xcode folds them into your app's privacy
report, so you do not describe the binaries' behaviour on their behalf — but **your own App Store privacy
answers must account for what it collects.**

| Data type | Linked to the user | Used for tracking | Purpose |
|---|---|---|---|
| User ID | Yes | No | App Functionality, Analytics |
| Product Interaction | Yes | No | Analytics |
| Other Data Types | Yes | No | Analytics |
| Performance Data | Yes | No | App Functionality |
| Other Diagnostic Data | Yes | No | App Functionality |

Performance Data and Other Diagnostic Data are new in 2.2.0. They cover diagnostics Tapp can switch on for
an install — the memory a render used, a closed set of failure codes, the device model and the OS, app and
SDK versions — and never carry anything your app authors, a user id or a token.

It declares no tracking and no tracking domains: no advertising identifier, no device or session
fingerprint, no location. There is no tracking API for your app to call, so nothing your app authors can
appear in those payloads.

## Support

Bugs and integration questions: [open an issue](https://github.com/tappgo/tapp-ios/issues). Please include
the SDK version, the iOS version, whether it reproduces on a physical device, and — for anything about a
card that does not appear — the App Group identifier as spelled in each target.

Commercial and account matters: contact@tappgo.com

## License

Proprietary. See [`LICENSE`](LICENSE) — use in a shipping application requires a commercial agreement with
Tapp.
