import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Project Definition

let project = Project(
    name: "RevenueCatTests",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages + .adMobPackage,
    settings: .framework,
    targets: [

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
                .revenueCat,
                .nimble,
                .snapshotTesting,
                .ohHTTPStubsSwift
            ],
            metadata: .metadata(tags: ["RevenueCatTests"])
        ),

        .target(
            name: "ReceiptParserTests",
            destinations: .allPlatforms(macWithiPadDesign: false),
            product: .unitTests,
            bundleId: "com.revenuecat.ReceiptParserTests",
            deploymentTargets: .revenueCatInternal,
            infoPlist: .default,
            sources: [
                "../../Tests/ReceiptParserTests/**/*.swift"
            ],
            resources: [
                "../../Tests/UnitTests/Resources/receipts/**/*.txt"
            ],
            dependencies: [
                .receiptParser,
                .nimble
            ]
        ),

        // MARK: – Unit Tests Host App
        .target(
            name: "UnitTestsHostApp",
            destinations: .allPlatforms(macWithiPadDesign: true),
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
            metadata: .metadata(tags: ["RevenueCatTests"])
        ),

        // MARK: – StoreKit Unit Tests
        .target(
            name: "StoreKitUnitTests",
            destinations: .allPlatforms(macWithiPadDesign: true),
            product: .unitTests,
            bundleId: "com.revenuecat.StoreKitUnitTests",
            deploymentTargets: .revenueCatInternal,
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
                .revenueCat,
                .target(name: "UnitTestsHostApp"),
                .nimble,
                .ohHTTPStubsSwift,
                .snapshotTesting
            ],
            additionalFiles: [
                "../../Tests/StoreKitUnitTests/UnitTestsConfiguration.storekit"
            ],
            metadata: .metadata(tags: ["RevenueCatTests"]),
        ),

        // MARK: – BackendIntegrationTests Host App
        .target(
            name: "BackendIntegrationTestsHostApp",
            destinations: .allPlatforms(macWithiPadDesign: true),
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
            ),
            metadata: .metadata(tags: ["RevenueCatTests"]),
        ),

        .target(
            name: "BackendCustomEntitlementsIntegrationTests",
            destinations: .allPlatforms(macWithiPadDesign: true),
            product: .unitTests,
            bundleId: "com.revenuecat.BackendCustomEntitlementsIntegrationTests",
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
                .revenueCatCustomEntitlementComputation,
                .target(name: "BackendIntegrationTestsHostApp"),
                .nimble,
                .snapshotTesting,
                .storeKitTests
            ],
            settings: .settings(
                base: [
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION"
                ]
            ),
            metadata: .metadata(tags: ["RevenueCatTests"]),
        ),

        .target(
            name: "BackendIntegrationTests",
            destinations: .allPlatforms(macWithiPadDesign: true),
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
                .revenueCat,
                .target(name: "BackendIntegrationTestsHostApp"),
                .nimble,
                .ohHTTPStubsSwift,
                .snapshotTesting,
                .storeKitTests
            ],
            additionalFiles: [
                "../../Tests/BackendIntegrationTests/RevenueCat_IntegrationPurchaseTesterConfiguration.storekit",
                "../../BackendIntegrationTests/**.xctestplan"
            ],
            metadata: .metadata(tags: ["RevenueCatTests"])
        ),

        // MARK: – RevenueCatAdMobTests
        .target(
            name: "RevenueCatAdMobTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.revenuecat.RevenueCatAdMobTests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: [
                "../../AdapterSDKs/RevenueCatAdMob/Tests/RevenueCatAdMobTests/**/*.swift"
            ],
            dependencies: [
                .revenueCat,
                .revenueCatAdMob,
                .googleMobileAds
            ],
            metadata: .metadata(tags: ["RevenueCatTests"])
        ),

        // MARK: – RevenueCatUITests
        .target(
            name: "RevenueCatUITests",
            destinations: .allRevenueCat,
            product: .unitTests,
            bundleId: "com.revenuecat.sampleapp.tests",
            deploymentTargets: .allRevenueCat,
            infoPlist: .default,
            sources: [
                "../../Tests/RevenueCatUITests/**/*.swift"
            ],
            dependencies: [
                .revenueCatUI,
                .nimble,
                .snapshotTesting,
                .ohHTTPStubsSwift
            ],
            metadata: .metadata(tags: ["RevenueCatTests"])
        )

    ],
    schemes: [

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
            name: "ReceiptParserTests",
            shared: true,
            buildAction: .buildAction(targets: ["ReceiptParserTests"]),
            testAction: .targets([
                .testableTarget(target: .init(stringLiteral: "ReceiptParserTests"))
            ]),
            runAction: .runAction(configuration: "Debug")
        ),

        .scheme(
            name: "RevenueCatAdMobTests",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCatAdMobTests"]),
            testAction: .targets([
                .testableTarget(target: .init(stringLiteral: "RevenueCatAdMobTests"))
            ]),
            runAction: .runAction(configuration: "Debug")
        ),

        .scheme(
            name: "RevenueCatUITests",
            shared: true,
            buildAction: .buildAction(targets: ["RevenueCatUITests"]),
            testAction: .targets([
                .testableTarget(target: .init(stringLiteral: "RevenueCatUITests"))
            ]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
