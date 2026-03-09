import ProjectDescription
import ProjectDescriptionHelpers

let destinations: Destinations = [
    .iPhone,
    .iPad,
    .mac,
    .macCatalyst,
    .appleTv,
    .appleVision
]

let deploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "15.2",
    macOS: "13.0",
    tvOS: "15.2",
    visionOS: "1.3"
)

let allDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "15.2",
    macOS: "13.0",
    watchOS: "8.0",
    tvOS: "15.2",
    visionOS: "1.3"
)

let allDestinations = destinations + [.appleWatch]

let project = Project(
    name: "PurchaseTester",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .appProject,
    targets: [
        .target(
            name: "PurchaseTester",
            destinations: destinations,
            product: .app,
            bundleId: "com.revenuecat.sampleapp",
            deploymentTargets: deploymentTargets,
            infoPlist: "../../Tests/TestingApps/PurchaseTesterSwiftUI/PurchaseTester-Info.plist",
            sources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/Shared/**/*.swift",
            ],
            resources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/AppIcon.xcassets",
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/Shared/Assets.xcassets",
            ],
            dependencies: [
                .target(name: "Core")
            ],
            settings: .appTarget,
            additionalFiles: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/PurchaseTester.entitlements",
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/PurchaseTesterStoreKitConfiguration.storekit"
            ],
        ),

        .target(
            name: "PurchaseTesterWatchOS",
            destinations: [.appleWatch],
            product: .app,
            bundleId: "com.revenuecat.sampleapp.watchkitapp",
            deploymentTargets: .watchOS("8.0"),
            infoPlist: "../../Tests/TestingApps/PurchaseTesterSwiftUI/PurchaseTesterWatchOS/Info.plist",
            sources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/PurchaseTesterWatchOS/**/*.swift"
            ],
            resources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/AppIcon.xcassets",
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/Shared/Assets.xcassets",
            ],
            dependencies: [
                .target(name: "Core")
            ]
        ),

        .target(
            name: "Core",
            destinations: Set(allDestinations),
            product: .framework,
            bundleId: "com.revenuecat.Core",
            deploymentTargets: allDeploymentTargets,
            sources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/Core/**/*.swift",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .receiptParser,
            ],
            settings: .framework
        ),
    ],
    schemes: [
        .scheme(
            name: "PurchaseTester",
            shared: true,
            buildAction: .buildAction(targets: ["PurchaseTester"], findImplicitDependencies: true),
            runAction: .runAction(
                configuration: "Debug",
                executable: "PurchaseTester",
                options: .options(
                    storeKitConfigurationPath: "../../Tests/TestingApps/PurchaseTesterSwiftUI/PurchaseTesterStoreKitConfiguration.storekit"
                )
            )
        ),
        .scheme(
            name: "PurchaseTesterWatchOS",
            shared: true,
            buildAction: .buildAction(targets: ["PurchaseTesterWatchOS"], findImplicitDependencies: true),
            runAction: .runAction(
                configuration: "Debug",
                executable: "PurchaseTesterWatchOS"
            )
        )
    ]
)
