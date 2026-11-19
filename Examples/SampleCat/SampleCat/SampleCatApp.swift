import RevenueCat
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(CheckpointsInternal) @_spi(Internal) import RevenueCatAdMob
#endif

@main
struct SampleCatApp: App {
    @State private var userViewModel: UserViewModel
    @State private var healthViewModel: HealthViewModel

    init() {
        let userViewModel = UserViewModel()
        let healthViewModel = HealthViewModel(userViewModel: userViewModel)
        self.userViewModel = userViewModel
        self.healthViewModel = healthViewModel
        Self.configureAdMob()
    }

    /// Lets a checkpoint that resolves to an ad step present through AdMob.
    private static func configureAdMob() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        Purchases.shared.adPresenter = AdMobPresenter()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(userViewModel)
                .environment(healthViewModel)
        }
    }
}
