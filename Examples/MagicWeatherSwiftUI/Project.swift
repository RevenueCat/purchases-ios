import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "MagicWeatherSwiftUI",
    organizationName: .revenueCatOrgName,
    settings: .settings(base: [:].automaticCodeSigning(devTeam: .revenueCatTeamID)),
    targets: [
        .target(
            name: "MagicWeatherSwiftUI",
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
                "MagicWeatherSwiftUI/Sources/**/*.swift",
                "MagicWeatherSwiftUI/Constants.swift"
                ],
            resources: [
                "MagicWeatherSwiftUI/Resources/**/*.xcassets",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
            ]
        )
    ],
)