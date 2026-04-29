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

let uiTestDestinations: Destinations = [
    .iPhone,
    .iPad
]

let uiTestDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "18.5"
)

let project = Project(
    name: "PaywallValidationTester",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
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
                .glob(
                    "../../Tests/TestingApps/PaywallValidationTester/**/*.swift",
                    excluding: ["../../Tests/TestingApps/PaywallValidationTester/UITests/**"]
                ),
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
        ),
        .target(
            name: "PaywallValidationTesterUITests",
            destinations: uiTestDestinations,
            product: .uiTests,
            bundleId: "com.revenuecat.PaywallValidationTesterUITests",
            deploymentTargets: uiTestDeploymentTargets,
            infoPlist: .default,
            sources: [
                "../../Tests/TestingApps/PaywallValidationTester/UITests/**/*.swift"
            ],
            dependencies: [
                .target(name: "PaywallValidationTester")
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
        ),
        .scheme(
            name: "PaywallValidationTesterUITests",
            shared: true,
            buildAction: .buildAction(targets: ["PaywallValidationTester", "PaywallValidationTesterUITests"]),
            testAction: .targets(
                [.testableTarget(target: .init(stringLiteral: "PaywallValidationTesterUITests"))],
                configuration: "Debug",
                options: .options(
                    language: nil,
                    region: nil,
                    preferredScreenCaptureFormat: .screenshots
                )
            ),
            runAction: .runAction(
                configuration: "Debug",
                executable: "PaywallValidationTester"
            )
        )
    ]
)
