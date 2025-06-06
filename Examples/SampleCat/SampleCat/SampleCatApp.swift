import RevenueCat
import SwiftUI

@main
struct SampleCatApp: App {
    @State private var userViewModel: UserViewModel
    @State private var healthViewModel: HealthViewModel

    init() {
        let userViewModel = UserViewModel()
        let healthViewModel = HealthViewModel(userViewModel: userViewModel)
        self.userViewModel = userViewModel
        self.healthViewModel = healthViewModel
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(userViewModel)
                .environment(healthViewModel)
        }
    }
}
