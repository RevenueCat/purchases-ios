import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AdsIntegrationSample",
    organizationName: .revenueCatOrgName,
    // RevenueCat is resolved transitively via the Ads package's dependency on purchases-ios.
    packages: .adsPackage,
    settings: .appProject,
    targets: [
        .target(
            name: "AdsIntegrationSample",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.revenuecat.sample.AdsIntegrationSample",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "NSAppTransportSecurity": [
                    "NSExceptionDomains": [
                        "localhost": [
                            "NSExceptionAllowsInsecureHTTPLoads": true
                        ]
                    ]
                ]
            ]),
            sources: ["../../AdapterSDKs/RevenueCatAds/Examples/AdsIntegrationSample/Sources/**"],
            dependencies: [
                .revenueCat,
                .revenueCatAds
            ],
            settings: .appTarget
        )
    ]
)
