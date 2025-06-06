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
    macOS: "11.0",
    watchOS: "7.0",
    tvOS: "14.0"
)

let project = Project(
    name: "PaywallTester",
    organizationName: "RevenueCat, Inc.",
    settings: .settings(
        configurations: [
            .debug(name: "Debug-SK", xcconfig: .relativeToRoot("Global.xcconfig")),
            .debug(name: "Debug")
        ],
        defaultSettings: .essential
    ),
    targets: [
        .target(
            name: "PaywallTester",
            destinations: allDestinations,
            product: .app,
            bundleId: "com.revenuecat.PaywallTester",
            deploymentTargets: .iOS("15.0"),
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
                configuration: "Debug-SK",
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
    ],
    additionalFiles: [
        "../../Local.xcconfig",
        "../../Global.xcconfig"
    ]
)
