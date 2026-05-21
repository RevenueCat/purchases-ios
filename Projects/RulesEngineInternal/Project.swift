import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RulesEngineInternal",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .framework,
    targets: [
        .target(
            name: "RulesEngineInternal",
            destinations: .allRevenueCat,
            product: .framework,
            bundleId: "com.revenuecat.RulesEngineInternal",
            deploymentTargets: .allRevenueCat,
            infoPlist: .default,
            sources: [
                "../../RulesEngineInternal/**/*.swift"
            ],
            settings: .settings(
                base: ([
                    "APPLICATION_EXTENSION_API_ONLY": "YES"
                ] as SettingsDictionary).appendingTuistSwiftConditions()
            )
        ),
        .target(
            name: "RulesEngineInternalTests",
            destinations: .allRevenueCat,
            product: .unitTests,
            bundleId: "com.revenuecat.RulesEngineInternalTests",
            deploymentTargets: .allRevenueCat,
            infoPlist: .default,
            sources: [
                "../../Tests/RulesEngineInternalTests/**/*.swift"
            ],
            scripts: [
                .pre(
                    path: "../../scripts/rules_engine/download_predicate_conformance_fixtures.sh",
                    name: "Download khepri conformance fixtures",
                    basedOnDependencyAnalysis: false
                )
            ],
            dependencies: [
                .target(name: "RulesEngineInternal")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "RulesEngineInternal",
            shared: true,
            buildAction: .buildAction(targets: ["RulesEngineInternal"]),
            testAction: .testAction(
                targets: [
                    .testableTarget(target: "RulesEngineInternalTests")
                ],
                preActions: [
                    .executionAction(
                        title: "Download khepri conformance fixtures",
                        scriptText: "\"${SRCROOT}/scripts/rules_engine/download_predicate_conformance_fixtures.sh\""
                    )
                ]
            ),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
