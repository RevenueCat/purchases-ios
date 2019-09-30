// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Purchases",
    platforms: [
      .macOS(.v10_12), .iOS(.v9)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Purchases",
            targets: ["Purchases"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .branch("feature/spm-support")),
        .package(url: "https://github.com/Quick/Nimble", .exact("8.0.4"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Purchases",
            dependencies: [],
            path: ".",
            sources: ["Purchases", "Purchases/Public"],
            publicHeadersPath: "Purchases/Public",
            cSettings: [
                .headerSearchPath("Purchases"),
                .headerSearchPath("Purchases/Public")
            ]),
        .testTarget(
            name: "PurchasesTests",
            dependencies: ["Purchases", "OHHTTPStubs", "Nimble"],
            path: "PurchasesTests",
            exclude: [],
            sources: nil),
    ]
)


