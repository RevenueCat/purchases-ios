import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Project Definition

let project = Project(
    name: "RevenueCat",
    organizationName: .revenueCatOrgName,
    settings: .framework,
    targets: [
        // MARK: – Main Library
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
            dependencies: [
                .purchasesCore
            ],
            settings: .settings(
                base: [
                    "APPLICATION_EXTENSION_API_ONLY": "YES"
                ]
            )
        ),

        .target(
            name: "RevenueCat_CustomEntitlementComputation",
            destinations: .allPlatforms(macWithiPadDesign: true),
            product: .framework,
            bundleId: "com.revenuecat.RevenueCatCustomEntitlementComputation",
            deploymentTargets: .revenueCatInternal,
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
                project: ["../../Sources/RevenueCat.h"]
            ),
            dependencies: [
                .purchasesCore
            ],
            settings: .settings(
                base: [
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION"
                ]
            )
        ),

        // MARK: – Receipt Parser
        .target(
            name: "ReceiptParser",
            destinations: .allPlatforms(macWithiPadDesign: false),
            product: .framework,
            bundleId: "com.revenuecat.ReceiptParser",
            deploymentTargets: .revenueCatInternal,
            infoPlist: .default,
            sources: [
                "../../Sources/LocalReceiptParsing/**/*.swift"
            ]
        )

    ],
    schemes: [
        .scheme(
            name: "RevenueCat",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCat"]),
            testAction: .testPlans([
                    .relativeToRoot("Tests/TestPlans/AllTests.xctestplan")
                ]
            ),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),

        .scheme(
            name: "ReceiptParser",
            shared: true,
            buildAction: .buildAction(targets: ["ReceiptParser"]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
