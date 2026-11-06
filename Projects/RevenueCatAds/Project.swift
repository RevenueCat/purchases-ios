import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RevenueCatAds",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .framework,
    targets: [
        .target(
            name: "RevenueCatAds",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.revenuecat.RevenueCatAds",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: [
                .glob(
                    "../../AdapterSDKs/RevenueCatAds/**/*.swift",
                    excluding: [
                        "../../AdapterSDKs/RevenueCatAds/.build/**",
                        "../../AdapterSDKs/RevenueCatAds/Tests/**",
                        "../../AdapterSDKs/RevenueCatAds/Examples/**",
                        "../../AdapterSDKs/RevenueCatAds/Package.swift"
                    ]
                )
            ],
            dependencies: [
                .revenueCat,
                .external(name: "PrebidMobile")
            ]
        )
    ]
)
