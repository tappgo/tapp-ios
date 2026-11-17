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
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.5.1/Tapp-2.5.1.xcframework.zip",
            checksum: "01df1b6e08854869c00947e4deab4323a75f9ce7b77e88b71bdd9759a68957f9"
        ),
        .binaryTarget(
            name: "TappLiveActivities",
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.5.1/TappLiveActivities-2.5.1.xcframework.zip",
            checksum: "4cfd034b14c44484a7defe88bc110d4fe7c80527443806691600602e43ecaf51"
        ),
        .binaryTarget(
            name: "TappWidgets",
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.5.1/TappWidgets-2.5.1.xcframework.zip",
            checksum: "0f68d385680bc5d91aa11df0bcc3b8e02765c3fd352c96d0ccd6497264ad7ba3"
        ),
    ]
)
