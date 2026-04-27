// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "SPMXCFrameworkTest",
    platforms: [.iOS(.v16)],
    targets: [
        .binaryTarget(
            name: "RevenueCat",
            path: "../../RevenueCat.xcframework"
        ),
        .binaryTarget(
            name: "RevenueCatUI",
            path: "../../RevenueCatUI.xcframework"
        )
    ]
)
