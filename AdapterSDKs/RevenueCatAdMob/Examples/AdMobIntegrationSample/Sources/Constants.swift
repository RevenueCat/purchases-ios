import Foundation

/// Constants for the AdMob Integration Sample app.
///
/// Ad unit IDs are intentionally colocated with each `*AdManager` implementation
/// to keep each format example self-contained and easy to copy.
enum Constants {
    /// RevenueCat API Key
    /// Get your API key from https://app.revenuecat.com/
    ///
    /// NOTE: For this sample app, you can use any valid RevenueCat API key.
    /// The sample demonstrates ad event tracking, not subscription functionality.
    static let revenueCatAPIKey = "YOUR_REVENUECAT_API_KEY"

    static var configuredRevenueCatAPIKey: String {
        return self.infoValue(forKey: "RC_REVENUECAT_API_KEY") ?? self.revenueCatAPIKey
    }

    static var configuredProxyURL: URL? {
        guard let raw = self.infoValue(forKey: "RC_PROXY_URL") else { return nil }
        return URL(string: raw)
    }

    static func configuredAdUnitID(
        forOverrideKey key: String,
        defaultValue: String
    ) -> String {
        return self.infoValue(forKey: key) ?? defaultValue
    }

    private static func infoValue(forKey key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
