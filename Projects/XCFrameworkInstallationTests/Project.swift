import ProjectDescription
import ProjectDescriptionHelpers

// Limited to platforms supported by both RevenueCat and RevenueCatUI xcframeworks
let destinations: Destinations = [
    .iPhone,
    .iPad,
    .macCatalyst,
    .appleWatch
]

let deploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "13.0",
    watchOS: "7.0"
)

let project = Project(
    name: "XCFrameworkInstallationTests",
    organizationName: .revenueCatOrgName,
    settings: .appProject,
    targets: [
        .target(
            name: "XCFrameworkInstallationTests",
            destinations: destinations,
            product: .app,
            bundleId: "com.revenuecat.xcframeworkinstallationtests",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ]
                ]
            ),
            sources: [
                "XCFrameworkInstallationTests/Sources/**/*.swift"
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
        )
    ]
)

