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
                "GADApplicationIdentifier": "$(RC_GAD_APPLICATION_IDENTIFIER)",
                "RC_REVENUECAT_API_KEY": "$(RC_REVENUECAT_API_KEY)",
                "RC_PROXY_URL": "$(RC_PROXY_URL)",
                "RC_BANNER_AD_UNIT_ID_OVERRIDE": "$(RC_BANNER_AD_UNIT_ID_OVERRIDE)",
                "RC_INTERSTITIAL_AD_UNIT_ID_OVERRIDE": "$(RC_INTERSTITIAL_AD_UNIT_ID_OVERRIDE)",
                "RC_APP_OPEN_AD_UNIT_ID_OVERRIDE": "$(RC_APP_OPEN_AD_UNIT_ID_OVERRIDE)",
                "RC_REWARDED_AD_UNIT_ID_OVERRIDE": "$(RC_REWARDED_AD_UNIT_ID_OVERRIDE)",
                "RC_REWARDED_INTERSTITIAL_AD_UNIT_ID_OVERRIDE": "$(RC_REWARDED_INTERSTITIAL_AD_UNIT_ID_OVERRIDE)",
                "RC_NATIVE_AD_UNIT_ID_OVERRIDE": "$(RC_NATIVE_AD_UNIT_ID_OVERRIDE)",
                "RC_NATIVE_VIDEO_AD_UNIT_ID_OVERRIDE": "$(RC_NATIVE_VIDEO_AD_UNIT_ID_OVERRIDE)",
                "RC_INVALID_AD_UNIT_ID_OVERRIDE": "$(RC_INVALID_AD_UNIT_ID_OVERRIDE)"
            ]),
            sources: ["../../AdapterSDKs/RevenueCatAdMob/Examples/AdMobIntegrationSample/Sources/**"],
            dependencies: [
                .revenueCat,
                .revenueCatAdMob,
                .googleMobileAds
            ],
            settings: .appTarget(including: [
                "RC_GAD_APPLICATION_IDENTIFIER": "ca-app-pub-3940256099942544~1458002511",
                "RC_REVENUECAT_API_KEY": "",
                "RC_PROXY_URL": "",
                "RC_BANNER_AD_UNIT_ID_OVERRIDE": "",
                "RC_INTERSTITIAL_AD_UNIT_ID_OVERRIDE": "",
                "RC_APP_OPEN_AD_UNIT_ID_OVERRIDE": "",
                "RC_REWARDED_AD_UNIT_ID_OVERRIDE": "",
                "RC_REWARDED_INTERSTITIAL_AD_UNIT_ID_OVERRIDE": "",
                "RC_NATIVE_AD_UNIT_ID_OVERRIDE": "",
                "RC_NATIVE_VIDEO_AD_UNIT_ID_OVERRIDE": "",
                "RC_INVALID_AD_UNIT_ID_OVERRIDE": ""
            ])
        )
    ]
)
