import Foundation

/// Constants for the LevelPlay manual integration sample app.
enum Constants {

    static let revenueCatAPIKey = requiredConfigurationValue(for: "REVENUECAT_API_KEY")

    /// Unity's public LevelPlay demo configuration.
    ///
    /// Override these values in `Local.xcconfig` with your own app key and ad unit IDs to get
    /// deterministic test-device fill. The public demo configuration can return no fill.
    /// Source: https://github.com/ironsource-mobile/Mediation-Demo-Apps
    enum LevelPlay {
        static let appKey = configurationValue(for: "LEVELPLAY_APP_KEY", default: "8545d445")
        static let bannerAdUnitID = configurationValue(
            for: "LEVELPLAY_BANNER_AD_UNIT_ID",
            default: "iep3rxsyp9na3rw8"
        )
        static let interstitialAdUnitID = configurationValue(
            for: "LEVELPLAY_INTERSTITIAL_AD_UNIT_ID",
            default: "wmgt0712uuux8ju4"
        )
        static let rewardedAdUnitID = configurationValue(
            for: "LEVELPLAY_REWARDED_AD_UNIT_ID",
            default: "qwouvdrkuwivay5q"
        )
        static let invalidAdUnitID = "invalid-ad-unit-id"
    }

    private static func configurationValue(for key: String, default defaultValue: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty,
              !value.hasPrefix("$(") else {
            return defaultValue
        }

        return value
    }

    private static func requiredConfigurationValue(for key: String) -> String {
        let value = configurationValue(for: key, default: "")
        precondition(!value.isEmpty, "Add \(key) to Local.xcconfig before running the sample.")
        return value
    }

}
