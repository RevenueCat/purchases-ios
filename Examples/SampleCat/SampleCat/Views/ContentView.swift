import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OfferingsView()
                .tabItem {
                    Image(systemName: "dollarsign")
                    Text("Offerings")
                }
        }
    }
}

#Preview {
    ContentView()
}
