// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo

func resolveTargets() -> [Target] {
    let baseTargets: [Target] = [
        .target(name: "RevenueCat",
                path: ".",
                exclude: ["Purchases/Info.plist"],
                sources: ["Purchases"]
        )
        // Note: publicHeadersPath: "Purchases/Public" doesn't actually pick up .h headers in Swift projects.
    ]

    return baseTargets
}

let package = Package(
    name: "RevenueCat",
    platforms: [
        .macOS(.v10_12),
        .watchOS("6.2"),
        .tvOS(.v9),

        // todo: deployment_target set to 12.0 instead of 9.0 temporarily for iOS due to a known issue in 
        // Xcode-beta 5, where swift libraries fail to build for iOS targets that use armv7.
        // See issue 74120874 in the release notes:
        // https://developer.apple.com/documentation/xcode-release-notes/xcode-13-beta-release-notes
        .iOS(.v12)
    ],
    products: [
        .library(name: "RevenueCat",
                 targets: ["RevenueCat"])
    ],
    dependencies: [],
    targets: resolveTargets()
)
