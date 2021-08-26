// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo


let package = Package(
    name: "Purchases",
    platforms: [
        .macOS(.v10_12), .iOS(.v9), .watchOS("6.2"), .tvOS(.v9)
    ],
    products: [
        .library(name: "Purchases",
                 targets: ["Purchases"])
    ],
    dependencies: [],
    targets: [
        .target(name: "Purchases", sources: ["Purchases"])
    ]
)
