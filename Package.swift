// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo

func resolveTargets() -> [Target] {
    let baseTargets: [Target] = [
        .target(name: "RevenueCat",
                path: "Sources",
                exclude: [
                    "Info.plist",
                    ]
        ),
    ]

    return baseTargets
}

let package = Package(
    name: "RevenueCat",
    platforms: [
        .macOS(.v10_13),
        .watchOS("6.2"),
        .tvOS(.v11),
        .iOS(.v11)
    ],
    products: [
        .library(name: "RevenueCat",
                 targets: ["RevenueCat"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", revision: "8aca5c543da5f99dbfc8ff04e50c3ac870f8deca"),
    ],
    targets: resolveTargets()
)
