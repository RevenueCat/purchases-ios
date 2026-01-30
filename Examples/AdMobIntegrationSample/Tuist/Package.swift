// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AdMobIntegrationSample",
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm", exact: "5.56.1"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", exact: "11.2.0")
    ]
)
