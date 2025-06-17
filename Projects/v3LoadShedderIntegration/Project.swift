import ProjectDescription
import ProjectDescriptionHelpers

// swiftlint:disable line_length

// MARK: - Shared Constants

let allDestinations: Destinations = [
    .iPhone,
    .iPad
]

let allDeploymentTargets: DeploymentTargets = .multiplatform(
    iOS: "14.0",
)

let storeKitFile = "../../Tests/v3LoadShedderIntegration/v3LoadShedderIntegrationTests/V3LoadShedderIntegrationTestsConfiguration.storekit"

// MARK: - Project Definition

let project = Project(
    name: "v3LoadShedderIntegration",
    organizationName: "RevenueCat, Inc.",
    targets: [
        // MARK: – Main Library
        .target(
            name: "v3LoadShedderIntegration",
            destinations: allDestinations,
            product: .app,
            bundleId: "com.revenuecat.v3LoadShedderIntegration",
            deploymentTargets: allDeploymentTargets,
            infoPlist: .file(path: "../../Tests/v3LoadShedderIntegration/v3LoadShedderIntegration/Info.plist"),
            sources: [
                .glob(
                    "../../Tests/v3LoadShedderIntegration/v3LoadShedderIntegration/**/*.swift"
                )
            ],
            resources: [
                "../../Tests/v3LoadShedderIntegration/v3LoadShedderIntegration/Assets.xcassets",
                "../../Tests/v3LoadShedderIntegration/v3LoadShedderIntegration/Base.lproj/LaunchScreen.storyboard",
                "../../Tests/v3LoadShedderIntegration/v3LoadShedderIntegration/Base.lproj/Main.storyboard",
                storeKitFile
            ],
            headers: .headers(
                project: ["../../Tests/v3LoadShedderIntegration/v3LoadShedderIntegration/v3LoadShedderIntegrationTests-Info.h"]
            ),
            additionalFiles: [
                storeKitFile,
                "../../Tests/v3LoadShedderIntegration/v3LoadShedderIntegration/Info.plist"
            ]
        ),

        .target(
            name: "v3LoadShedderIntegrationTests",
            destinations: allDestinations,
            product: .unitTests,
            bundleId: "com.revenuecat.v3LoadShedderIntegrationTests",
            deploymentTargets: allDeploymentTargets,
            infoPlist: .default,
            sources: [
                "../../Tests/v3LoadShedderIntegration/v3LoadShedderIntegrationTests/**/*.swift"
            ],
            dependencies: [
                .target(name: "v3LoadShedderIntegration"),
                .external(name: "Purchases")
            ],
            additionalFiles: [
                storeKitFile
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "v3LoadShedderIntegrationTests",
            shared: true,
            buildAction: .buildAction(targets: ["v3LoadShedderIntegrationTests"]),
            testAction: .targets(["v3LoadShedderIntegrationTests"]),
            runAction: .runAction(
                executable: "v3LoadShedderIntegration",
                options: .options(
                    storeKitConfigurationPath: storeKitFile
                )
            ),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
