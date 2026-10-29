import RevenueCat
import SwiftUI

@main
struct AdsIntegrationSampleApp: App {

    init() {
        // RevenueCatAds reports ad events through Purchases, so point it at the same backend as the ads.
        Purchases.logLevel = .debug
        Purchases.proxyURL = URL(string: Constants.serverURL)
        Purchases.configure(withAPIKey: Constants.revenueCatAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }

}
