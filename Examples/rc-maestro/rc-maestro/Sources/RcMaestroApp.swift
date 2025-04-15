import SwiftUI
import RevenueCat

@main
struct RcMaestroApp: App {

    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_fEVHDkWYraujHYbxopxJknYGNUx")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
