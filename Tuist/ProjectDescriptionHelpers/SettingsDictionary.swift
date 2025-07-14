import ProjectDescription

extension SettingsDictionary {

    /// Base project settings dictionary for RevenueCat projects.
    /// 
    /// This provides a standardized base configuration that includes:
    /// - Whole module compilation mode for optimal performance
    /// - Asset catalog Swift symbol extensions generation
    /// - Automatic code signing with RevenueCat team ID
    public static var projectBase: SettingsDictionary {
        return [
            "SWIFT_COMPILATION_MODE": "wholemodule",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
        ].automaticCodeSigning(devTeam: .revenueCatTeamID)
    }
}
