import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "PaywallScreenshotTests",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .framework,
    targets: [
        .target(
            name: "PaywallScreenshotTests",
            destinations: [.iPhone, .iPad, .macCatalyst, .macWithiPadDesign],
            product: .unitTests,
            bundleId: "com.revenuecat.PaywallScreenshotTests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: [
                "../../Tests/RevenueCatUITests/PaywallsV2/TakeScreenshot.swift",
                "../../Tests/RevenueCatUITests/PaywallsV2/PaywallPreviewResourcesLoader.swift",
                "../../Tests/RevenueCatUITests/BaseSnapshotTest.swift",
                "../../Tests/RevenueCatUITests/Helpers/TestCase.swift",
                "../../Tests/StoreKitUnitTests/TestHelpers/ImageSnapshot.swift",
                "../../Tests/RevenueCatUITests/Helpers/AsyncTestHelpers.swift",
                "../../Tests/RevenueCatUITests/Helpers/CurrentTestCaseTracker.swift",
                "../../Tests/RevenueCatUITests/Helpers/OSVersionEquivalent.swift",
                "../../Tests/RevenueCatUITests/Helpers/SnapshotTesting+Extensions.swift",
                "../../Tests/RevenueCatUITests/Helpers/TestLogHandler.swift"
            ],
            resources: [
                .folderReference(path: "../../Tests/paywall-preview-resources"),
                "../../Tests/RevenueCatUITests/Resources/header.heic",
                "../../Tests/RevenueCatUITests/Resources/background.heic"
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .nimble,
                .snapshotTesting,
                .project(
                    target: "UnitTestsHostApp",
                    path: .relativeToRoot("Projects/RevenueCatTests")
                )
            ],
            settings: .settings(base: ["MACOSX_DEPLOYMENT_TARGET": "12.0"])
        )
    ],
    schemes: [
        .scheme(
            name: "PaywallScreenshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["PaywallScreenshotTests"]),
            testAction: .testPlans([
                .relativeToRoot("Tests/RevenueCatUITests/TestPlans/Paywall-Screenshots.xctestplan")
            ]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
