import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Home()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            Settings()
                .tabItem {
                    Image(systemName: "cog.fill")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    ContentView()
}
