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
                    "CONTRIBUTING.md",
                    "Documentation.docc",
                    "docs",
                    "Examples",
                    "fastlane",
                    "Gemfile",
                    "Gemfile.lock",
                    "InstallationTests",
                    "LatestTagDocs",
                    "LICENSE",
                    "Purchases/Info.plist",
                    "README.md",
                    "RELEASING.md",
                    "RevenueCat.podspec",
                    "scripts",
                    "SwiftStyleGuide.swift",
                    "TestingApps",
                    "Tests"
                    ],
                sources: ["Purchases"]
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
    dependencies: [],
    targets: resolveTargets()
)
