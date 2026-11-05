import Foundation

/// Defaults for the Ads Integration Sample app. All of them can be edited in the app's UI
/// or overridden with the `RC_ADS_*` environment variables (see README).
enum Constants {
    /// RevenueCat public API key: configures `Purchases` (which tracks the ad events) and is sent to the
    /// auction endpoint as `Authorization: Bearer <key>`.
    /// Get your API key from https://app.revenuecat.com/
    static let revenueCatAPIKey = environment["RC_ADS_API_KEY"] ?? "YOUR_REVENUECAT_API_KEY"

    /// Base URL of the RevenueCat ad-serving backend. `/v1/ads/openrtb2/auction` is appended by `RevenueCatAds`.
    /// Also used as `Purchases.proxyURL`, so ad events are posted to the same backend.
    /// Defaults to Khepri's local Envoy (reachable from the iOS Simulator as `localhost`).
    static let serverURL = environment["RC_ADS_SERVER_URL"] ?? "http://localhost:8180"

    /// Becomes the Prebid config ID (`imp.tagid`); any stable string.
    static let placementID = environment["RC_ADS_PLACEMENT_ID"] ?? "interstitial"

    /// Loads at launch and presents as soon as the ad is loaded, so the flow can be driven
    /// without tapping (e.g. `xcrun simctl launch` with `SIMCTL_CHILD_RC_ADS_AUTO_RUN=1`).
    static let autoRun = environment["RC_ADS_AUTO_RUN"] == "1"

    private static let environment = ProcessInfo.processInfo.environment
}
