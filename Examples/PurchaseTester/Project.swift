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

let project = Project(
    name: "PurchaseTester",
    organizationName: .revenueCatOrgName,
    settings: .settings(base: [:].automaticCodeSigning(devTeam: .revenueCatTeamID)),
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
                .target(name: "Core_App"),
            ],
            additionalFiles: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/PurchaseTester.entitlements",
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/PurchaseTesterStoreKitConfiguration.storekit"
            ]
        ),

        .target(
            name: "PurchaseTesterWatchOS",
            destinations: [.appleWatch],
            product: .app,
            bundleId: "com.revenuecat.sampleapp.watchkitapp",
            deploymentTargets: .watchOS("8.0"),
            infoPlist: nil,
            sources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/PurchaseTesterWatchOS/**/*.swift"
            ],
            resources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/AppIcon.xcassets",
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/Shared/Assets.xcassets",
            ],
            dependencies: [
                .target(name: "Core_WatchOS")
            ],
            settings: .settings(
                base: [
                    "GENERATE_INFOPLIST_FILE": true,
                    "CURRENT_PROJECT_VERSION": "1.0",
                    "MARKETING_VERSION": "1.0",
                    "INFOPLIST_KEY_UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationPortraitUpsideDown",
                    ],
                    "INFOPLIST_KEY_WKCompanionAppBundleIdentifier": "com.revenuecat.sampleapp",
                    "WKWatchKitApp": true,
                    "INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp": false,
                ]
            )
        ),

        .target(
            name: "Core_App",
            destinations: destinations,
            product: .framework,
            productName: "Core",
            bundleId: "com.revenuecat.Core",
            deploymentTargets: deploymentTargets,
            sources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/Core/**/*.swift",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .receiptparser,
            ]
        ),

        .target(
            name: "Core_WatchOS",
            destinations: [.appleWatch],
            product: .framework,
            productName: "Core",
            bundleId: "com.revenuecat.Core",
            deploymentTargets: .watchOS("8.0"),
            sources: [
                "../../Tests/TestingApps/PurchaseTesterSwiftUI/Core/**/*.swift",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .receiptparser,
            ]
        )
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