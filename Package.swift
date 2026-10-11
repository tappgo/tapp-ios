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
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.2.2/Tapp-2.2.2.xcframework.zip",
            checksum: "f2f4d8ac22e92004e8cf5d5e293448c1eec071ca728ce0a8b8fa41bbf557106a"
        ),
        .binaryTarget(
            name: "TappLiveActivities",
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.2.2/TappLiveActivities-2.2.2.xcframework.zip",
            checksum: "227fa44033639a28c576e4c317c2819747dfa9e0d2cb5aec09a96abf8ac59849"
        ),
        .binaryTarget(
            name: "TappWidgets",
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.2.2/TappWidgets-2.2.2.xcframework.zip",
            checksum: "2ccf86fadf8fa21fefdcbfbcdd607ddc061d510c5ea0a35852cbca38dc3d6c09"
        ),
    ]
)
