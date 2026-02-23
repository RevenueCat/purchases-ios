import ProjectDescription

let project = Project(
    name: "AdMobIntegrationSample",
    targets: [
        .target(
            name: "AdMobIntegrationSample",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.revenuecat.sample.admob",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511"
            ]),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "RevenueCat", path: "../../Projects/RevenueCat"),
                .external(name: "GoogleMobileAds"),
                .project(target: "RevenueCatAdMob", path: "../../Projects/RevenueCatAdMob")
            ]
        )
    ]
)
