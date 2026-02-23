import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RevenueCatAdMob",
    organizationName: .revenueCatOrgName,
    settings: .framework,
    targets: [
        .target(
            name: "RevenueCatAdMob",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.revenuecat.RevenueCatAdMob",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: [
                .glob(
                    "../../RevenueCatAdMob/**/*.swift",
                    excluding: [
                        "../../RevenueCatAdMob/.build/**",
                        "../../RevenueCatAdMob/Tests/**",
                        "../../RevenueCatAdMob/Support/**",
                        "../../RevenueCatAdMob/Package.swift"
                    ]
                )
            ],
            dependencies: [
                .revenueCat,
                .external(name: "GoogleMobileAds")
            ]
        ),
        .target(
            name: "RevenueCatAdMobTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.revenuecat.RevenueCatAdMobTests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: [
                "../../RevenueCatAdMob/Tests/RevenueCatAdMobTests/**/*.swift"
            ],
            dependencies: [
                .target(name: "RevenueCatAdMob"),
                .external(name: "GoogleMobileAds")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "RevenueCatAdMob",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCatAdMob"]),
            testAction: .targets([
                .testableTarget(target: .init(stringLiteral: "RevenueCatAdMobTests"))
            ]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
