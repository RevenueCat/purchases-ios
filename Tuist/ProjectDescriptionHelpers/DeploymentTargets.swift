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

    /// Deployment targets for internal targets (CustomEntitlementComputation, ReceiptParser, tests, etc.)
    /// These have higher minimum versions than the public-facing SDK targets.
    public static var revenueCatInternal: DeploymentTargets {
        .multiplatform(
            iOS: "13.0",
            macOS: "11.0",
            watchOS: "7.0",
            tvOS: "14.0",
            visionOS: "1.3"
        )
    }
}
