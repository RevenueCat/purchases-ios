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
}
