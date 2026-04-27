import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RCTTester",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .appProject,
    targets: [
        .target(
            name: "RCTTester",
            destinations: [.iPhone, .iPad, .appleTv],
            product: .app,
            bundleId: "com.revenuecat.rcttester",
            deploymentTargets: .multiplatform(iOS: "15.0", tvOS: "17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleIconName": "AppIcon",
                    "ITSAppUsesNonExemptEncryption": false,
                    "REVENUECAT_API_KEY": "$(REVENUECAT_API_KEY)",
                ]
            ),
            sources: [
                "../../Tests/TestingApps/RCTTester/RCTTester/**/*.swift"
            ],
            resources: [
                "../../Tests/TestingApps/RCTTester/RCTTester/**/*.xcassets",
                "../../Tests/TestingApps/RCTTester/RCTTester/**/*.storekit",
                "../../Tests/TestingApps/RCTTester/RCTTester/**/*.icon",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
            ],
            settings: .appTarget(including: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "PROVISIONING_PROFILE_SPECIFIER": "$(RCT_PROVISIONING_PROFILE)",
            ])
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
