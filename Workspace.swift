import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let magicWeatherProject: Path = Environment.local
    ? "./Examples/MagicWeather/"
    : "./Examples/MagicWeatherRemote/"
let magicWeatherSwiftUIProject: Path = Environment.local
    ? "./Examples/MagicWeatherSwiftUI/"
    : "./Examples/MagicWeatherSwiftUIRemote/"
let purchaseTesterProject: Path = Environment.local
    ? "./Examples/PurchaseTester/"
    : "./Examples/PurchaseTesterRemote/"
let maestroProject: Path = Environment.local
    ? "./Examples/Maestro/"
    : "./Examples/MaestroRemote/"

var projects: [Path] = [
    maestroProject,
    magicWeatherProject,
    magicWeatherSwiftUIProject,
    "./Examples/testCustomEntitlementsComputation/",
    purchaseTesterProject,
    "./Projects/PaywallsTester",
    "./Projects/APITesters",
    "./Projects/PaywallValidationTester"
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
    .glob(pattern: "Global.xcconfig"),
    .glob(pattern: "Tests/TestPlans/**/*.xctestplan"),
    .glob(pattern: "Tests/RevenueCatUITests/TestPlans/**/*.xctestplan")
]
if FileManager.default.fileExists(atPath: "Local.xcconfig") {
    additionalFiles.append(.glob(pattern: "Local.xcconfig"))
}

let workspace = Workspace(
    name: "RevenueCat-Tuist",
    projects: projects,
    additionalFiles: additionalFiles
)
