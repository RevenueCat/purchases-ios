// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo

// Only add DocC Plugin when building docs, so that clients of this library won't
// unnecessarily also get the DocC Plugin
let environmentVariables = ProcessInfo.processInfo.environment
let shouldIncludeDocCPlugin = environmentVariables["INCLUDE_DOCC_PLUGIN"] == "true"

var dependencies: [Package.Dependency] = [
    .package(url: "git@github.com:Quick/Nimble.git", revision: "1f3bde57bde12f5e7b07909848c071e9b73d6edc"),
    // SST requires iOS 13 starting from version 1.13.0
    .package(
        url: "git@github.com:pointfreeco/swift-snapshot-testing.git",
        revision: "26ed3a2b4a2df47917ca9b790a57f91285b923fb"
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

let package = Package(
    name: "RevenueCat",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15),
        .watchOS("6.2"),
        .tvOS(.v13),
        .iOS(.v13)
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
                ]),
        .target(name: "RevenueCat_CustomEntitlementComputation",
                path: "CustomEntitlementComputation",
                exclude: ["Info.plist", "LocalReceiptParsing/ReceiptParser-only-files"],
                resources: [
                    .copy("PrivacyInfo.xcprivacy")
                ],
                swiftSettings: [.define("ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION")]),
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
                    .copy("Resources/background.jpg"),
                    .process("Resources/icons.xcassets")
                ]),
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
