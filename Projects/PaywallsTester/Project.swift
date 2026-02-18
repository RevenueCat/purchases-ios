import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let fileManager = FileManager.default
let projectDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let repoRoot = projectDir.deletingLastPathComponent().deletingLastPathComponent()
let paywallsTesterDir = repoRoot
    .appendingPathComponent("Tests/TestingApps/PaywallsTester/PaywallsTester")

// Update Local.xcconfig with custom API key if TUIST_RC_API_KEY is set
if let apiKey = Environment.rcApiKey {
    let localXcconfig = repoRoot.appendingPathComponent("Local.xcconfig")

    if fileManager.fileExists(atPath: localXcconfig.path),
       var contents = try? String(contentsOf: localXcconfig, encoding: .utf8) {
        // Replace existing API key or add new one
        let pattern = #"REVENUECAT_API_KEY\s*=\s*\S+"#
        if let range = contents.range(of: pattern, options: .regularExpression) {
            contents.replaceSubrange(range, with: "REVENUECAT_API_KEY = \(apiKey)")
        } else {
            contents += "\nREVENUECAT_API_KEY = \(apiKey)\n"
        }
        try? contents.write(to: localXcconfig, atomically: true, encoding: .utf8)
    }
}

// Copy custom StoreKit config to project directory if TUIST_SK_CONFIG_PATH is set
let hasCustomStoreKit = Environment.storekitConfigPath != nil
if let customPath = Environment.storekitConfigPath {
    let sourceURL = URL(fileURLWithPath: customPath)
    let destURL = paywallsTesterDir.appendingPathComponent("PaywallsTester.storekit")

    // Copy the file to the project directory
    try? fileManager.removeItem(at: destURL)
    try? fileManager.copyItem(at: sourceURL, to: destURL)
}

let allDestinations: Destinations = [
    .iPhone,
    .iPad,
    .mac,
    .macWithiPadDesign,
    .macCatalyst,
    .appleWatch,
    .appleTv,
    .appleVision,
    .appleVisionWithiPadDesign
]

let allDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "15.0",
    watchOS: "10.0",
    visionOS: "1.3"
)

// Use custom StoreKit config if TUIST_SK_CONFIG_PATH is set, otherwise use default
let storeKitConfigPath: Path = if Environment.storekitConfigPath != nil {
    // Reference the copied file in the project directory
    "../../Tests/TestingApps/PaywallsTester/PaywallsTester/PaywallsTester.storekit"
} else {
    "../../Tests/TestingApps/PaywallsTester/PaywallsTester/Products.storekit"
}

let schemes: [Scheme] = [
    .scheme(
        name: "PaywallsTester - SK Config",
        shared: true,
        buildAction: .buildAction(targets: ["PaywallsTester"]),
        runAction: .runAction(
            configuration: "Debug",
            executable: "PaywallsTester",
            options: .options(
                storeKitConfigurationPath: storeKitConfigPath
            )
        )
    ),
    .scheme(
        name: "PaywallsTester - Live Config",
        shared: true,
        buildAction: .buildAction(targets: ["PaywallsTester"]),
        runAction: .runAction(
            configuration: "Debug",
            executable: "PaywallsTester"
        )
    ),
    .scheme(
        name: "PaywallsTester - LocalKhepri",
        shared: true,
        buildAction: .buildAction(targets: ["PaywallsTester"]),
        runAction: .runAction(
            configuration: "Debug",
            executable: "PaywallsTester",
            options: .options(
                storeKitConfigurationPath:
                    "../../Tests/TestingApps/PaywallsTester/PaywallsTester/LocalKhepri.storekit"
            )
        )
    ),
    // hack to avoid having `PaywallsTester` visible in the scheme list (hidden: true)
    .scheme(
        name: "PaywallsTester",
        shared: false,
        hidden: true,
        buildAction: .buildAction(targets: ["PaywallsTester"]),
        runAction: .runAction(
            configuration: "Debug",
            executable: "PaywallsTester",
            options: .options(
                storeKitConfigurationPath: storeKitConfigPath
            )
        )
    )
]

// Build additional files list (include custom StoreKit config if present)
var additionalFiles: [FileElement] = []
if hasCustomStoreKit {
    additionalFiles.append("../../Tests/TestingApps/PaywallsTester/PaywallsTester/PaywallsTester.storekit")
}

let project = Project(
    name: "PaywallsTester",
    organizationName: .revenueCatOrgName,
    settings: .appProject,
    targets: [
        .target(
            name: "PaywallsTester",
            destinations: allDestinations,
            product: .app,
            bundleId: "com.revenuecat.PaywallsTester",
            deploymentTargets: allDeploymentTargets,
            infoPlist: "../../Tests/TestingApps/PaywallsTester/PaywallsTester/Info.plist",
            sources: [
                "../../Tests/TestingApps/PaywallsTester/PaywallsTester/**/*.swift"
            ],
            resources: [
                "../../Tests/TestingApps/PaywallsTester/PaywallsTester/**/*.xcassets"
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .storeKit
            ],
            settings: .appTarget
        )
    ],
    schemes: schemes,
    additionalFiles: additionalFiles
)
