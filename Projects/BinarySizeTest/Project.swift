import ProjectDescription
import ProjectDescriptionHelpers
import Foundation

/// Unlike other Tuist projects in this repo, BinarySizeTest manages its own dependency integration
/// independently of `Environment.dependencyMode`. Each case produces a separate binary uploaded to
/// Emerge for size tracking, so they each have a distinct bundle ID.
///
/// - `localSource`: Uses Xcode project target references (`.project(target:path:)`).
///   Requires `TUIST_RC_XCODE_PROJECT=true` so that `Workspace.swift` includes the
///   `Projects/RevenueCat` and `Projects/RevenueCatUI` projects.
/// - `spm`: Uses a local SPM package reference (`.package(path:)`).
///   Works with the default `localSwiftPackage` dependency mode.
/// - `cocoapods`: No Tuist-managed dependencies; uses CocoaPods via `pod install`.
///
/// Set via `TUIST_BINARY_SIZE_TEST_INTEGRATION_METHOD`
/// (`LOCAL_SOURCE` | `SPM` | `COCOAPODS`, defaults to `LOCAL_SOURCE`).
enum BinarySizeTestIntegrationMethod: String {
    case localSource = "LOCAL_SOURCE"
    case cocoapods = "COCOAPODS"
    case spm = "SPM"

    static let bundleIdPrefix = "com.revenuecat.binary-size-test."
    static let displayNamePrefix = "BinarySizeTest"

    var identifier: String {
        switch self {
        case .localSource:
            return "local-source"
        case .cocoapods:
            return "cocoapods"
        case .spm:
            return "spm"
        }
    }

    var name: String {
        switch self {
        case .localSource:
            return "Local Source"
        case .cocoapods:
            return "Cocoapods"
        case .spm:
            return "SPM"
        }
    }
}

extension BinarySizeTestIntegrationMethod {
    var bundleId: String {
        return Self.bundleIdPrefix + identifier
    }

    var displayName: String {
        return Self.displayNamePrefix + " (\(name))"
    }

    var dependencies: [TargetDependency] {
        switch self {
        case .localSource:
            return [
                .project(target: "RevenueCat", path: .relativeToRoot("Projects/RevenueCat")),
                .project(target: "RevenueCatUI", path: .relativeToRoot("Projects/RevenueCatUI"))
            ]
        case .spm:
            return [
                .package(product: "RevenueCat", type: .runtime),
                .package(product: "RevenueCatUI", type: .runtime)
            ]
        case .cocoapods:
            return []
        }
    }

    var packages: [ProjectDescription.Package] {
        switch self {
        case .localSource, .cocoapods:
            return []
        case .spm:
            return [.package(path: "../..")]
        }
    }

    var provisioningProfileSpecifier: String {
        return "match AppStore \(bundleId)"
    }

    var provisioningProfileSettingValue: SettingValue {
        return .init(stringLiteral: provisioningProfileSpecifier)
    }
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

let project = Project(
    name: "BinarySizeTest",
    organizationName: .revenueCatOrgName,
    packages: binarySizeTestIntegrationMethod.packages,
    settings: .settings(
        defaultSettings: .recommended
    ),
    targets: [
        .target(
            name: "BinarySizeTest",
            destinations: .iOS,
            product: .app,
            bundleId: binarySizeTestIntegrationMethod.bundleId,
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
            dependencies: binarySizeTestIntegrationMethod.dependencies,
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": .string("Manual"),
                    "DEVELOPMENT_TEAM": .string("8SXR2327BM"),
                    "CODE_SIGN_IDENTITY": .string("Apple Distribution: RevenueCat, Inc. (8SXR2327BM)"),
                    "INFOPLIST_KEY_CFBundleDisplayName": .string(binarySizeTestIntegrationMethod.displayName),
                    "PROVISIONING_PROFILE_SPECIFIER": binarySizeTestIntegrationMethod.provisioningProfileSettingValue
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
