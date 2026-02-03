import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RCTTester",
    organizationName: .revenueCatOrgName,
    settings: .appProject,
    targets: [
        .target(
            name: "RCTTester",
            destinations: .iOS,
            product: .app,
            bundleId: "com.revenuecat.rcttester",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "REVENUECAT_API_KEY": "$(REVENUECAT_API_KEY)",
                ]
            ),
            sources: [
                "../../Tests/TestingApps/RCTTester/RCTTester/**/*.swift"
            ],
            resources: [
                "../../Tests/TestingApps/RCTTester/RCTTester/**/*.xcassets",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
            ],
            settings: .appTarget
        )
    ]
)
