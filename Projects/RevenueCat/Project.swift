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
    tvOS: "14.0"
)

// MARK: - Project Definition

let project = Project(
    name: "RevenueCat",
    organizationName: .revenueCatOrgName,
    settings: .settings(
        base: [:].automaticCodeSigning(devTeam: .revenueCatTeamID),
        configurations: .xcconfigFileConfigurations,
        defaultSettings: .recommended
    ),
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
            name: "UnitTests",
            destinations: .allRevenueCat,
            product: .unitTests,
            bundleId: "com.revenuecat.PurchasesTests",
            deploymentTargets: .allRevenueCat,
            infoPlist: .default,
            sources: [
                "../../Tests/UnitTests/**/*.swift",
                "../../Tests/ReceiptParserTests/Helpers/MockBundle.swift",
                "../../Tests/StoreKitUnitTests/TestHelpers/AvailabilityChecks.swift",
                "../../Tests/StoreKitUnitTests/TestHelpers/StoreKitTestHelpers.swift",
                "../../Tests/StoreKitUnitTests/TestHelpers/ImageSnapshot.swift"
            ],
            dependencies: [
                .target(name: "RevenueCat"),
                .nimble,
                .snapshotTesting,
                .ohHTTPStubsSwift
            ],
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
        ),

        .target(
            name: "ReceiptParserTests",
            destinations: allDestinations(macWithiPadDesign: false),
            product: .unitTests,
            bundleId: "com.revenuecat.ReceiptParserTests",
            deploymentTargets: allDeploymentTargets,
            infoPlist: .default,
            sources: [
                "../../Tests/ReceiptParserTests/**/*.swift"
            ],
            resources: [
                "../../Tests/UnitTests/Resources/receipts/**/*.txt"
            ],
            dependencies: [
                .target(name: "ReceiptParser"),
                .nimble
            ]
        ),

        // MARK: – Unit Tests Host App
        .target(
            name: "UnitTestsHostApp",
            destinations: allDestinations(macWithiPadDesign: true),
            product: .app,
            bundleId: "com.revenuecat.StoreKitUnitTestsHostApp",
            deploymentTargets: .multiplatform(
                iOS: "13.0",
                macOS: "10.15",
                watchOS: "6.2",
                tvOS: "13.0",
                visionOS: "1.0"
            ),
            infoPlist: .file(path: "../../Tests/UnitTestsHostApp/Info.plist"),
            sources: [
                "../../Tests/UnitTestsHostApp/**/*.swift"
            ],
            dependencies: [],
        ),

        // MARK: – StoreKit Unit Tests
        .target(
            name: "StoreKitUnitTests",
            destinations: allDestinations(macWithiPadDesign: true),
            product: .unitTests,
            bundleId: "com.revenuecat.StoreKitUnitTests",
            deploymentTargets: allDeploymentTargets,
            infoPlist: .default,
            sources: [
                "../../Tests/StoreKitUnitTests/**/*.swift",
                "../../Tests/UnitTests/TestHelpers/**/*.swift",
                "../../Tests/UnitTests/Misc/**/TestCase.swift",
                "../../Tests/UnitTests/Misc/**/CustomerInfo+TestExtensions.swift",
                "../../Tests/UnitTests/Misc/**/XCTestCase+Extensions.swift",
                "../../Tests/UnitTests/Mocks/**/*.swift"
            ],
            resources: [
                "../../Tests/StoreKitUnitTests/UnitTestsConfiguration.storekit"
            ],
            dependencies: [
                .target(name: "RevenueCat"),
                .target(name: "UnitTestsHostApp"),
                .nimble,
                .ohHTTPStubsSwift,
                .snapshotTesting
            ],
            additionalFiles: [
                "../../Tests/StoreKitUnitTests/UnitTestsConfiguration.storekit"
            ]
        ),

        // MARK: – BackendIntegrationTests Host App
        .target(
            name: "BackendIntegrationTestsHostApp",
            destinations: allDestinations(macWithiPadDesign: true),
            product: .app,
            bundleId: "com.revenuecat.StoreKitTestApp",
            deploymentTargets: .multiplatform(
                iOS: "14.1",
                macOS: "10.15",
                tvOS: "14.1"
            ),
            infoPlist: .file(path: "../../Tests/UnitTestsHostApp/Info.plist"),
            sources: [
                "../../Tests/BackendIntegrationTestApp/**/*.swift"
            ],
            dependencies: [
             .storeKit
            ],
            settings: .settings(
                base: [
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION"
                ]
            )
        ),

        .target(
            name: "BackendCustomEntitlementsIntegrationTests",
            destinations: allDestinations(macWithiPadDesign: true),
            product: .unitTests,
            bundleId: "com.revenuecat.BackendIntBackendCustomEntitlementsIntegrationTestsegrationTests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "../../Tests/BackendIntegrationTests/CustomEntitlementsComputationIntegrationTests.swift",
                "../../Tests/BackendIntegrationTests/BaseBackendIntegrationTests.swift",
                "../../Tests/BackendIntegrationTests/BaseStoreKitIntegrationTests.swift",
                "../../Tests/BackendIntegrationTests/MainThreadMonitor.swift",
                "../../Tests/BackendIntegrationTests/Constants.swift",
                "../../Tests/BackendIntegrationTests/Helpers/**/*.swift",
                "../../Tests/UnitTests/Misc/**/TestCase.swift",
                "../../Tests/UnitTests/Mocks/MockSandboxEnvironmentDetector.swift",
                "../../Tests/UnitTests/TestHelpers/**/TestLogHandler.swift",
                "../../Tests/UnitTests/TestHelpers/**/CurrentTestCaseTracker.swift",
                "../../Tests/UnitTests/TestHelpers/**/AsyncTestHelpers.swift",
                "../../Tests/UnitTests/TestHelpers/**/OSVersionEquivalent.swift",
                "../../Tests/UnitTests/Misc/XCTestCase+Extensions.swift",
                "../../Tests/StoreKitUnitTests/TestHelpers/StoreKitTestHelpers.swift",
                "../../Tests/StoreKitUnitTests/TestHelpers/AvailabilityChecks.swift"
            ],
            dependencies: [
                .target(name: "RevenueCat_CustomEntitlementComputation"),
                .target(name: "BackendIntegrationTestsHostApp"),
                .nimble,
                .snapshotTesting,
                .storeKitTests
            ],
            settings: .settings(
                base: [
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION"
                ]
            )
        ),

        .target(
            name: "BackendIntegrationTests",
            destinations: allDestinations(macWithiPadDesign: true),
            product: .unitTests,
            bundleId: "com.revenuecat.BackendIntegrationTests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                .glob(
                    "../../Tests/BackendIntegrationTests/**/*.swift",
                    excluding: [
                        "../../Tests/BackendIntegrationTests/CustomEntitlementsComputationIntegrationTests.swift"
                    ]
                ),
                "../../Tests/UnitTests/Mocks/MockSandboxEnvironmentDetector.swift",
                "../../Tests/UnitTests/Misc/**/TestCase.swift",
                "../../Tests/UnitTests/Misc/**/XCTestCase+Extensions.swift",
                "../../Tests/UnitTests/TestHelpers/**/*.swift",
                .glob(
                    "../../Tests/StoreKitUnitTests/TestHelpers/**/*.swift",
                    excluding: [
                        "../../Tests/StoreKitUnitTests/TestHelpers/StoreKitConfigTestCase+Extensions.swift"
                    ]
                )
            ],
            resources: [
                "../../Tests/BackendIntegrationTests/RevenueCat_IntegrationPurchaseTesterConfiguration.storekit"
            ],
            dependencies: [
                .target(name: "RevenueCat"),
                .target(name: "BackendIntegrationTestsHostApp"),
                .nimble,
                .ohHTTPStubsSwift,
                .snapshotTesting,
                .storeKitTests
            ],
            additionalFiles: [
                "../../Tests/BackendIntegrationTests/RevenueCat_IntegrationPurchaseTesterConfiguration.storekit",
                "../../BackendIntegrationTests/**.xctestplan"
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
            name: "BackendIntegrationTests",
            shared: true,
            buildAction: .buildAction(targets: ["BackendIntegrationTests"]),
            testAction: .testPlans([
                    .relativeToRoot("BackendIntegrationTests/BackendIntegrationTests-All-CI.xctestplan")
                ]
            ),
            runAction: .runAction(
                executable: "BackendIntegrationTestsHostApp",
                options: .options(
                    storeKitConfigurationPath: .relativeToRoot(
                        "Tests/BackendIntegrationTests/RevenueCat_IntegrationPurchaseTesterConfiguration.storekit"
                    )
                )
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
