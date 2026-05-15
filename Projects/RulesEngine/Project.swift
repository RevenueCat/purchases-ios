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
        ),
        .target(
            name: "RulesEngineTests",
            destinations: .allRevenueCat,
            product: .unitTests,
            bundleId: "com.revenuecat.RulesEngineTests",
            deploymentTargets: .allRevenueCat,
            infoPlist: .default,
            sources: [
                "../../Tests/RulesEngineTests/**/*.swift"
            ],
            dependencies: [
                .target(name: "RulesEngine")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "RulesEngine",
            shared: true,
            buildAction: .buildAction(targets: ["RulesEngine"]),
            testAction: .targets([
                .testableTarget(target: "RulesEngineTests")
            ]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
