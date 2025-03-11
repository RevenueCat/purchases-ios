import RevenueCat
import SwiftUI

@main
struct SampleCatApp: App {
    init() {
        Purchases.configure(withAPIKey: Constants.apiKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
