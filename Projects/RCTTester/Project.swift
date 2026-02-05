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
                "../../Tests/TestingApps/RCTTester/RCTTester/**/*.storekit",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
            ],
            settings: .appTarget
        )
    ],
    schemes: [
        .scheme(
            name: "RCTTester - SK Config",
            shared: true,
            buildAction: .buildAction(targets: ["RCTTester"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "RCTTester",
                options: .options(
                    storeKitConfigurationPath: "../../Tests/TestingApps/RCTTester/RCTTester/RCTTester.storekit"
                )
            )
        ),
        .scheme(
            name: "RCTTester - Live Config",
            shared: true,
            buildAction: .buildAction(targets: ["RCTTester"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "RCTTester"
            )
        ),
        // Hide the default scheme
        .scheme(
            name: "RCTTester",
            shared: false,
            hidden: true,
            buildAction: .buildAction(targets: ["RCTTester"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "RCTTester",
                options: .options(
                    storeKitConfigurationPath: "../../Tests/TestingApps/RCTTester/RCTTester/RCTTester.storekit"
                )
            )
        )
    ]
)
