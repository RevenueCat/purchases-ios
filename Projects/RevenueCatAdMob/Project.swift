import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RevenueCatAdMob",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
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
                    "../../AdapterSDKs/RevenueCatAdMob/**/*.swift",
                    excluding: [
                        "../../AdapterSDKs/RevenueCatAdMob/.build/**",
                        "../../AdapterSDKs/RevenueCatAdMob/Tests/**",
                        "../../AdapterSDKs/RevenueCatAdMob/Examples/**",
                        "../../AdapterSDKs/RevenueCatAdMob/Package.swift"
                    ]
                )
            ],
            dependencies: [
                .revenueCat,
                .external(name: "GoogleMobileAds")
            ]
        )
    ]
)
