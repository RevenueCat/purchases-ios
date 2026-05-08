import GoogleMobileAds
import RevenueCat
import SwiftUI

@main
struct AdMobIntegrationSampleApp: App {

    init() {
        // Initialize SDKs (AdMob v13 Swift API)
        MobileAds.shared.start(completionHandler: nil)
        Purchases.logLevel = .debug
        Purchases.proxyURL = Constants.configuredProxyURL
        Purchases.configure(withAPIKey: Constants.configuredRevenueCatAPIKey)
        print("✅ SDKs initialized")
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
