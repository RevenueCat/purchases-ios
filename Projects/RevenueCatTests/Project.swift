import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Project Definition

private let revenueCatTestsTestPlans: [Path] = [
    .relativeToRoot("Tests/TestPlans/CI-AllTests.xctestplan"),
    .relativeToRoot("Tests/TestPlans/CI-RevenueCat.xctestplan"),
    .relativeToRoot("Tests/TestPlans/CI-RevenueCat-Snapshots.xctestplan"),
    .relativeToRoot("Tests/TestPlans/CI-Snapshots.xctestplan")
]

private let revenueCatTestsLocalePreAction = ExecutionAction.executionAction(
    title: "Set Simulator Locale",
    scriptText: """
    sh "$SRCROOT/../../scripts/revenuecat-tests-simulator-locale.sh" set
    """,
    target: "UnitTests"
)

private let revenueCatTestsLocalePostAction = ExecutionAction.executionAction(
    title: "Restore Simulator Locale",
    scriptText: """
    sh "$SRCROOT/../../scripts/revenuecat-tests-simulator-locale.sh" restore
    """,
    target: "UnitTests"
)

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
            resources: [
                .folderReference(path: "../../Tests/UnitTests/Networking/Responses/Fixtures"),
                "../../Tests/UnitTests/Resources/receipts/base64encoded_sandboxReceipt.txt",
                "../../Tests/UnitTests/Resources/receipts/base64encodedreceiptsample1.txt",
                "../../Tests/UnitTests/Resources/receipts/base64EncodedReceiptSampleForDataExtension.txt",
                "../../Tests/UnitTests/Resources/receipts/verifyReceiptSample1.txt",
                "../../Tests/UnitTests/Paywalls/Components/JSON/ImageComponent.json",
                "../../Tests/UnitTests/Paywalls/Components/JSON/VideoComponent.json",
                // swiftlint:disable:next line_length
                "../../Tests/UnitTests/Ads/Events/__Snapshots__/AdEventsRequestTests/testCanInitFromDeserializedEvent.1.json",
                "../../Tests/UnitTests/Ads/Events/__Snapshots__/AdEventsRequestTests/testDisplayedEvent.1.json",
                "../../Tests/UnitTests/Ads/Events/__Snapshots__/AdEventsRequestTests/testOpenedEvent.1.json",
                "../../Tests/UnitTests/Ads/Events/__Snapshots__/AdEventsRequestTests/testRevenueEvent.1.json",
                // swiftlint:disable:next line_length
                "../../Tests/UnitTests/Networking/Requests/__Snapshots__/DiagnosticsEventEncodingTests/testEncoding.1.json"
            ],
            dependencies: [
                .revenueCat,
                .nimble,
                .snapshotTesting,
                .ohHTTPStubsSwift
            ]
        )
        .tagged(["RevenueCatTests"]),

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
                macOS: "11.0",
                watchOS: "7.0",
                tvOS: "14.0",
                visionOS: "1.0"
            ),
            infoPlist: .file(path: "../../Tests/UnitTestsHostApp/Info.plist"),
            sources: [
                "../../Tests/UnitTestsHostApp/**/*.swift"
            ],
            dependencies: []
        )
        .tagged(["RevenueCatTests"]),

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
            ]
        )
        .tagged(["RevenueCatTests"]),

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
            ]
        )
        .tagged(["RevenueCatTests"]),

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
                // Only the helpers that are CustomEntitlementComputation-aware (conditional import).
                // The excluded helpers import `RevenueCat` directly and aren't used by these tests,
                // so compiling them here would link against the wrong module.
                .glob(
                    "../../Tests/BackendIntegrationTests/Helpers/**/*.swift",
                    excluding: [
                        "../../Tests/BackendIntegrationTests/Helpers/SK1ProductFetcher.swift",
                        "../../Tests/BackendIntegrationTests/Helpers/SK2ProductFetcher.swift",
                        "../../Tests/BackendIntegrationTests/Helpers/ObserverModeManager.swift",
                        "../../Tests/BackendIntegrationTests/Helpers/ExternalPurchasesManager.swift"
                    ]
                ),
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
            resources: [
                "../../Tests/BackendIntegrationTests/RevenueCat_IntegrationPurchaseTesterConfiguration.storekit"
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
            )
        )
        .tagged(["RevenueCatTests"]),

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
            ]
        )
        .tagged(["RevenueCatTests"]),

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
                .googleMobileAds,
                .nimble
            ]
        )
        .tagged(["RevenueCatTests"]),

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
            ]
        )
        .tagged(["RevenueCatTests"])

    ],
    schemes: [

        .scheme(
            name: "RevenueCatTests",
            shared: true,
            buildAction: .buildAction(targets: ["UnitTests"]),
            testAction: .testPlans(
                revenueCatTestsTestPlans,
                preActions: [revenueCatTestsLocalePreAction],
                postActions: [revenueCatTestsLocalePostAction]
            ),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),

        .scheme(
            name: "BackendIntegrationTests",
            shared: true,
            buildAction: .buildAction(targets: ["BackendIntegrationTests"]),
            testAction: .testPlans([
                    .relativeToRoot("BackendIntegrationTests/BackendIntegrationTests-All-CI.xctestplan"),
                    .relativeToRoot("BackendIntegrationTests/BackendIntegrationTests-All.xctestplan"),
                    .relativeToRoot("BackendIntegrationTests/BackendIntegrationTests-SK1.xctestplan"),
                    .relativeToRoot("BackendIntegrationTests/BackendIntegrationTests-SK2.xctestplan"),
                    .relativeToRoot("BackendIntegrationTests/BackendIntegrationTests-Offline.xctestplan"),
                    .relativeToRoot("BackendIntegrationTests/BackendIntegrationTests-Other.xctestplan"),
                    .relativeToRoot("BackendIntegrationTests/BackendIntegrationTests-CustomEntitlements.xctestplan"),
                    .relativeToRoot("BackendIntegrationTests/BackendIntegrationTests-LoadShedder.xctestplan")
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
