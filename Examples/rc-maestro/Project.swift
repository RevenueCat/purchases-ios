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
            "REVENUECAT_API_KEY": "$(REVENUECAT_API_KEY)"
        ]
    ),
    sources: ["rc-maestro/Sources/**/*.swift"],
    resources: [
        "rc-maestro/Resources/**/*.xcassets",
        "rc-maestro/Resources/**/Local-SAMPLE.xcconfig",
        "rc-maestro/Resources/**/Local.xcconfig"
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
    settings: .settings(
        base: [:],
        configurations: [
            .debug(name: "Debug", xcconfig: .relativeToManifest("rc-maestro/Resources/Maestro.xcconfig"))
        ]
    ),
    targets: [appTarget],
    schemes: [appScheme]
)