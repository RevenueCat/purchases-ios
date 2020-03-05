// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo

let shouldTest = ProcessInfo.processInfo.environment["TEST"] == "1"

func resolveDependencies() -> [Package.Dependency] {
    if shouldTest {
        return [
            .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .branch("feature/spm-support")),
            .package(url: "https://github.com/Quick/Nimble", .exact("8.0.4"))
        ]
    }

    return []
}

func resolveTargets() -> [Target] {
    let baseTargets: [Target] = [
        .target(name: "Purchases",
                dependencies: [],
                path: ".",
                exclude: ["Purchases/Info.plist"],
                sources: ["Purchases", "Purchases/Public"],
                publicHeadersPath: "Purchases/Public",
                cSettings: [
                    .headerSearchPath("Purchases"),
                    .headerSearchPath("Purchases/Public"),
                    .headerSearchPath("Purchases/Caching")
                ])]

    if shouldTest {
        let testTargets: [Target] = [
            .testTarget(name: "PurchasesTests",
                    dependencies: ["Purchases", "OHHTTPStubs", "Nimble"],
                    path: "PurchasesTests",
                    exclude: [],
                    sources: nil)]

        return baseTargets + testTargets
    }

    return baseTargets
}

let package = Package(
        name: "Purchases",
        platforms: [
            .macOS(.v10_12), .iOS(.v9), .watchOS("6.2"), .tvOS("13.4")
        ],
        products: [
            .library(name: "Purchases",
                    targets: ["Purchases"]),
        ],
        dependencies: resolveDependencies(),
        targets: resolveTargets()
)


