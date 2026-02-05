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
    
    /// Returns whether to include the XCFrameworkTester project in the workspace.
    /// This is determined by the `TUIST_INCLUDE_XCFRAMEWORK_TESTER` environment variable, defaulting to `false` if not set.
    /// 
    /// Example usage:
    /// ```bash
    /// # Generate workspace without XCFrameworkTester (default)
    /// tuist generate
    /// 
    /// # Generate workspace with XCFrameworkTester
    /// TUIST_INCLUDE_XCFRAMEWORK_TESTER=true tuist generate
    /// ```
    public static var includeXCFrameworkTester: Bool {
        let envValue = ProcessInfo.processInfo.environment["TUIST_INCLUDE_XCFRAMEWORK_TESTER"] ?? "false"
        return envValue.lowercased() == "true"
    }
}
