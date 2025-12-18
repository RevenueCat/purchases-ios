import ProjectDescription
import ProjectDescriptionHelpers
import Foundation

enum BinarySizeTestIntegrationMethod: String {
    case localSource = "LOCAL_SOURCE"
    case cocoapods = "COCOAPODS"
    case spm = "SPM"
}

let binarySizeTestIntegrationMethod: BinarySizeTestIntegrationMethod = {
    let raw = Environment.binarySizeTestIntegrationMethod.getString(default: BinarySizeTestIntegrationMethod.localSource.rawValue)
    let value = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

    switch value {
    case "LOCAL_SOURCE":
        return .localSource
    case "COCOAPODS":
        return .cocoapods
    case "SPM":
        return .spm
    default:
        preconditionFailure(
            "Invalid TUIST_BINARY_SIZE_TEST_INTEGRATION_METHOD '\(raw)'. " +
            "Expected one of: \(BinarySizeTestIntegrationMethod.localSource.rawValue), " +
            "\(BinarySizeTestIntegrationMethod.cocoapods.rawValue), " +
            "\(BinarySizeTestIntegrationMethod.spm.rawValue)."
        )
    }
}()

let binarySizeTestBundleId: String = {
    switch binarySizeTestIntegrationMethod {
    case .localSource:
        return "com.revenuecat.binary-size-test.local-source"
    case .cocoapods:
        return "com.revenuecat.binary-size-test.cocoapods"
    case .spm:
        return "com.revenuecat.binary-size-test.spm"
    }
}()

let binarySizeTestDisplayName: String = {
    switch binarySizeTestIntegrationMethod {
    case .localSource:
        return "BinarySizeTest (Local Source)"
    case .cocoapods:
        return "BinarySizeTest (Cocoapods)"
    case .spm:
        return "BinarySizeTest (SPM)"
    }
}()

let binarySizeTestProvisioningProfileSpecifier = "match AppStore \(binarySizeTestBundleId)"
let binarySizeTestProvisioningProfileSettingValue: SettingValue = .init(
    stringLiteral: binarySizeTestProvisioningProfileSpecifier
)

let binarySizeTestDependencies: [TargetDependency] = {
    switch binarySizeTestIntegrationMethod {
    case .localSource:
        // Explicit local project dependencies (no reliance on other env vars).
        return [
            .project(target: "RevenueCat", path: .relativeToRoot("Projects/RevenueCat")),
            .project(target: "RevenueCatUI", path: .relativeToRoot("Projects/RevenueCatUI"))
        ]
    case .spm:
        // SDK provided via Tuist-managed SPM external dependencies.
        return [
            .revenueCatLocal,
            .revenueCatUILocal
        ]
    case .cocoapods:
        // SDK will be provided by CocoaPods (see Podfile in this directory).
        return []
    }
}()

let project = Project(
    name: "BinarySizeTest",
    organizationName: .revenueCatOrgName,
    settings: .settings(
        defaultSettings: .recommended
    ),
    targets: [
        .target(
            name: "BinarySizeTest",
            destinations: .iOS,
            product: .app,
            bundleId: binarySizeTestBundleId,
            deploymentTargets: .iOS("13.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ]
                ]
            ),
            sources: [
                "BinarySizeTest/Sources/**/*.swift"
            ],
            dependencies: binarySizeTestDependencies,
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": .string("Manual"),
                    "DEVELOPMENT_TEAM": .string("8SXR2327BM"),
                    "CODE_SIGN_IDENTITY": .string("Apple Distribution: RevenueCat, Inc. (8SXR2327BM)"),
                    "INFOPLIST_KEY_CFBundleDisplayName": .string(binarySizeTestDisplayName),
                    "PROVISIONING_PROFILE_SPECIFIER": binarySizeTestProvisioningProfileSettingValue
                ],
                defaultSettings: .essential
            )
        )
    ],
    schemes: [
        .scheme(
            name: "BinarySizeTest",
            shared: true,
            buildAction: .buildAction(targets: ["BinarySizeTest"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release")
        )
    ]
)
