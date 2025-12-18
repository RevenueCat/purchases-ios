import ProjectDescription

let project = Project(
    name: "Maestro",
    organizationName: "RevenueCat",
    settings: .settings(
        configurations: [
            .debug(name: "Debug", xcconfig: .relativeToManifest("rc-maestro/Resources/Local.xcconfig"))
        ],
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
                    "REVENUECAT_API_KEY": "$(REVENUECAT_API_KEY)"
                ]
            ),
            sources: ["rc-maestro/Sources/**/*.swift"],
            resources: [
                "rc-maestro/Resources/**/*.xcassets",
            ],
            dependencies: [
                .external(name: "RevenueCat"),
                .external(name: "RevenueCatUI"),
                .sdk(name: "StoreKit", type: .framework, status: .required)
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
    ],
    additionalFiles: [
        "rc-maestro/Resources/**/Local.xcconfig.sample",
        "rc-maestro/Resources/**/Local.xcconfig"
    ]
)