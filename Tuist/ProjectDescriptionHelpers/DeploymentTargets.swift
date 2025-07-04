import ProjectDescription

extension DeploymentTargets {

    /// Deployment targets for all RevenueCat targets  (RevenueCat, RevenueCatUI)
    public static var allRevenueCat: DeploymentTargets {
        .multiplatform(
            iOS: "13.0",
            macOS: "10.15",
            watchOS: "6.2",
            tvOS: "13.0",
            visionOS: "1.0"
        )
    }
}
