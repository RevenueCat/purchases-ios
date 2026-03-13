import SwiftUI
import GoogleMobileAds
import RevenueCat

@main
struct AdMobIntegrationSampleApp: App {

    init() {
        // Initialize SDKs (AdMob v13 Swift API)
        MobileAds.shared.start(completionHandler: nil)
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Constants.revenueCatAPIKey)
        print("✅ SDKs initialized")
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
