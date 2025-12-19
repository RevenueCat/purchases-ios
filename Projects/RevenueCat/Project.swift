import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Shared Constants

func allDestinations(macWithiPadDesign: Bool) -> Destinations {
    let destinations: [Destination?] = [
        .iPhone,
        .iPad,
        .mac,
        macWithiPadDesign ? .macWithiPadDesign : nil,
        .macCatalyst,
        .appleWatch,
        .appleTv,
        .appleVision,
        .appleVisionWithiPadDesign
    ]
    return Set(destinations.compactMap { $0 })
}

let allDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "13.0",
    macOS: "11.0",
    watchOS: "7.0",
    tvOS: "14.0",
    visionOS: "1.3"
)

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
            settings: .settings(
                base: [
                    "APPLICATION_EXTENSION_API_ONLY": "YES"
                ]
            )
        ),

        .target(
            name: "RevenueCat_CustomEntitlementComputation",
            destinations: allDestinations(macWithiPadDesign: true),
            product: .framework,
            bundleId: "com.revenuecat.RevenueCatCustomEntitlementComputation",
            deploymentTargets: allDeploymentTargets,
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
            destinations: allDestinations(macWithiPadDesign: false),
            product: .framework,
            bundleId: "com.revenuecat.ReceiptParser",
            deploymentTargets: allDeploymentTargets,
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
            testAction: .targets([
                .testableTarget(target: .init(stringLiteral: "ReceiptParserTests"))
            ]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
