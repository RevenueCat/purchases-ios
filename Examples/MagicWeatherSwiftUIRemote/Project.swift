import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "MagicWeatherSwiftUIRemote",
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
                "../MagicWeatherSwiftUI/MagicWeatherSwiftUI/Sources/**/*.swift",
                "../MagicWeatherSwiftUI/MagicWeatherSwiftUI/Constants.swift"
            ],
            resources: [
                "../MagicWeatherSwiftUI/MagicWeatherSwiftUI/Resources/**/*.xcassets",
            ],
            dependencies: [
                .package(product: "RevenueCat", type: .runtime),
                .package(product: "RevenueCatUI", type: .runtime)
            ],
            settings: .appTarget
        )
    ]
)
