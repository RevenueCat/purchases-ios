import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OfferingsView()
                .tabItem {
                    Label("Offerings", systemImage: "dollarsign")
                }
            
            ProductsView()
                .tabItem {
                    Label("Products", systemImage: "shippingbox.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
