// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "Nimble": .framework,
            "SnapshotTesting": .framework, // default is .staticFramework,
            "RevenueCat": .framework,
            "RevenueCatUI": .framework,
            "Purchases": .framework,
            "OHHTTPStubs": .framework,
            "OHHTTPStubsSwift": .framework
        ]
    )

#endif

let package = Package(
    name: "Dependencies",
    dependencies: [
        .package(
            url: "https://github.com/quick/nimble",
            exact: "13.7.1"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            revision: "26ed3a2b4a2df47917ca9b790a57f91285b923fb"
        ),
        .package(
            url: "https://github.com/RevenueCat/purchases-ios",
            branch: "main"
        ),
        .package(
            url: "https://github.com/AliSoftware/OHHTTPStubs",
            revision: "9.1.0"
        )
    ]
)
