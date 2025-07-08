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

let project = Project(
    name: "PaywallTester",
    organizationName: .revenueCatOrgName,
    settings: .settings(
        base: [:].automaticCodeSigning(devTeam: .revenueCatTeamID),
        configurations: .xcconfigFileConfigurations,
        defaultSettings: .essential
    ),
    targets: [
        .target(
            name: "PaywallTester",
            destinations: allDestinations,
            product: .app,
            bundleId: "com.revenuecat.PaywallTester",
            deploymentTargets: allDeploymentTargets,
            infoPlist: "../../Tests/TestingApps/PaywallsTester/PaywallsTester/Info.plist",
            sources: [
                "../../Tests/TestingApps/PaywallsTester/PaywallsTester/**/*.swift"
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .storeKit
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "PaywallTester - SK Config",
            shared: true,
            buildAction: .buildAction(targets: ["PaywallTester"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "PaywallTester",
                options: .options(
                    storeKitConfigurationPath: "../../Tests/TestingApps/PaywallsTester/PaywallsTester/Products.storekit"
                )
            )
        ),
        .scheme(
            name: "PaywallTester - Live Config",
            shared: true,
            buildAction: .buildAction(targets: ["PaywallTester"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "PaywallTester"
            )
        )
    ]
)
