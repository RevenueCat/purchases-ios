// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnapshotTestingStub",
    platforms: [.iOS(.v15), .macOS(.v12), .watchOS(.v9)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SnapshotTestingStub",
            targets: ["SnapshotTestingStub"]),
    ],
    // Why is SnapshotTestingStub needed?
    //
    // At the time of the writing, we still support iOS 13 and iOS 14, which need macOS 12 to run tests in the simulator.
    // CircleCI bundles Xcode 14.2 with the macOS 12 image, which comes with Swift 5.7.
    // Emerge's SnapshotPreviews package currently has a dependency on the https://github.com/swhitty/FlyingFox package version 0.16 which requires Swift 5.8.
    // When we open Revenuecat.xcodeproj in Xcode 14.2, it tries to pull all dependencies, including SnapshotPreviews, and fails to build because of the FlyingFox dependency.
    // This prevents us from running tests in the iOS 13 and iOS 14 simulators.
    // It is not possible to add a package to an Xcode project conditionally on the Swift version used, but we can create a stub package that only depends on SnapshotPreviews,
    // and only pulls the dependency for Swift 5.8.
    dependencies: [
        .package(url: "https://github.com/EmergeTools/SnapshotPreviews.git", .upToNextMajor(from: "0.10.24")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SnapshotTestingStub", dependencies: [.product(name: "SnapshottingTests", package: "SnapshotPreviews")]),

    ]
)
