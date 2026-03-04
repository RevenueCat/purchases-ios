// swift-tools-version:5.8
// RevenueCat AdMob Adapter — v11-compatible manifest (Google Mobile Ads 11.x, RC_ADMOB_SDK_11).
// Not redundant with ../Package.swift: main manifest uses GMA 12.x–14.x; this one pins to 11.x for
// revenuecat-admob-tests-v11 CI. That job copies this file to ../Package.swift before running tests.

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
        .package(path: ".."),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            "11.2.0"..<"12.0.0"
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
            exclude: ["README.md", "Tests", "Support"],
            swiftSettings: [
                .define("RC_ADMOB_SDK_11")
            ]
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
