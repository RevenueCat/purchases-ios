import ProjectDescription
import ProjectDescriptionHelpers

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
    organizationName: "RevenueCat, Inc.",
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
            ]
        )
    ],
    schemes: [],
    additionalFiles: [
        "../../Tests/APITesters/AllAPITests/ObjcAPITester/**/*.h"
    ]
)
