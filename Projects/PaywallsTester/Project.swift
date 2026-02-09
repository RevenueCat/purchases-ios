import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

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

// Build the schemes list
var schemes: [Scheme] = [
    .scheme(
        name: "PaywallsTester - SK Config",
        shared: true,
        buildAction: .buildAction(targets: ["PaywallsTester"]),
        runAction: .runAction(
            configuration: "Debug",
            executable: "PaywallsTester",
            options: .options(
                storeKitConfigurationPath: "../../Tests/TestingApps/PaywallsTester/PaywallsTester/Products.storekit"
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
                storeKitConfigurationPath: "../../Tests/TestingApps/PaywallsTester/PaywallsTester/Products.storekit"
            )
        )
    )
]

// Add custom scheme if TUIST_SK_CONFIG_PATH is set
if let customStorekitPath = Environment.storekitConfigPath {
    schemes.append(
        .scheme(
            name: "PaywallsTester - Custom",
            shared: true,
            buildAction: .buildAction(targets: ["PaywallsTester"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "PaywallsTester",
                options: .options(
                    storeKitConfigurationPath: Path(stringLiteral: customStorekitPath)
                )
            )
        )
    )
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
    schemes: schemes
)
