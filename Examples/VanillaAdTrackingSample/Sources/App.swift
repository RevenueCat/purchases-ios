import RevenueCat
import SwiftUI

@main
struct VanillaAdTrackingSampleApp: App {

    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Constants.revenueCatAPIKey)
        print("✅ RevenueCat SDK initialized")
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
