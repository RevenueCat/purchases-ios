import Foundation
import ProjectDescription

extension Environment {
    /// Returns whether the current environment is local.
    /// This is determined by the `rcLocal` environment variable, defaulting to `true` if not set.
    ///
    /// Example usage:
    /// ```bash
    /// # Generate project with local environment (default)
    /// tuist generate
    ///
    /// # Generate project with non-local environment
    /// TUIST_RC_LOCAL=false tuist generate
    /// ```
    public static var local: Bool {
        Environment.rcLocal.getBoolean(default: true)
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

    /// Returns the custom StoreKit configuration file path for PaywallsTester, if set.
    /// When set, a "PaywallsTester - Custom" scheme will be generated using this path.
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
}
