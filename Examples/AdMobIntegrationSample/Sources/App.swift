import SwiftUI
import GoogleMobileAds
import RevenueCat

@main
struct AdMobIntegrationSampleApp: App {

    init() {
        // Initialize SDKs
        GADMobileAds.sharedInstance().start(completionHandler: nil)
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
