import ProjectDescription
import ProjectDescriptionHelpers

/// The SDK update tests build this app twice: once against the latest released SDK and once against
/// the local SDK sources. Both builds share the bundle ID so that installing the second one over the first
/// one behaves like an app update, preserving the app's persisted data.
///
/// Set `TUIST_SDK_UPDATE_TESTER_RELEASE_VERSION` (e.g. `5.92.0`) to depend on that released version.
/// Leave it unset to depend on the local SDK sources.
///
/// Each variant generates a differently named Xcode project, so both can coexist and be built in parallel.
enum SDKUpdateTesterVariant {
    case local
    case release(version: Version)

    var projectName: String {
        switch self {
        case .local:
            return "SDKUpdateTester-Local"
        case .release:
            return "SDKUpdateTester-Release"
        }
    }

    var package: ProjectDescription.Package {
        switch self {
        case .local:
            return .package(path: .relativeToRoot("."))
        case let .release(version):
            return .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", .exact(version))
        }
    }
}

let variant: SDKUpdateTesterVariant = {
    let releaseVersion = Environment.sdkUpdateTesterReleaseVersion.getString(default: "")
    guard !releaseVersion.isEmpty else {
        return .local
    }
    guard let version = Version(string: releaseVersion) else {
        preconditionFailure("Invalid TUIST_SDK_UPDATE_TESTER_RELEASE_VERSION '\(releaseVersion)'.")
    }
    return .release(version: version)
}()

let project = Project(
    name: variant.projectName,
    organizationName: .revenueCatOrgName,
    packages: [variant.package],
    settings: .appProject,
    targets: [
        .target(
            name: "SDKUpdateTester",
            destinations: .iOS,
            product: .app,
            bundleId: "com.revenuecat.SDKUpdateTester",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": ""
                    ],
                    "REVENUECAT_API_KEY": "$(REVENUECAT_API_KEY)"
                ]
            ),
            sources: ["Sources/**/*.swift"],
            dependencies: [
                .package(product: "RevenueCat", type: .runtime)
            ],
            settings: .appTarget
        )
    ],
    schemes: [
        .scheme(
            name: "SDKUpdateTester",
            shared: true,
            buildAction: .buildAction(targets: ["SDKUpdateTester"]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
