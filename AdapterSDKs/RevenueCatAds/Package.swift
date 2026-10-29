// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "RevenueCatAds",
    platforms: [
        .iOS(.v15),
        // The package is iOS-only, but SPM requires platform minimums >= those of dependencies.
        // RevenueCat declares macOS 10.15 / tvOS 13 / watchOS 6.2, so we must match them here
        // or SPM fills in lower defaults and fails dependency resolution.
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS("6.2")
    ],
    products: [
        .library(name: "RevenueCatAds", targets: ["RevenueCatAds"])
    ],
    dependencies: [
        .package(name: "purchases-ios", path: "../.."),
        .package(url: "https://github.com/prebid/prebid-mobile-ios.git", "3.3.1"..<"4.0.0")
    ],
    targets: [
        .target(
            name: "RevenueCatAds",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "PrebidMobile",
                         package: "prebid-mobile-ios",
                         condition: .when(platforms: [.iOS]))
            ]),
        .testTarget(
            name: "RevenueCatAdsTests",
            dependencies: [
                "RevenueCatAds",
                .product(name: "PrebidMobile",
                         package: "prebid-mobile-ios",
                         condition: .when(platforms: [.iOS]))
            ])
    ]
)
