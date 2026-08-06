import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

// A home for static paywall fixtures: paywalls defined in code, rendered with no API key, no
// backend and no dashboard state, so tests can assert against a known component tree.
//
// iPhone-only and iOS 17+ because the tests here drive the real accessibility tree, and
// `performAccessibilityAudit` needs iOS 17 or later.
let project = Project(
    name: "PaywallFixtures",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .appProject,
    targets: [
        .target(
            name: "PaywallFixtures",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.revenuecat.PaywallFixtures",
            deploymentTargets: .iOS("17.0"),
            infoPlist: "../../Tests/TestingApps/PaywallFixtures/Info.plist",
            sources: [
                "../../Tests/TestingApps/PaywallFixtures/**/*.swift"
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI
            ],
            settings: .appTarget(including: ([:] as SettingsDictionary).appendingTuistSwiftConditions())
        ),
        .target(
            name: "PaywallFixturesUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "com.revenuecat.PaywallFixturesUITests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "../../Tests/TestingApps/PaywallFixturesUITests/**/*.swift"
            ],
            dependencies: [
                .target(name: "PaywallFixtures")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "PaywallFixturesUITests",
            shared: true,
            buildAction: .buildAction(targets: ["PaywallFixturesUITests"]),
            testAction: .targets(["PaywallFixturesUITests"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "PaywallFixtures"
            )
        ),
        .scheme(
            name: "PaywallFixtures",
            shared: true,
            buildAction: .buildAction(targets: ["PaywallFixtures"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "PaywallFixtures"
            )
        )
    ]
)
