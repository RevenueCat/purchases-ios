import ProjectDescription
import ProjectDescriptionHelpers

// swiftlint:disable line_length

let allDestinations: Destinations = [
    .iPhone,
    .iPad,
    .mac,
    .macWithiPadDesign,
    .macCatalyst,
    .appleWatch,
    .appleTv,
    .appleVision,
    .appleVisionWithiPadDesign
]

let allDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "13.0",
    macOS: "10.15",
    watchOS: "1.0",
    tvOS: "13.0"
)

let project = Project(
    name: "APITesters",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .framework,
    targets: [
        .target(
            name: "ObjcAPITester",
            destinations: allDestinations,
            product: .framework,
            bundleId: "com.revenuecat.ObjcAPITester",
            deploymentTargets: allDeploymentTargets,
            sources: [
                "../../Tests/APITesters/AllAPITests/ObjcAPITester/**/*.m"
            ],
            headers: .headers(
                public: [
                    "../../Tests/APITesters/AllAPITests/ObjcAPITester/RCSubscriptionInfoAPI.h"
                ],
                project: [
                    "../../Tests/APITesters/AllAPITests/ObjcAPITester/ObjcAPITester.h"
                ]
            ),
            dependencies: [
                .revenueCat
            ].compactMap { $0 },
            metadata: .metadata(tags: ["APITester"])
        ),

        .target(
            name: "SwiftAPITester",
            destinations: allDestinations,
            product: .framework,
            bundleId: "com.revenuecat.SwiftAPITester",
            deploymentTargets: allDeploymentTargets,
            sources: [
                "../../Tests/APITesters/AllAPITests/SwiftAPITester/**/*.swift"
            ],
            headers: .headers(
                public: [
                    "../../Tests/APITesters/AllAPITests/SwiftAPITester/SwiftAPITester.h"
                ]
            ),
            dependencies: [
                .revenueCat
            ].compactMap { $0 },
            metadata: .metadata(tags: ["APITester"])
        ),

        .target(
            name: "ReceiptParserAPITester",
            destinations: allDestinations,
            product: .framework,
            bundleId: "com.revenuecat.ReceiptParserAPITester",
            deploymentTargets: allDeploymentTargets,
            sources: [
                "../../Tests/APITesters/AllAPITests/ReceiptParserAPITester/**/*.swift"
            ],
            headers: .headers(
                public: [
                    "../../Tests/APITesters/AllAPITests/ReceiptParserAPITester/ReceiptParserAPITester.h"
                ]
            ),
            dependencies: [
                .receiptparser
            ].compactMap { $0 },
            metadata: .metadata(tags: ["APITester"])
        ),

        .target(
            name: "RevenueCatUISwiftAPITester",
            destinations: allDestinations,
            product: .framework,
            bundleId: "com.revenuecat.RevenueCatUISwiftAPITester",
            deploymentTargets: .multiplatform(
                iOS: "15.0",
                macOS: "10.15",
                watchOS: "1.0",
                tvOS: "13.0"
            ),
            sources: [
                "../../Tests/APITesters/AllAPITests/RevenueCatUISwiftAPITester/**/*.swift"
            ],
            headers: .headers(
                public: [
                    "../../Tests/APITesters/AllAPITests/RevenueCatUISwiftAPITester/RevenueCatUISwiftAPITester.h"
                ]
            ),
            dependencies: [
                .revenueCatUI
            ].compactMap { $0 },
            metadata: .metadata(tags: ["APITester"])
        ),

        .target(
            name: "CustomEntitlementComputationSwiftAPITester",
            destinations: allDestinations,
            product: .framework,
            bundleId: "com.revenuecat.CustomEntitlementComputationSwiftAPITester",
            deploymentTargets: allDeploymentTargets,
            sources: [
                "../../Tests/APITesters/AllAPITests/CustomEntitlementComputationSwiftAPITester/**/*.swift"
            ],
            headers: .headers(
                public: [
                    "../../Tests/APITesters/AllAPITests/CustomEntitlementComputationSwiftAPITester/CustomEntitlementComputationSwiftAPITester.h"
                ]
            ),
            dependencies: [
                .revenueCatCustomEntitlementComputation
            ],
            metadata: .metadata(tags: ["APITester"])
        )
    ],
    schemes: [
        .scheme(
            name: "All API Tests",
            shared: true,
            buildAction: .buildAction(targets: [
                "ObjcAPITester",
                "SwiftAPITester",
                "ReceiptParserAPITester",
                "RevenueCatUISwiftAPITester",
                "CustomEntitlementComputationSwiftAPITester"
            ])
        )
    ],
    additionalFiles: [
        "../../Tests/APITesters/AllAPITests/ObjcAPITester/**/*.h",
        "../../Tests/APITesters/AllAPITests/SwiftAPITester/SwiftAPITester.h",
        "../../Tests/APITesters/AllAPITests/CustomEntitlementComputationSwiftAPITester/CustomEntitlementComputationSwiftAPITester.h",
        "../../Tests/APITesters/AllAPITests/RevenueCatUISwiftAPITester/RevenueCatUISwiftAPITester.h",
        "../../Tests/APITesters/AllAPITests/ReceiptParserAPITester/ReceiptParserAPITester.h"
    ]
)
