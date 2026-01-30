import ProjectDescription

let project = Project(
    name: "AdMobIntegrationSample",
    targets: [
        .target(
            name: "AdMobIntegrationSample",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.revenuecat.sample.admob",
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511"
            ]),
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "RevenueCat"),
                .external(name: "GoogleMobileAds")
            ]
        )
    ]
)
