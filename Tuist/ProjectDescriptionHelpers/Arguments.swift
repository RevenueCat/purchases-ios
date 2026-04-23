import ProjectDescription

extension Arguments {

    /// Returns an `Arguments` value that merges `base` with any launch arguments
    /// from the `TUIST_LAUNCH_ARGUMENTS` environment variable (enabled by default).
    ///
    /// Example usage:
    /// ```bash
    /// TUIST_LAUNCH_ARGUMENTS="-EnableWorkflowsEndpoint" tuist generate PaywallsTester
    /// ```
    public static func appendingTuistLaunchArguments(
        base: Arguments = .arguments()
    ) -> Arguments {
        let extra = Environment.extraLaunchArguments.map {
            LaunchArgument.launchArgument(name: $0, isEnabled: true)
        }
        guard !extra.isEmpty else { return base }
        return .arguments(
            environmentVariables: base.environmentVariables,
            launchArguments: base.launchArguments + extra
        )
    }

}
