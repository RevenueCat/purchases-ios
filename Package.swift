// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo
import struct Foundation.URL

/// This looks for a file named `Local.xcconfig` in the root of the purchases-ios[-spm] repo, and reads any compiler
/// flags defined in it. It does nothing if this file does not exist in this exact folder. This file does not exist on
/// a clean checkout. It has to be created manually by a developer.
var additionalCompilerFlags: [PackageDescription.SwiftSetting] = {
    guard let config = try? String(
        contentsOf: URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Local.xcconfig")
    ) else {
        return []
    }
    // We split the capture group by space and remove any special flags, such as $(inherited).
    return config
        .firstMatch(of: #/^SWIFT_ACTIVE_COMPILATION_CONDITIONS *= *(.*)$/#.anchorsMatchLineEndings())?
        .output
        .1
        .split(whereSeparator: \.isWhitespace)
        .filter { !$0.isEmpty && !$0.hasPrefix("$") }
        .map { .define(String($0)) }
        ?? []
}()

var ciCompilerFlags: [PackageDescription.SwiftSetting] = [
    // REPLACE_WITH_DEFINES_HERE
]

// Only add DocC Plugin when building docs, so that clients of this library won't
// unnecessarily also get the DocC Plugin
let environmentVariables = ProcessInfo.processInfo.environment
let shouldIncludeDocCPlugin = environmentVariables["INCLUDE_DOCC_PLUGIN"] == "true"

var dependencies: [Package.Dependency] = [
    .package(url: "git@github.com:Quick/Nimble.git", from: "10.0.0"),
    // SST requires iOS 13 starting from version 1.13.0
    .package(url: "git@github.com:pointfreeco/swift-snapshot-testing.git", .upToNextMinor(from: "1.12.0"))
]
if shouldIncludeDocCPlugin {
    // Versions 1.4.0 and 1.4.1 are failing to compile, so we are pinning it to 1.3.0 for now
    // https://github.com/RevenueCat/purchases-ios/pull/4216
    dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", .exact("1.3.0")))
}

// See https://github.com/RevenueCat/purchases-ios/pull/2989
// #if os(visionOS) can't really be used in Xcode 13, so we use this instead.
let visionOSSetting: SwiftSetting = .define("VISION_OS", .when(platforms: [.visionOS]))

let package = Package(
    name: "RevenueCat",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15),
        .watchOS("6.2"),
        .tvOS(.v13),
        .iOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "RevenueCat",
                 targets: ["RevenueCat"]),
        .library(name: "RevenueCat_CustomEntitlementComputation",
                 targets: ["RevenueCat_CustomEntitlementComputation"]),
        .library(name: "ReceiptParser",
                 targets: ["ReceiptParser"]),
        .library(name: "RevenueCatUI",
                 targets: ["RevenueCatUI"])
    ],
    dependencies: dependencies,
    targets: [
        .target(name: "RevenueCat",
                path: "Sources",
                exclude: ["Info.plist", "LocalReceiptParsing/ReceiptParser-only-files"],
                resources: [
                    .copy("../Sources/PrivacyInfo.xcprivacy")
                ],
                swiftSettings: [visionOSSetting] + ciCompilerFlags + additionalCompilerFlags),
        .target(name: "RevenueCat_CustomEntitlementComputation",
                path: "CustomEntitlementComputation",
                exclude: ["Info.plist", "LocalReceiptParsing/ReceiptParser-only-files"],
                resources: [
                    .copy("PrivacyInfo.xcprivacy")
                ],
                swiftSettings: [
                    .define("ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION"),
                    visionOSSetting
                ] + ciCompilerFlags + additionalCompilerFlags),
        // Receipt Parser
        .target(name: "ReceiptParser",
                path: "LocalReceiptParsing"),
        .testTarget(name: "ReceiptParserTests",
                    dependencies: ["ReceiptParser", "Nimble"],
                    exclude: ["ReceiptParserTests-Info.plist"]),
        // RevenueCatUI
        .target(name: "RevenueCatUI",
                dependencies: ["RevenueCat"],
                path: "RevenueCatUI",
                resources: [
                    // Note: these have to match the values in RevenueCatUI.podspec
                    .copy("Resources/background.jpg"),
                    .process("Resources/icons.xcassets")
                ],
                swiftSettings: ciCompilerFlags + additionalCompilerFlags),
        .testTarget(name: "RevenueCatUITests",
                    dependencies: [
                        "RevenueCatUI",
                        "Nimble",
                        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
                    ],
                    exclude: ["Templates/__Snapshots__", "Data/__Snapshots__", "TestPlans"],
                    resources: [.copy("Resources/header.heic"), .copy("Resources/background.heic")])
    ]
)
