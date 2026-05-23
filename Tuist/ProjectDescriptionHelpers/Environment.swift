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

    /// Returns extra launch arguments to inject into scheme run actions, enabled by default.
    ///
    /// Example usage:
    /// ```bash
    /// # Single argument
    /// TUIST_LAUNCH_ARGUMENTS="-EnableWorkflowsEndpoint" tuist generate PaywallsTester
    ///
    /// # Multiple arguments
    /// TUIST_LAUNCH_ARGUMENTS="-EnableWorkflowsEndpoint -MyOtherFlag" tuist generate
    /// ```
    public static var extraLaunchArguments: [String] {
        let value = ProcessInfo.processInfo.environment["TUIST_LAUNCH_ARGUMENTS"] ?? ""
        return value.split(separator: " ").map(String.init).filter { !$0.isEmpty }
    }

    /// Returns extra Swift compilation conditions to inject into all targets.
    ///
    /// Example usage:
    /// ```bash
    /// # Single flag
    /// TUIST_SWIFT_CONDITIONS="ENABLE_WORKFLOWS_ENDPOINT" tuist generate PaywallsTester
    ///
    /// # Multiple flags
    /// TUIST_SWIFT_CONDITIONS="ENABLE_WORKFLOWS_ENDPOINT MY_OTHER_FLAG" tuist generate
    /// ```
    public static var extraSwiftConditions: [String] {
        let value = ProcessInfo.processInfo.environment["TUIST_SWIFT_CONDITIONS"] ?? ""
        return value.split(separator: " ").map(String.init).filter { !$0.isEmpty }
    }

    /// Returns the path to a local `purchases-core` checkout if the developer
    /// has configured one. Reads `PURCHASES_CORE_LOCAL_PATH` from the environment
    /// first, then falls back to parsing `Local.xcconfig` at the repo root.
    /// When set, Package.swift swaps the published dep for the local path and
    /// the RevenueCat target gets a pre-build script phase that rebuilds the
    /// xcframework whenever Rust sources change.
    ///
    /// Example usage (Local.xcconfig):
    /// ```
    /// PURCHASES_CORE_LOCAL_PATH = ../purchases-core
    /// ```
    public static var purchasesCoreLocalPath: String? {
        if let env = ProcessInfo.processInfo.environment["PURCHASES_CORE_LOCAL_PATH"],
           !env.isEmpty {
            return env
        }
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // ProjectDescriptionHelpers
            .deletingLastPathComponent() // Tuist
            .deletingLastPathComponent() // repo root
        let xcconfig = repoRoot.appendingPathComponent("Local.xcconfig")
        guard let contents = try? String(contentsOf: xcconfig, encoding: .utf8) else {
            return nil
        }
        for rawLine in contents.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("PURCHASES_CORE_LOCAL_PATH"),
                  let eqIdx = line.firstIndex(of: "=") else {
                continue
            }
            let value = line[line.index(after: eqIdx)...]
                .trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? nil : value
        }
        return nil
    }
}
