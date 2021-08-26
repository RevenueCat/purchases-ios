// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo

func resolveTargets() -> [Target] {
    let objcSources = ["Purchases/Info.plist",
                       "Purchases/Public"]
    let infoPlist = "Purchases/Info.plist"

    let baseTargets: [Target] = [
        .target(name: "Purchases",
                dependencies: ["Purchases"],
                path: ".",
                exclude: [infoPlist],
                sources: ["Purchases"],
                publicHeadersPath: "Purchases/Public",
                cSettings: objcSources.map { CSetting.headerSearchPath($0) }
        ),
        .target(name: "Purchases",
                dependencies: [],
                path: ".",
                sources: ["Purchases"])]

    return baseTargets
}

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
    targets: resolveTargets()
)
