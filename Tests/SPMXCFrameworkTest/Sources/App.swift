import SwiftUI
import RevenueCat
import RevenueCatUI

@main
struct SPMXCFrameworkTestApp: App {

    init() {
        Purchases.configure(withAPIKey: "appl_YWHNMhMdtbbMlqAGeIkVhPeSvdA")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 20) {
            Text("SPM XCFramework Test")
                .font(.title)

            Button("Present Paywall") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
