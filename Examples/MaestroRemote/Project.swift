import ProjectDescription
import ProjectDescriptionHelpers
import Foundation

let project = Project(
    name: "MaestroRemote",
    organizationName: .revenueCatOrgName,
    packages: [
        .remote(
            url: "https://github.com/RevenueCat/purchases-ios",
            requirement: .branch("main")
        )
    ],
    settings: .appProject,
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
            sources: ["../Maestro/rc-maestro/Sources/**/*.swift"],
            resources: [
                "../Maestro/rc-maestro/Resources/**/*.xcassets",
            ],
            dependencies: [
                .package(product: "RevenueCat", type: .runtime),
                .package(product: "RevenueCatUI", type: .runtime),
                .storeKit
            ],
            settings: .appTarget
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
                    storeKitConfigurationPath: "../Maestro/rc-maestro/Resources/StoreKit/StoreKitConfiguration.storekit"
                )
            )
        )
    ]
)
