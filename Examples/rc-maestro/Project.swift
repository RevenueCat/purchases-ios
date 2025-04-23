import ProjectDescription

let appTarget: Target = .target(
    name: "Maestro-Debug",
    destinations: .iOS,
    product: .app,
    bundleId: "com.revenuecat.maestro.ios",
    infoPlist: .extendingDefault(
        with: [
            "UILaunchScreen": [
                "UIColorName": "",
                "UIImageName": "",
            ],
        ]
    ),
    sources: ["rc-maestro/Sources/**/*.swift"],
    resources: [
        "rc-maestro/Resources/**/*.xcassets"
    ],
    dependencies: [
        .external(name: "RevenueCat"),
        .external(name: "RevenueCatUI"),
    ]
)

let runActionOptions: RunActionOptions = .options(
    storeKitConfigurationPath: "rc-maestro/Resources/StoreKit/StoreKitConfigDefault.storekit"
)

let appScheme: Scheme = .scheme(
    name: "Maestro-Debug",
    shared: true,
    hidden: false,
    buildAction: .buildAction(targets: ["Maestro-Debug"], findImplicitDependencies: false),
    runAction: .runAction(
        configuration: "Debug",
        executable: "Maestro-Debug",
        options: runActionOptions
    )
)

let project = Project(
    name: "Maestro",
    organizationName: "RevenueCat",
    targets: [appTarget],
    schemes: [appScheme]
)