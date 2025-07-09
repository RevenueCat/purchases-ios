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
}
