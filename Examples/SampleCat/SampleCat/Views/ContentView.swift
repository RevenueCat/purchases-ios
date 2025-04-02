import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OfferingsView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Offerings")
                }
        }
    }
}

#Preview {
    ContentView()
}
