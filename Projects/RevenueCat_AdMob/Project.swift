import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RevenueCat_AdMob",
    organizationName: .revenueCatOrgName,
    settings: .framework,
    targets: [
        .target(
            name: "RevenueCat_AdMob",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.revenuecat.RevenueCat_AdMob",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: [
                .glob(
                    "../../RevenueCat_AdMob/**/*.swift",
                    excluding: [
                        "../../RevenueCat_AdMob/.build/**",
                        "../../RevenueCat_AdMob/Tests/**"
                    ]
                )
            ],
            dependencies: [
                .revenueCat,
                .external(name: "GoogleMobileAds")
            ]
        ),
        .target(
            name: "RevenueCat_AdMobTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.revenuecat.RevenueCat_AdMobTests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: [
                "../../RevenueCat_AdMob/Tests/RevenueCat_AdMobTests/**/*.swift"
            ],
            dependencies: [
                .target(name: "RevenueCat_AdMob"),
                .external(name: "GoogleMobileAds")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "RevenueCat_AdMob",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCat_AdMob"]),
            testAction: .targets([
                .testableTarget(target: .init(stringLiteral: "RevenueCat_AdMobTests"))
            ]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
