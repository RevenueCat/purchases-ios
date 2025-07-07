import SwiftUI
import RevenueCat

@main
struct RcMaestroApp: App {

    init() {
        Purchases.logLevel = .debug
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String {
            Purchases.configure(withAPIKey: "api_key")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
