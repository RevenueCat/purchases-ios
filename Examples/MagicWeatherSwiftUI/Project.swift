import ProjectDescription

let project = Project(
    name: "MagicWeatherSwiftUI",
    organizationName: "RevenueCat, Inc.",
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
                .external(name: "RevenueCat"),
                .external(name: "RevenueCatUI"),
            ]
        )
    ]
)