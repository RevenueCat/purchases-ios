import ProjectDescription
import ProjectDescriptionHelpers
import Foundation

let project = Project(
    name: "Maestro",
    organizationName: .revenueCatOrgName,
    settings: .settings(
        base: [:].automaticCodeSigning(devTeam: .revenueCatTeamID),
        configurations: .xcconfigFileConfigurations,
        defaultSettings: .essential
    ),
    targets: [
        .target(
            name: "Maestro-Debug",
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
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "Maestro-Debug",
            shared: true,
            hidden: false,
            buildAction: .buildAction(targets: ["Maestro-Debug"], findImplicitDependencies: true),
            runAction: .runAction(
                configuration: "Debug",
                executable: "Maestro-Debug",
                options: .options(
                    storeKitConfigurationPath: "rc-maestro/Resources/StoreKit/StoreKitConfiguration.storekit"
                )
            )
        )
    ]
)