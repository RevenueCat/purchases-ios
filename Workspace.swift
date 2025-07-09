import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

var projects: [Path] = [
    "./Examples/rc-maestro/",
    "./Examples/MagicWeather/",
    "./Examples/MagicWeatherSwiftUI/",
    "./Examples/testCustomEntitlementsComputation/",
    "./Examples/PurchaseTester/",
    "./Projects/PaywallTester",
    "./Projects/APITesters"
]

if Environment.local {
    projects.append("./Projects/RevenueCat")
    projects.append("./Projects/RevenueCatUI")
} else {
    // Needs 3.0.0 of Purchases.
    // Only when TUIST_RC_LOCAL=false tuist generate
    projects.append("./Projects/v3LoadShedderIntegration")
}

var additionalFiles: [FileElement] = [
    .glob(pattern: "Global.xcconfig")
]
if FileManager.default.fileExists(atPath: "Local.xcconfig") {
    additionalFiles.append(.glob(pattern: "Local.xcconfig"))
}

let workspace = Workspace(
    name: "RevenueCat-Workspace",
    projects: projects,
    additionalFiles: additionalFiles
)
