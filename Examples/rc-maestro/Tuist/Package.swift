// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "RevenueCat": .framework,
            "RevenueCatUI": .framework // default is .staticFramework
        ]
    )

#endif

let package = Package(
    name: "Dependencies",
    dependencies: [
        .package(
            url: "https://github.com/RevenueCat/purchases-ios", 
            branch: "main"
        ),
    ]
)
