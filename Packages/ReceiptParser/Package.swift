// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReceiptParser",
    platforms: [
        .macOS(.v10_13),
        .watchOS("6.2"),
        .tvOS(.v11),
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "ReceiptParser",
            type: .static,
            targets: ["ReceiptParser"])
    ],
    dependencies: [
        .package(url: "git@github.com:Quick/Nimble.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "ReceiptParser",
            dependencies: [],
            swiftSettings: [
                .unsafeFlags(["-enable-library-evolution"])
            ]
        ),
        .testTarget(
            name: "ReceiptParserTests",
            dependencies: ["ReceiptParser", "Nimble"]
        )
    ]
)
