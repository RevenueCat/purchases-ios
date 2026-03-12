// swift-tools-version: 5.8
// RevenueCat AdMob Adapter — supports Google Mobile Ads v12.x and v13.x only.

import PackageDescription

let package = Package(
    name: "RevenueCatAdMob",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "RevenueCatAdMob", targets: ["RevenueCatAdMob"])
    ],
    dependencies: [
        .package(name: "purchases-ios", path: ".."),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            "12.0.0"..<"14.0.0"
        )
    ],
    targets: [
        .target(
            name: "RevenueCatAdMob",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            path: ".",
            exclude: ["README.md", "Tests", "Support"]
        ),
        .testTarget(
            name: "RevenueCatAdMobTests",
            dependencies: [
                "RevenueCatAdMob",
                .product(name: "RevenueCat", package: "purchases-ios")
            ],
            path: "Tests/RevenueCatAdMobTests"
        )
    ]
)
