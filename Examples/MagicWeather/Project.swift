import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "MagicWeather",
    organizationName: .revenueCatOrgName,
    targets: [
        .target(
            name: "MagicWeather",
            destinations: .iOS,
            product: .app,
            bundleId: "com.revenuecat.sampleapp",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ]
                ]
            ),
            sources: [
                "MagicWeather/Sources/**/*.swift",
                "MagicWeather/Constants.swift"
                ],
            resources: [
                "MagicWeather/Resources/**/*.xcassets",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
            ],
            settings: .settings(base: [:].automaticCodeSigning(devTeam: .revenueCatTeamID))
        )
    ]
)