import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let allDestinations: Destinations = [
    .iPhone,
    .iPad,
    .mac,
    .macWithiPadDesign,
    .macCatalyst,
    .appleVision,
    .appleVisionWithiPadDesign
]

let allDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "18.5",
    macOS: "15.5",
    visionOS: "2.5"
)

let project = Project(
    name: "PaywallValidationTester",
    organizationName: .revenueCatOrgName,
    settings: .appProject,
    targets: [
        .target(
            name: "PaywallValidationTester",
            destinations: allDestinations,
            product: .app,
            bundleId: "com.revenuecat.PaywallValidationTester",
            deploymentTargets: allDeploymentTargets,
            infoPlist: "../../Tests/TestingApps/PaywallValidationTester/Info.plist",
            sources: [
                "../../Tests/TestingApps/PaywallValidationTester/**/*.swift",
                "../../Tests/RevenueCatUITests/PaywallsV2/PaywallPreviewResourcesLoader.swift"
            ],
            resources: [
                .folderReference(path: "../../Tests/paywall-preview-resources"),
                "../../Tests/RevenueCatUITests/Resources/header.heic",
                "../../Tests/RevenueCatUITests/Resources/background.heic"
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "PaywallValidationTester",
            shared: true,
            buildAction: .buildAction(targets: ["PaywallValidationTester"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "PaywallValidationTester"
            )
        )
    ]
)
