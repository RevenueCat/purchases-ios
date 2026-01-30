import Foundation

/// Constants for the AdMob Integration Sample app.
///
/// IMPORTANT: These are test ad unit IDs provided by Google AdMob for development and testing.
/// Replace these with your actual production ad unit IDs before publishing your app.
enum Constants {
    /// RevenueCat API Key
    /// Get your API key from https://app.revenuecat.com/
    ///
    /// NOTE: For this sample app, you can use any valid RevenueCat API key.
    /// The sample demonstrates ad event tracking, not subscription functionality.
    #error("Modify this property to reflect your app's API key, then comment this line out.")
    static let revenueCatAPIKey = "YOUR_REVENUECAT_API_KEY_HERE"

    /// AdMob Test Ad Unit IDs
    /// These are official test IDs provided by Google that always serve test ads.
    /// Source: https://developers.google.com/admob/ios/test-ads
    enum AdMob {
        /// Banner Ad Test Unit ID
        /// Always successfully loads and displays a test banner ad.
        static let bannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

        /// Interstitial Ad Test Unit ID
        /// Always successfully loads and displays a test interstitial ad.
        static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"

        /// App Open Ad Test Unit ID
        /// Always successfully loads and displays a test app open ad.
        /// App open ads are full-screen ads shown when users open or switch back to your app.
        static let appOpenAdUnitID = "ca-app-pub-3940256099942544/5575463023"

        /// Native Ad Test Unit ID
        /// Test ID for native ads (text + images).
        /// Official Google test ID for Native Advanced ads.
        ///
        /// ⚠️ IMPORTANT: This test ID does not work reliably for native ads.
        /// Google's test IDs for native ads often fail to load or behave inconsistently.
        /// For reliable testing:
        /// 1. Use a production ad unit ID from your AdMob account
        /// 2. Configure your device as a test device
        static let nativeAdUnitID = "ca-app-pub-3940256099942544/2247696110"

        /// Native Video Ad Test Unit ID
        /// Test ID for native ads with video content.
        /// Official Google test ID for Native Advanced Video ads.
        ///
        /// ⚠️ IMPORTANT: This test ID does not work reliably for native video ads.
        /// Google's test IDs for native ads often fail to load or behave inconsistently.
        /// For reliable testing:
        /// 1. Use a production ad unit ID from your AdMob account
        /// 2. Configure your device as a test device
        static let nativeVideoAdUnitID = "ca-app-pub-3940256099942544/1044960115"

        /// Invalid Ad Unit ID - Used for Error Handling
        /// This intentionally invalid ID triggers load failures to demonstrate
        /// how to handle and track ad load errors with RevenueCat.
        ///
        /// NOTE: AdMob does not provide an official "error test ID", so we use
        /// an invalid ID to simulate load failures for testing purposes.
        static let invalidAdUnitID = "invalid-ad-unit-id"
    }
}
