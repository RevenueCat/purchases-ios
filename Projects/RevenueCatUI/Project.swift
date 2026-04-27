import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RevenueCatUI",
    organizationName: .revenueCatOrgName,
    options: .options(disableBundleAccessors: true),
    packages: .projectPackages,
    settings: .framework,
    targets: [
        .target(
            name: "RevenueCatUI",
            destinations: .allRevenueCat,
            product: .framework,
            bundleId: "com.revenuecat.RevenueCatUI",
            deploymentTargets: .allRevenueCat,
            infoPlist: .default,
            sources: [
                "../../RevenueCatUI/**/*.swift"
            ],
            resources: [
                "../../RevenueCatUI/Resources/**"
            ],
            headers: .headers(
                public: ["../../RevenueCatUI/RevenueCatUI.h"]
            ),
            dependencies: [
                .revenueCat
            ],
            settings: .settings(
                base: ([:] as SettingsDictionary).appendingTuistSwiftConditions()
            )
        )
    ],
    schemes: [
        .scheme(
            name: "RevenueCatUI-Framework",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCatUI"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
