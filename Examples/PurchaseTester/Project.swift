import ProjectDescription
import ProjectDescriptionHelpers

let destinations: Destinations = [
    .iPhone,
    .iPad,
    .mac,
    .macWithiPadDesign,
    .macCatalyst,
    .appleTv,
    .appleVision,
    .appleVisionWithiPadDesign
]

var allDestinations = destinations 
allDestinations.insert(.appleWatch)

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

let project = Project(
    name: "PurchaseTester",
    organizationName: "RevenueCat, Inc.",
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
                .target(name: "Core"),
                .target(name: "PurchaseTesterWatchOS"),
            ]
        ),

        .target(
            name: "PurchaseTesterWatchOS",
            destinations: [.appleWatch],
            product: .watch2Extension,
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
            destinations: allDestinations,
            product: .framework,
            bundleId: "com.revenuecat.Core",
            deploymentTargets: allDeploymentTargets,
            sources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/Core/**/*.swift",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .receiptparser,
            ]
        )
    ]
)