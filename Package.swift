// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo

func resolveTargets() -> [Target] {
    let baseTargets: [Target] = [
        .target(name: "RevenueCat",
                path: ".",
                exclude: [
                    "CHANGELOG.latest.md",
                    "CHANGELOG.md",
                    "CODE_OF_CONDUCT.md",
                    "Development",
                    "Documentation.docc",
                    "Examples",
                    "fastlane",
                    "Gemfile",
                    "Gemfile.lock",
                    "LatestTagDocs",
                    "LICENSE",
                    "Sources/Info.plist",
                    "README.md",
                    "RevenueCat.podspec",
                    "scripts",
                    "Tests"
                    ],
                sources: ["Sources"]
        )
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
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: resolveTargets()
)
