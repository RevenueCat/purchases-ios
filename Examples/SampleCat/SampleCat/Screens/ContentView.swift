import SwiftUI

struct ContentView: View {
    @Environment(HealthViewModel.self) var healthViewModel

    var body: some View {
        @Bindable var healthViewModel = healthViewModel

        TabView {
            OfferingsView()
                .tabItem {
                    Label("Offerings", systemImage: "dollarsign")
                }

            ProductsView()
                .tabItem {
                    Label("Products", systemImage: "shippingbox.fill")
                }

            CustomerCenterTabView()
                .tabItem {
                    Label("Customer Center", systemImage: "person.crop.circle")
                }

            PaywallsTabView()
                .tabItem {
                    Label("Paywalls", systemImage: "rectangle.portrait")
                }
        }
        .fullScreenCover(item: $healthViewModel.blockingError) { error in
            FullScreenErrorView(error: error)
        }
    }
}
