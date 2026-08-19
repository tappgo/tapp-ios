// swift-tools-version: 5.9
//
// The URL and checksum below are rewritten by the release workflow from the tag it is building.
// Do not edit them by hand — a hand-edited manifest is how a URL and a checksum come to disagree.

import PackageDescription

let package = Package(
    name: "TappGo",
    // The floor a host *app* target must satisfy to link the binary. The SDK only does anything on
    // iOS 17.2 and later; below that every entry point returns its neutral answer. See the README.
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "TappGo", targets: ["TappGo"])
    ],
    targets: [
        .binaryTarget(
            name: "TappGo",
            url: "https://github.com/tappgo/tapp-ios/releases/download/v2.0.0/TappGo-2.0.0.xcframework.zip",
            checksum: "5813a900c7f1793031e3ac3da753267b99212f8ef7c9d5a2b1629a33c4fac83f"
        )
    ]
)
