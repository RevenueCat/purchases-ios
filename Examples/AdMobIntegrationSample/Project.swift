import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AdMobIntegrationSample",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .appProject,
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
                .revenueCat,
                .revenueCatAdMob,
                .external(name: "GoogleMobileAds"),
            ],
            settings: .appTarget
        )
    ]
)
