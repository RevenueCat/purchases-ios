// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo

// Only add DocC Plugin when building docs, so that clients of this library won't
// unnecessarily also get the DocC Plugin
let environmentVariables = ProcessInfo.processInfo.environment
let shouldIncludeDocCPlugin = environmentVariables["INCLUDE_DOCC_PLUGIN"] == "true"

var dependencies: [Package.Dependency] = []
if shouldIncludeDocCPlugin {
    dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
}

let package = Package(
    name: "RevenueCat",
    platforms: [
        .macOS(.v10_13),
        .watchOS("6.2"),
        .tvOS(.v11),
        .iOS(.v11)
    ],
    products: [
        .library(name: "RevenueCat",
                 targets: ["RevenueCat"]),
        .library(name: "ReceiptParser",
                 targets: ["ReceiptParser"])
    ],
    dependencies: dependencies,
    targets: [
        .target(name: "RevenueCat",
                path: "Sources",
                exclude: ["Info.plist"]),
        .target(name: "ReceiptParser",
                path: "LocalReceiptParsing")
    ]
)
