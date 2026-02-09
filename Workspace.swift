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
    "./Projects/RevenueCatTests",
    "./Projects/RevenueCat",
    "./Projects/RevenueCatUI",
    "./Projects/BinarySizeTest",
    "./Projects/RCTTester"
]

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
