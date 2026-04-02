import ProjectDescription
import ProjectDescriptionHelpers

/// Dedicated project for building xcframeworks.
/// Uses explicit project target dependencies to ensure dynamic linking
/// between RevenueCat and RevenueCatUI (avoids singleton duplication).
let project = Project(
    name: "XCFrameworkExport",
    organizationName: .revenueCatOrgName,
    options: .options(disableBundleAccessors: true),
    settings: .framework,
    targets: [
        .target(
            name: "RevenueCat",
            destinations: .allRevenueCat,
            product: .framework,
            bundleId: "com.revenuecat.Purchases",
            deploymentTargets: .allRevenueCat,
            infoPlist: "../../Sources/Info.plist",
            sources: [
                .glob(
                    "../../Sources/**/*.swift",
                    excluding: [
                        "../../Sources/LocalReceiptParsing/ReceiptParser-only-files/**/*.swift"
                    ]
                )
            ],
            headers: .headers(
                public: ["../../Sources/RevenueCat.h"]
            ),
            settings: .settings(
                base: [
                    "APPLICATION_EXTENSION_API_ONLY": "YES"
                ]
            )
        ),
        .target(
            name: "RevenueCatUI",
            destinations: .allRevenueCat,
            product: .framework,
            bundleId: "com.revenuecat.RevenueCatUI",
            deploymentTargets: .allRevenueCat,
            infoPlist: .default,
            sources: [
                "../../RevenueCatUI/**/*.swift"
            ],
            resources: [
                "../../RevenueCatUI/Resources/**"
            ],
            headers: .headers(
                public: ["../../RevenueCatUI/RevenueCatUI.h"]
            ),
            dependencies: [
                .target(name: "RevenueCat")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "RevenueCat-XCFramework",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCat"]),
            archiveAction: .archiveAction(configuration: "Release")
        ),
        .scheme(
            name: "RevenueCatUI-XCFramework",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCatUI"]),
            archiveAction: .archiveAction(configuration: "Release")
        )
    ]
)
