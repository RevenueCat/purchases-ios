import RevenueCat
import SwiftUI

@main
struct SampleCatApp: App {
    @State private var userViewModel = UserViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(userViewModel)
        }
    }
}
