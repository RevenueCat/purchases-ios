// swift-tools-version: 6.0
@preconcurrency import PackageDescription
import Foundation

// When set to "false", skips downloading external test/dev dependencies
// to speed up `tuist install` in CI jobs that only build app targets.
let includeTestDependencies = ProcessInfo.processInfo.environment["TUIST_INCLUDE_TEST_DEPENDENCIES"]?.lowercased() != "false"

if !includeTestDependencies {
    print("⚠️ TUIST_INCLUDE_TEST_DEPENDENCIES=false: skipping external dependencies. Set to true or unset to include them.")
}

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            // Nimble and its dependencies must be dynamic frameworks
            // to fix "Attempted to report a test failure to XCTest while no test case was running"
            // See: https://github.com/Quick/Nimble/issues/1101
            "Nimble": .framework,
            "NimbleObjectiveC": .framework,
            "CwlPreconditionTesting": .framework,
            "CwlPosixPreconditionTesting": .framework,
            "CwlCatchException": .framework,
            "CwlMachBadInstructionHandler": .framework,
            // Other frameworks
            "SnapshotTesting": .framework, // default is .staticFramework,
            "RevenueCat": .framework,
            "RevenueCatUI": .framework,
            "Purchases": .framework,
            "GoogleMobileAds": .framework,
            "OHHTTPStubs": .framework,
            "OHHTTPStubsSwift": .framework
        ]
    )

#endif

let package = Package(
    name: "Dependencies",
    dependencies: includeTestDependencies ? [
        .package(
            url: "https://github.com/quick/nimble",
            exact: "13.7.1"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            exact: "1.18.9"
        ),
        .package(
            url: "https://github.com/RevenueCat/purchases-ios",
            branch: "main"
        ),

        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            "12.0.0"..<"14.0.0"
        ),
        .package(
            url: "https://github.com/AliSoftware/OHHTTPStubs",
            revision: "9.1.0"
        ),
        .package(
            url: "https://github.com/apple/swift-protobuf",
            from: "1.28.1"
        )
    ] : []
)
