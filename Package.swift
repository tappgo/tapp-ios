// swift-tools-version: 5.9
//
// The URLs and checksums below are rewritten by the release workflow from the tag it is building.
// Do not edit them by hand — a hand-edited manifest is how a URL and a checksum come to disagree.

import PackageDescription

let package = Package(
    name: "Tapp",
    // The floor a host *app* target must satisfy to link the binaries. The SDK only does anything on
    // iOS 17.2 and later; below that every entry point returns its neutral answer. See the README.
    platforms: [.iOS(.v15)],
    products: [
        // **Pick the surfaces you use.** Each product carries its own binary plus `Tapp`, so a widgets-only
        // app never links the Live Activity binary and never links ActivityKit. That is the whole reason
        // the SDK is three frameworks rather than one, and it is expressed here.
        //
        // The cross-platform bridge is in `Tapp`, not a product of its own: a wrapper host calls it through
        // whichever surfaces it adds, and a call belonging to a framework it did not add answers
        // `surfaceNotLinked` rather than failing to resolve a selector.
        //
        // A product listing two binary targets is how a binary dependency is spelled in SPM: binary targets
        // cannot depend on each other, so the product does the composing.
        .library(name: "Tapp", targets: ["Tapp"]),
        .library(name: "TappLiveActivities", targets: ["TappLiveActivities", "Tapp"]),
        .library(name: "TappWidgets", targets: ["TappWidgets", "Tapp"]),
    ],
    targets: [
        .binaryTarget(
            name: "Tapp",
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.4.0-rc.1/Tapp-2.4.0-rc.1.xcframework.zip",
            checksum: "7a0b5a49cd7364cfa05ee593109811ae5c3020ab1e280b4e3b8813b688dae71a"
        ),
        .binaryTarget(
            name: "TappLiveActivities",
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.4.0-rc.1/TappLiveActivities-2.4.0-rc.1.xcframework.zip",
            checksum: "08562c530289d686bf20c3fddae3795de98ac074900a65ef08d20f179f86e7a8"
        ),
        .binaryTarget(
            name: "TappWidgets",
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.4.0-rc.1/TappWidgets-2.4.0-rc.1.xcframework.zip",
            checksum: "0a4d7a856620d88d3dfd0b6e3443fc4b524798b5ccf7d15ff3d3398e6507950b"
        ),
    ]
)
