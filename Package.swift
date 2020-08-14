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
    let objcSources = ["Purchases/Info.plist",
                       "Purchases/Caching",
                       "Purchases/FoundationExtensions",
                       "Purchases/Misc",
                       "Purchases/Networking",
                       "Purchases/Public",
                       "Purchases/Purchasing",
                       "Purchases/ProtectedExtensions",
                       "Purchases/SubscriberAttributes",
                       "Purchases/SwiftInterfaces",
                       "Purchases/SPMSwiftInterfaces"]
    let infoPlist = "Purchases/Info.plist"
    let swiftSources = "Purchases/SwiftSources"
    
    let baseTargets: [Target] = [
        .target(name: "Purchases",
                dependencies: ["PurchasesSwift"],
                path: ".",
                exclude: [infoPlist, swiftSources],
                sources: ["Purchases"],
                publicHeadersPath: "Purchases/Public",
                cSettings: objcSources.map { CSetting.headerSearchPath($0) }
        ),
        .target(name: "PurchasesSwift",
                dependencies: [],
                path: ".",
                exclude: [infoPlist] + objcSources,
                sources: ["Purchases"],
                publicHeadersPath: swiftSources)]

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
            .macOS(.v10_12), .iOS(.v9), .watchOS("6.2"), .tvOS(.v9)
        ],
        products: [
            .library(name: "Purchases",
                    targets: ["Purchases"]),
        ],
        dependencies: resolveDependencies(),
        targets: resolveTargets()
)


