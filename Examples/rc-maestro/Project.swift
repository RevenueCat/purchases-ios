import ProjectDescription
import ProjectDescriptionHelpers
import Foundation

let project = Project(
    name: "Maestro",
    organizationName: .revenueCatOrgName,
    settings: .project,
    targets: [
        .target(
            name: "Maestro",
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
                    "REVENUECAT_PROXY_URL_HOST": "$(REVENUECAT_PROXY_URL_HOST)"
                ]
            ),
            sources: ["rc-maestro/Sources/**/*.swift"],
            resources: [
                "rc-maestro/Resources/**/*.xcassets",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .storeKit
            ],
            settings: .target
        )
    ],
    schemes: [
        .scheme(
            name: "Maestro",
            shared: true,
            hidden: false,
            buildAction: .buildAction(targets: ["Maestro"], findImplicitDependencies: true),
            runAction: .runAction(
                configuration: "Debug",
                executable: "Maestro",
                options: .options(
                    storeKitConfigurationPath: "rc-maestro/Resources/StoreKit/StoreKitConfiguration.storekit"
                )
            )
        )
    ]
)