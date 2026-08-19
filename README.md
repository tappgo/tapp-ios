# TappGo — iOS SDK

TappGo shows **remote, server-configured content** on Apple's Live Activities — prize reveals, countdowns,
streaks, campaign cards. The campaign, its screens, its artwork, and its clocks live in the Tapp back
office and are delivered to the device, so **changing what a card shows does not require a new app build**.

This release ships Live Activities. Home-screen widgets are in development and have no public API here.

## Install

In Xcode: **File → Add Package Dependencies…**, then enter

```
https://github.com/tappgo/tapp-ios
```

and choose **Up to Next Major Version** from `2.0.0`.

Or, in a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tappgo/tapp-ios", from: "2.0.0")
]
```

Add the `TappGo` library to **both** your app target and your Live Activity extension target.

## Requirements

|  |  |
|---|---|
| App target deployment | **iOS 15.0** or later — the floor for *linking* the SDK |
| Runtime | **iOS 17.2** or later — the floor for the SDK *doing anything* (see below) |
| Live Activity extension target | **iOS 17.2** or later — this one is a build requirement, not a runtime one |
| Xcode | 16.4 or later |
| Swift | 6 (the binary is built with library evolution, so older Swift language modes can consume it) |

**The two iOS numbers are deliberately different.** A framework whose minimum is 17.2 cannot be linked by
an iOS 15 app at all, which would block you from integrating over a feature you may not be using. So the
SDK links into an iOS 15 app and, on anything below 17.2, **does nothing and says so in the log**: every
entry point returns its neutral answer — `handleURL` returns `false`, `activeLiveActivities()` returns
`[]`, `startLiveActivity` returns an empty id, and `configure`, `setUserID`, and `logout` return without
throwing. There is no error to handle: you call `configure` at launch from code that should not branch on
the OS version, and there is nothing you could do about the answer.

Your **extension** target is different — it must be 17.2 or later, because the types it renders are
annotated `@available(iOS 17.2, *)`. It fails to build below that rather than failing at launch.

## Quickstart

Read [the integration guide](https://documentation.tappgo.com/v2/native/integration) before you ship. The entitlements, `Info.plist` keys, and
bundled fonts each target needs are not inferable from a binary, and the asymmetry between the app's
entitlements and the extension's is the most common cause of a card that renders placeholders forever. The
snippets below are orientation; that page is the contract.

**In the app**, early in its lifecycle:

```swift
import TappGo

try Tapp.configure(
    TappAppConfiguration(
        appGroupIdentifier: "group.com.acme.app",
        liveActivities: TappLiveActivityConfiguration(appID: "your-app-id")
    )
)
```

Naming `liveActivities` is what turns the feature on: `configure` then pre-warms the shared cache in the
background, so the first card renders real content instead of a placeholder.

Hand the SDK every URL your app opens, so taps on Tapp cards are attributed:

```swift
ContentView()
    .onOpenURL { url in
        guard !Tapp.handleURL(url) else { return }
        // …your own deep links…
    }
```

**In the Live Activity extension**, typically in your `WidgetBundle`:

```swift
import WidgetKit
import TappGo

@main
struct AcmeLiveActivityBundle: WidgetBundle {

    init() {
        try? Tapp.configureLiveActivity(appGroupIdentifier: "group.com.acme.app")
    }

    var body: some Widget {
        TappLiveActivity()
    }
}
```

**Then drive activities from the app:**

```swift
try await Tapp.startLiveActivity(id: "flash-sale", entryID: "screen-1", seconds: 30 * 60)
try await Tapp.updateLiveActivity(id: "flash-sale", entryID: "screen-1", seconds: 300)
try await Tapp.endLiveActivity(id: "flash-sale", entryID: "screen-1")
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

## Verifying the binary

The `TappGo.xcframework` is signed with Tapp's Apple Distribution identity. Xcode records that identity the
first time you build against it and fails the build if it ever changes. To check it yourself:

```bash
codesign -dvvv --extract-certificates TappGo.xcframework && shasum -a 256 codesign0
```

The certificate's SHA-256 fingerprint is:

```
7756e7ab2d48948c3ce04bac8520fefca9691e22b42171fd83577e1df0fa6b0a
```

## Privacy

The SDK ships an Apple **privacy manifest** (`PrivacyInfo.xcprivacy`) inside the framework, declaring its
data collection and its use of required-reason APIs. Xcode folds it into your app's privacy report, so you
do not describe the binary's behaviour on its behalf — but **your own App Store privacy answers must
account for what it collects.**

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
