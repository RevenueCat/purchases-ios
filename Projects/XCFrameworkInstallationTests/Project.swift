import ProjectDescription
import ProjectDescriptionHelpers

let allDestinations: Destinations = [
    .iPhone,
    .iPad,
    .mac,
    .macCatalyst,
    .appleWatch,
    .appleVision
]

let uiDestinations: Destinations = [
    .iPhone,
    .iPad,
    .macCatalyst,
    .appleWatch
]

let allDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "13.0",
    macOS: "11.0",
    watchOS: "7.0",
    visionOS: "1.3"
)

let uiDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "13.0",
    watchOS: "7.0"
)

let launchScreen: [String: Plist.Value] = [
    "UILaunchScreen": [
        "UIColorName": "",
        "UIImageName": "",
    ]
]

let project = Project(
    name: "XCFrameworkInstallationTests",
    organizationName: .revenueCatOrgName,
    settings: .appProject,
    targets: [
        // Tests RevenueCat xcframework on all platforms
        .target(
            name: "XCFrameworkInstallationTests",
            destinations: allDestinations,
            product: .app,
            bundleId: "com.revenuecat.xcframeworkinstallationtests",
            deploymentTargets: allDeploymentTargets,
            infoPlist: .extendingDefault(with: launchScreen),
            sources: [
                "XCFrameworkInstallationTests/Sources/**/*.swift"
            ],
            dependencies: [
                .xcframework(path: "../../RevenueCat.xcframework")
            ],
            settings: .appTarget
        ),
        // Tests RevenueCatUI xcframework on supported platforms (iOS, Mac Catalyst, watchOS)
        .target(
            name: "XCFrameworkUIInstallationTests",
            destinations: uiDestinations,
            product: .app,
            bundleId: "com.revenuecat.xcframeworkuiinstallationtests",
            deploymentTargets: uiDeploymentTargets,
            infoPlist: .extendingDefault(with: launchScreen),
            sources: [
                "XCFrameworkUIInstallationTests/Sources/**/*.swift"
            ],
            dependencies: [
                .xcframework(path: "../../RevenueCat.xcframework"),
                .xcframework(path: "../../RevenueCatUI.xcframework")
            ],
            settings: .appTarget
        )
    ],
    schemes: [
        .scheme(
            name: "XCFrameworkInstallationTests",
            shared: true,
            buildAction: .buildAction(targets: ["XCFrameworkInstallationTests"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release")
        ),
        .scheme(
            name: "XCFrameworkUIInstallationTests",
            shared: true,
            buildAction: .buildAction(targets: ["XCFrameworkUIInstallationTests"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release")
        )
    ]
)
