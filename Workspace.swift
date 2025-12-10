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
    "./Projects/RevenueCat",
    "./Projects/RevenueCatUI"
]

var additionalFiles: [FileElement] = [
    .glob(pattern: "Global.xcconfig"),
    .glob(pattern: "Tests/TestPlans/**/*.xctestplan"),
    .glob(pattern: "Tests/RevenueCatUITests/TestPlans/**/*.xctestplan")
]
if FileManager.default.fileExists(atPath: "CI.xcconfig") {
    additionalFiles.append(.glob(pattern: "CI.xcconfig"))
} else if FileManager.default.fileExists(atPath: "Local.xcconfig") {
    additionalFiles.append(.glob(pattern: "Local.xcconfig"))
}

let workspace = Workspace(
    name: "RevenueCat-Tuist",
    projects: projects,
    additionalFiles: additionalFiles
)
