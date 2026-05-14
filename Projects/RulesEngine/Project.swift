import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RulesEngine",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .framework,
    targets: [
        .target(
            name: "RulesEngine",
            destinations: .allRevenueCat,
            product: .framework,
            bundleId: "com.revenuecat.RulesEngine",
            deploymentTargets: .allRevenueCat,
            infoPlist: .default,
            sources: [
                "../../RulesEngine/**/*.swift"
            ],
            settings: .settings(
                base: ([:] as SettingsDictionary).appendingTuistSwiftConditions()
            )
        )
    ],
    schemes: [
        .scheme(
            name: "RulesEngine",
            shared: true,
            buildAction: .buildAction(targets: ["RulesEngine"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
