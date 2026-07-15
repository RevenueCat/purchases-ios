// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import class Foundation.ProcessInfo
import struct Foundation.URL
import PackageDescription

/// This reads extra Swift compiler conditions from `CI.xcconfig`, `Local.xcconfig`, and
/// `TUIST_SWIFT_CONDITIONS`.
var additionalCompilerFlags: [PackageDescription.SwiftSetting] = {
    let ciConfig = try? String(
        contentsOf: URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("CI.xcconfig")
    )

    let localConfig = try? String(
        contentsOf: URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Local.xcconfig")
    )

    // We split the capture group by space and remove any special flags, such as $(inherited).
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

var ciCompilerFlags: [PackageDescription.SwiftSetting] = [
    // REPLACE_WITH_DEFINES_HERE
]

// Only add DocC Plugin when building docs, so that clients of this library won't
// unnecessarily also get the DocC Plugin
let environmentVariables = ProcessInfo.processInfo.environment
let shouldIncludeDocCPlugin = environmentVariables["INCLUDE_DOCC_PLUGIN"] == "true"

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/quick/nimble", exact: "13.7.1"),
    .package(
        url: "https://github.com/pointfreeco/swift-snapshot-testing",
        exact: "1.18.9"
    )
]
if shouldIncludeDocCPlugin {
    // Versions 1.4.0 and 1.4.1 are failing to compile, so we are pinning it to 1.3.0 for now
    // https://github.com/RevenueCat/purchases-ios/pull/4216
    dependencies.append(.package(
        url: "https://github.com/apple/swift-docc-plugin",
        revision: "26ac5758409154cc448d7ab82389c520fa8a8247"
    ))
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
                    dependencies: [
                        "ReceiptParser",
                        .product(name: "Nimble", package: "nimble")
                    ],
                    exclude: ["ReceiptParserTests-Info.plist"]),
        // RevenueCatUI
        .target(name: "RevenueCatUI",
                dependencies: ["RevenueCat"],
                path: "RevenueCatUI",
                resources: [
                    // Note: these have to match the values in RevenueCatUI.podspec
                    .copy("Resources/background.jpg"),
                    .process("Resources/icons.xcassets"),
                    .process("Resources/Media.xcassets")
                ],
                swiftSettings: ciCompilerFlags + additionalCompilerFlags),
        .testTarget(name: "RevenueCatUITests",
                    dependencies: [
                        "RevenueCatUI",
                        .product(name: "Nimble", package: "nimble"),
                        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
                    ],
                    exclude: ["Templates/__Snapshots__", "Data/__Snapshots__", "TestPlans"],
                    resources: [
                        .copy("Resources/header.heic"),
                        .copy("Resources/background.heic"),
                        .copy("PaywallsV2/__PreviewResources__")
                    ]),
        .target(name: "RulesEngineInternal",
                path: "RulesEngineInternal",
                swiftSettings: ciCompilerFlags + additionalCompilerFlags),
        .testTarget(name: "RulesEngineInternalTests",
                    dependencies: ["RulesEngineInternal"],
                    path: "Tests/RulesEngineInternalTests",
                    exclude: ["PredicateFixtures"])
    ]
)
