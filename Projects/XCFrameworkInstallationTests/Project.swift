import ProjectDescription
import ProjectDescriptionHelpers

let destinations: Destinations = [
    .iPhone,
    .iPad,
    .mac,
    .macCatalyst,
    .appleWatch,
    .appleVision
]

let deploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "13.0",
    macOS: "11.0",
    watchOS: "7.0",
    visionOS: "1.3"
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
                .xcframework(path: "../../RevenueCat.xcframework")
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

