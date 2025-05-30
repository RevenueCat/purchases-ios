import RevenueCat
import SwiftUI

@main
struct SampleCatApp: App {
    @State private var userViewModel = UserViewModel()
    @State private var healthViewModel = HealthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(userViewModel)
                .environment(healthViewModel)
        }
    }
}
