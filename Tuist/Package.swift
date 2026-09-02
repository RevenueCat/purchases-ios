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

    // Test dependencies that must be built as dynamic frameworks to fix
    // "Attempted to report a test failure to XCTest while no test case was running"
    // (see https://github.com/Quick/Nimble/issues/1101). These also declare deployment minimums
    // below the floors newer Xcode SDKs enforce, so they receive the overrides below.
    let testFrameworkDependencies = [
        "Nimble", "NimbleObjectiveC",
        "CwlPreconditionTesting", "CwlPosixPreconditionTesting",
        "CwlCatchException", "CwlMachBadInstructionHandler",
        "SnapshotTesting", "OHHTTPStubs", "OHHTTPStubsSwift"
    ]

    // Our own frameworks and their binary dependencies, built as dynamic frameworks (the default for
    // several of these would otherwise be `.staticFramework`).
    var productTypes: [String: ProjectDescription.Product] = [
        "RevenueCat": .framework,
        "RevenueCatUI": .framework,
        "Purchases": .framework,
        "GoogleMobileAds": .framework
    ]
    testFrameworkDependencies.forEach { productTypes[$0] = .framework }

    // SDK-conditional deployment-target overrides, mirroring `Target+DeploymentTargetOverrides.swift`.
    // Applied per target (target level), which overrides the deployment target Tuist derives from each
    // package's platforms only when building against a newer Xcode SDK. `CwlCatchExceptionSupport` is a
    // transitive Cwl target that is built (so it needs the override) but isn't forced to a framework.
    let xcodeDeploymentTargetOverrides: SettingsDictionary = [
        "IPHONEOS_DEPLOYMENT_TARGET[sdk=iphoneos27*]": "15.0",
        "IPHONEOS_DEPLOYMENT_TARGET[sdk=iphonesimulator27*]": "15.0",
        // Mac Catalyst derives its minimum from the iOS deployment target under the macOS SDK.
        "IPHONEOS_DEPLOYMENT_TARGET[sdk=macosx27*]": "15.0",
        "TVOS_DEPLOYMENT_TARGET[sdk=appletvos27*]": "15.0",
        "TVOS_DEPLOYMENT_TARGET[sdk=appletvsimulator27*]": "15.0",
        "WATCHOS_DEPLOYMENT_TARGET[sdk=watchos27*]": "9.0",
        "WATCHOS_DEPLOYMENT_TARGET[sdk=watchsimulator27*]": "9.0",
        "MACOSX_DEPLOYMENT_TARGET[sdk=macosx27*]": "12.0"
    ]
    let deploymentOverrideTargets = testFrameworkDependencies + ["CwlCatchExceptionSupport"]

    let packageSettings = PackageSettings(
        productTypes: productTypes,
        targetSettings: deploymentOverrideTargets.reduce(into: [:]) { result, target in
            result[target] = .settings(base: xcodeDeploymentTargetOverrides)
        }
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
        )
    ] : []
)
