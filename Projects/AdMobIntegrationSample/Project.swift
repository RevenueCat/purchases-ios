import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AdMobIntegrationSample",
    organizationName: .revenueCatOrgName,
    // RevenueCat is resolved transitively via the AdMob package's dependency on purchases-ios.
    packages: .adMobPackage,
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
            sources: ["../../AdapterSDKs/RevenueCatAdMob/Examples/AdMobIntegrationSample/Sources/**"],
            dependencies: [
                .revenueCat,
                .revenueCatAdMob,
                .googleMobileAds
            ],
            settings: .appTarget
        )
    ]
)
