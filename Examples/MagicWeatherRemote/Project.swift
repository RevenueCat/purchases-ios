import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "MagicWeatherRemote",
    organizationName: .revenueCatOrgName,
    packages: [
        .remote(
            url: "https://github.com/RevenueCat/purchases-ios",
            requirement: .branch("main")
        )
    ],
    settings: .appProject,
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
                "../MagicWeather/MagicWeather/Sources/**/*.swift",
                "../MagicWeather/MagicWeather/Constants.swift"
            ],
            resources: [
                "../MagicWeather/MagicWeather/Resources/**/*.xcassets",
            ],
            dependencies: [
                .package(product: "RevenueCat", type: .runtime),
                .package(product: "RevenueCatUI", type: .runtime)
            ],
            settings: .appTarget
        )
    ]
)
