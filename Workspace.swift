import ProjectDescription
import ProjectDescriptionHelpers

// projects that are commented will be enabled one by one

var projects: [Path] = [
    "./Examples/rc-maestro/",
    "./Examples/MagicWeather/",
    "./Examples/MagicWeatherSwiftUI/",
    "./Examples/testCustomEntitlementsComputation/",
    "./Projects/PaywallTester",
    "./Projects/APITesters"
    //	  "./Examples/SampleCat/"
]

if Environment.local {
    projects.append("./Projects/RevenueCat")
    projects.append("./Projects/RevenueCatUI")
}

let workspace = Workspace(
    name: "RevenueCat-Workspace",
    projects: projects,
    additionalFiles: [
        "Local.xcconfig",
        "Global.xcconfig"
    ]
)
