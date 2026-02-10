import ProjectDescription
import ProjectDescriptionHelpers

let allDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "13.0",
    macOS: "10.15",
    watchOS: "6.2",
    tvOS: "13.0",
    visionOS: "1.0"
)

let project = Project(
    name: "RevenueCatUI",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .framework,
    targets: [
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
            dependencies: [
                .revenueCat
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "RevenueCatUI",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCatUI"]),
            testAction: .targets([
                .testableTarget(target: .init(stringLiteral: "RevenueCatUITests"))
            ]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
