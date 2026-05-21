import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

var projects: [Path] = [
    "./Examples/rc-maestro/",
    "./Examples/MagicWeather/",
    "./Examples/MagicWeatherSwiftUI/",
    "./Examples/testCustomEntitlementsComputation/",
    "./Examples/PurchaseTester/",
    "./Projects/PaywallsTester",
    "./Projects/APITesters",
    "./Projects/PaywallValidationTester",
    "./Projects/BinarySizeTest",
    "./Projects/RCTTester"
]

// These projects depend on external packages (Nimble, SnapshotTesting, OHHTTPStubs, GoogleMobileAds).
// Exclude them when TUIST_INCLUDE_TEST_DEPENDENCIES=false to allow skipping those downloads on CI.
if Environment.includeTestDependencies {
    projects.append("./Projects/RevenueCatTests")
    projects.append("./Projects/PaywallScreenshotTests")
    projects.append("./Projects/RevenueCatAdMob")
    projects.append("./Projects/AdMobIntegrationSample")
}

// `RulesEngineInternal` is intentionally never exposed as an SPM `.library` product or as an
// `.external(name:)` target in any of our Tuist projects — it's only ever pulled in
// transitively as an internal target of `RevenueCat`/`RevenueCatUI`. That means including
// `./Projects/RulesEngineInternal` in every mode does NOT cause the "Multiple commands produce"
// duplicate-framework error that would happen with `RevenueCat`/`RevenueCatUI`, because no
// workspace project links the local Tuist `RulesEngineInternal.framework` and the SPM-resolved
// transitive one into the same binary. Including it unconditionally lets developers run
// `tuist generate RulesEngineInternal` (or pick the `RulesEngineInternal` scheme in the workspace) without
// needing to set `TUIST_RC_XCODE_PROJECT=true`.
projects.append("./Projects/RulesEngineInternal")

// `RevenueCat` and `RevenueCatUI` ARE exposed as SPM library products consumed via
// `.package(product:)` by the workspace projects. Including the local Tuist projects
// alongside the SPM-resolved ones would produce two definitions of the same framework name
// → "Multiple commands produce" build errors. So they stay gated to `localXcodeProject`.
switch Environment.dependencyMode {
case .localXcodeProject:
    projects.append("./Projects/RevenueCat")
    projects.append("./Projects/RevenueCatUI")
case .localSwiftPackage, .remoteSwiftPackage, .remoteXcodeProject:
    break
}

// Only include XCFrameworkInstallationTests when explicitly enabled via environment variable
// This allows tuist generate to run before xcframeworks are created in CI
// Set TUIST_INCLUDE_XCFRAMEWORK_INSTALLATION_TESTS=true to include it
if Environment.includeXCFrameworkInstallationTests {
    projects.append("./Projects/XCFrameworkInstallationTests")
}

var additionalFiles: [FileElement] = [
    .glob(pattern: "Global.xcconfig"),
    .glob(pattern: "Tests/TestPlans/**/*.xctestplan"),
    .glob(pattern: "Tests/RevenueCatUITests/TestPlans/**/*.xctestplan")
]
if FileManager.default.fileExists(atPath: "CI.xcconfig") {
    additionalFiles.append(.glob(pattern: "CI.xcconfig"))
}
if FileManager.default.fileExists(atPath: "Local.xcconfig") {
    additionalFiles.append(.glob(pattern: "Local.xcconfig"))
}

let workspace = Workspace(
    name: "RevenueCat-Tuist",
    projects: projects,
    additionalFiles: additionalFiles
)
