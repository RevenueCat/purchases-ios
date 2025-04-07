import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OfferingsView()
                .tabItem {
                    Label("Offerings", systemImage: "dollarsign")
                }
            
            PackagesView()
                .tabItem {
                    Label("Packages", systemImage: "shippingbox.fill")
                }
            
            EntitlementsView()
                .tabItem {
                    Label("Entitlements", systemImage: "medal.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
