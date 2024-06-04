// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var dependencies: [Package.Dependency] = [
    .package(url: "git@github.com:Quick/Nimble.git", from: "10.0.0"),
    // SST requires iOS 13 starting from version 1.13.0
    .package(url: "git@github.com:pointfreeco/swift-snapshot-testing.git", .upToNextMinor(from: "1.12.0")),
    .package(url: "git@github.com:AliSoftware/OHHTTPStubs.git", .upToNextMinor(from: "9.1.0"))
]

let package = Package(
    name: "RevenueCat",
    platforms: [
            .iOS(.v16) // Specifies that the package supports iOS 16 and later
        ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RevenueCat",
            targets: ["RevenueCat"]),
    ],
    dependencies: dependencies,
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RevenueCat",
            exclude: ["Info.plist", "LocalReceiptParsing/ReceiptParser-only-files"]),
        .testTarget(
            name: "RevenueCatTests",
            dependencies: [
                "RevenueCat",
                "Nimble",
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]),
        .testTarget(
            name: "OtherTests",
            dependencies: [
                "RevenueCat",
                "Nimble",
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ])
    ]
)
