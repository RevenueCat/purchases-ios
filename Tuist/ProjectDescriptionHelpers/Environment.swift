import Foundation
import ProjectDescription

public enum DependencyMode {
    /// The dependency is a local Swift Package Manager package.
    case localSwiftPackage

    /// The dependency is a local Xcode project. Tuist's default behavior.
    case localXcodeProject

    /// The dependency is a remote Swift Package Manager package.
    case remoteSwiftPackage

    /// The dependency is a remote Xcode project.
    case remoteXcodeProject
}

extension Environment {
    /// Returns the dependency mode for RevenueCat/RevenueCatUI.
    ///
    /// Example usage:
    /// ```bash
    /// # Generate project with local Swift Package dependency (default)
    /// tuist generate
    ///
    /// # Generate project with Xcode project dependency (instead of Swift Package)
    /// TUIST_RC_XCODE_PROJECT=true tuist generate
    ///
    /// # Generate project with remote dependency (instead of local dependency)
    /// TUIST_RC_REMOTE=true tuist generate
    /// ```
    public static var dependencyMode: DependencyMode {
        // Note: Environment variable names are prefixed with TUIST_ automatically, therefore:
        // rcRemote reads TUIST_RC_REMOTE
        // rcXcodeProject reads TUIST_RC_XCODE_PROJECT
        let remote = Environment.rcRemote.getBoolean(default: false)
        let xcodeProject = Environment.rcXcodeProject.getBoolean(default: false)
        if remote {
            return xcodeProject ? .remoteXcodeProject : .remoteSwiftPackage
        } else {
            return xcodeProject ? .localXcodeProject : .localSwiftPackage
        }
    }

    /// Returns whether to include external test/dev dependencies (Nimble, SnapshotTesting, OHHTTPStubs, GoogleMobileAds, etc.)
    /// and the projects that depend on them (RevenueCatTests, RevenueCatAdMob, AdMobIntegrationSample).
    /// Defaults to `true`. Set `TUIST_INCLUDE_TEST_DEPENDENCIES=false` to skip them and speed up `tuist install` on CI.
    public static var includeTestDependencies: Bool {
        let envValue = ProcessInfo.processInfo.environment["TUIST_INCLUDE_TEST_DEPENDENCIES"] ?? "true"
        return envValue.lowercased() != "false"
    }

    /// Returns whether to include the XCFrameworkInstallationTests project in the workspace.
    /// This is determined by the `TUIST_INCLUDE_XCFRAMEWORK_INSTALLATION_TESTS` environment variable, defaulting to `false` if not set.
    ///
    /// Example usage:
    /// ```bash
    /// # Generate workspace without XCFrameworkInstallationTests (default)
    /// tuist generate
    ///
    /// # Generate workspace with XCFrameworkInstallationTests
    /// TUIST_INCLUDE_XCFRAMEWORK_INSTALLATION_TESTS=true tuist generate
    /// ```
    public static var includeXCFrameworkInstallationTests: Bool {
        let envValue = ProcessInfo.processInfo.environment["TUIST_INCLUDE_XCFRAMEWORK_INSTALLATION_TESTS"] ?? "false"
        return envValue.lowercased() == "true"
    }

    /// Returns whether to include the XCFrameworkExport project in the workspace.
    /// This project is used for building xcframeworks with proper dynamic linking.
    /// Set `TUIST_INCLUDE_XCFRAMEWORK_EXPORT=true` to include it.
    public static var includeXCFrameworkExport: Bool {
        let envValue = ProcessInfo.processInfo.environment["TUIST_INCLUDE_XCFRAMEWORK_EXPORT"] ?? "false"
        return envValue.lowercased() == "true"
    }

    /// Returns the custom StoreKit configuration file path for PaywallsTester, if set.
    /// When set, the "PaywallsTester - SK Config" scheme will use this path instead of the default.
    ///
    /// Example usage:
    /// ```bash
    /// # Generate project with custom StoreKit config
    /// TUIST_SK_CONFIG_PATH=/path/to/MyProject.storekit tuist generate PaywallsTester
    /// ```
    public static var storekitConfigPath: String? {
        let value = Environment.skConfigPath.getString(default: "")
        return value.isEmpty ? nil : value
    }

    /// Returns the RevenueCat API key for PaywallsTester, if set.
    /// When set, this will be written to Local.xcconfig during project generation.
    ///
    /// Example usage:
    /// ```bash
    /// # Generate project with custom API key and StoreKit config
    /// TUIST_RC_API_KEY=appl_xxxxx TUIST_SK_CONFIG_PATH=/path/to/config.storekit tuist generate PaywallsTester
    /// ```
    public static var rcApiKey: String? {
        let value = ProcessInfo.processInfo.environment["TUIST_RC_API_KEY"] ?? ""
        return value.isEmpty ? nil : value
    }
}
