import SwiftUI
import RevenueCat

@main
struct RcMaestroApp: App {

    init() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Constants.proxyURL.flatMap { URL(string: $0) }
        Purchases.configure(withAPIKey: Constants.apiKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
