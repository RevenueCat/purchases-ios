import ProjectDescription
import ProjectDescriptionHelpers
import Foundation

let project = Project(
    name: "AutomatedSDKTestsApp",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .appProject,
    targets: [
        .target(
            name: "AutomatedSDKTestsApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.revenuecat.maestro.ios",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "REVENUECAT_API_KEY": "$(REVENUECAT_API_KEY)",
                    "REVENUECAT_PROXY_URL_SCHEME": "$(REVENUECAT_PROXY_URL_SCHEME)",
                    "REVENUECAT_PROXY_URL_HOST": "$(REVENUECAT_PROXY_URL_HOST)",
                    "REVENUECAT_FORCE_SERVER_ERROR_STRATEGY": "$(REVENUECAT_FORCE_SERVER_ERROR_STRATEGY)",
                    "REVENUECAT_API_HOST": "$(REVENUECAT_API_HOST)"
                ]
            ),
            sources: ["AutomatedSDKTestsApp/Sources/**/*.swift"],
            resources: [
                "AutomatedSDKTestsApp/Resources/**/*.xcassets",
                "AutomatedSDKTestsApp/Resources/StoreKit/app787ddb07e6.storekit",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .storeKit
            ],
            settings: .appTarget(including: [
                "ENABLE_TESTING_SEARCH_PATHS[sdk=iphonesimulator*]": "YES",
            ])
        )
    ],
    schemes: [
        .scheme(
            name: "AutomatedSDKTestsApp",
            shared: true,
            hidden: false,
            buildAction: .buildAction(targets: ["AutomatedSDKTestsApp"], findImplicitDependencies: true),
            runAction: .runAction(
                configuration: "Debug",
                executable: "AutomatedSDKTestsApp",
                options: .options(
                    storeKitConfigurationPath: "AutomatedSDKTestsApp/Resources/StoreKit/StoreKitConfiguration.storekit"
                )
            )
        )
    ]
)
