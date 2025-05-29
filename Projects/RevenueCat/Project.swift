import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "RevenueCat",
    organizationName: "RevenueCat, Inc.",
    targets: [
        // MARK: – Main library
        .target(
            name: "RevenueCat",
            destinations: .iOS,
            product: .staticLibrary,
            bundleId: "com.revenuecat.sampleapp",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: [
                .glob(
                    "../../Sources/**/*.swift",
                    excluding: [
                        "../../Sources/LocalReceiptParsing/ReceiptParser-only-files/**/*.swift"
                    ]
                )
            ]
        ),

        // MARK: – Tests
        .target(
            name: "RevenueCatTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.revenuecat.sampleapp.tests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: [
                "../../Tests/UnitTests/**/*.swift",
                "../../Tests/StoreKitUnitTests/**/*.swift",
                "../../Tests/ReceiptParserTests/Helpers/**/*.swift"
            ],
            dependencies: [
                .target(name: "RevenueCat"),
                .nimble,
                .snapshotTesting,
                .ohHTTPStubs
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "RevenueCat",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCat"]),
            testAction: .targets([
                .testableTarget(target: .init(stringLiteral: "RevenueCatTests"))
            ]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
