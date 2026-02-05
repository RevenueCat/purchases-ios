import ProjectDescription
import ProjectDescriptionHelpers

let destinations: Destinations = [
    .iPhone
]

let deploymentTargets: DeploymentTargets = .iOS("13.0")

let project = Project(
    name: "XCFrameworkTester",
    organizationName: .revenueCatOrgName,
    settings: .appProject,
    targets: [
        .target(
            name: "XCFrameworkTester",
            destinations: destinations,
            product: .app,
            bundleId: "com.revenuecat.xcframeworktester",
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
                "XCFrameworkTester/Sources/**/*.swift"
            ],
            dependencies: [
                .xcframework(path: "../../RevenueCat.xcframework")
            ],
            settings: .appTarget
        )
    ],
    schemes: [
        .scheme(
            name: "XCFrameworkTester",
            shared: true,
            buildAction: .buildAction(targets: ["XCFrameworkTester"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release")
        )
    ]
)

