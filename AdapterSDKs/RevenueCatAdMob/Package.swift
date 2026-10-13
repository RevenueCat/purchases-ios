// swift-tools-version:5.8

import class Foundation.ProcessInfo
import struct Foundation.URL
import PackageDescription

/// Keep compile-time feature conditions aligned with the root RevenueCat package.
let additionalCompilerFlags: [SwiftSetting] = {
    let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    let ciConfig = try? String(contentsOf: repositoryRoot.appendingPathComponent("CI.xcconfig"))
    let localConfig = try? String(contentsOf: repositoryRoot.appendingPathComponent("Local.xcconfig"))
    let configFlags = (ciConfig ?? localConfig)?
        .firstMatch(of: #/^SWIFT_ACTIVE_COMPILATION_CONDITIONS *= *(.*)$/#.anchorsMatchLineEndings())?
        .output
        .1
        .split(whereSeparator: \.isWhitespace)
        .filter { !$0.isEmpty && !$0.hasPrefix("$") }
        ?? []
    let environmentFlags = ProcessInfo.processInfo.environment["TUIST_SWIFT_CONDITIONS"]?
        .split(whereSeparator: \.isWhitespace)
        .filter { !$0.isEmpty }
        ?? []

    var flags: [String] = []
    for flag in configFlags + environmentFlags {
        let flag = String(flag)
        guard !flags.contains(flag) else { continue }
        flags.append(flag)
    }

    return flags.map { .define($0) }
}()

let package = Package(
    name: "RevenueCatAdMob",
    platforms: [
        .iOS(.v15),
        // The adapter is iOS-only, but SPM requires platform minimums >= those of dependencies.
        // RevenueCat declares macOS 10.15 / tvOS 13 / watchOS 6.2, so we must match them here
        // or SPM fills in lower defaults and fails dependency resolution.
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS("6.2")
    ],
    products: [
        .library(name: "RevenueCatAdMob", targets: ["RevenueCatAdMob"])
    ],
    dependencies: [
        .package(name: "purchases-ios", path: "../.."),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            "12.0.0"..<"14.0.0"
        )
    ],
    targets: [
        .target(
            name: "RevenueCatAdMob",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "GoogleMobileAds",
                         package: "swift-package-manager-google-mobile-ads",
                         condition: .when(platforms: [.iOS]))
            ],
            swiftSettings: additionalCompilerFlags),
        .testTarget(
            name: "RevenueCatAdMobTests",
            dependencies: [
                "RevenueCatAdMob",
                .product(name: "Nimble", package: "Nimble")
            ],
            swiftSettings: additionalCompilerFlags)
    ]
)
