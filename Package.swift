// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo

// Only add DocC Plugin when building docs, so that clients of this library won't
// unnecessarily also get the DocC Plugin
let environmentVariables = ProcessInfo.processInfo.environment
let shouldIncludeDocCPlugin = environmentVariables["INCLUDE_DOCC_PLUGIN"] == "true"

var dependencies: [Package.Dependency] = [
    .package(url: "git@github.com:Quick/Nimble.git", from: "10.0.0"),
    .package(url: "git@github.com:pointfreeco/swift-snapshot-testing.git", from: "1.11.0")
]
if shouldIncludeDocCPlugin {
    dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
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
                path: "RevenueCatUI"),
        .testTarget(name: "RevenueCatUITests",
                    dependencies: [
                        "RevenueCatUI",
                        "Nimble",
                        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
                    ],
                    exclude: ["__Snapshots__"],
                    resources: [.copy("Resources/image_1.jpg"), .copy("Resources/image_2.jpg")])
    ]
)
