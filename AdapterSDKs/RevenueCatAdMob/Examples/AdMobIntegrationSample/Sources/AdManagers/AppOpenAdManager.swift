import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class AppOpenAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/5575463023"

    var appOpenAd: AppOpenAd?
    @Published var message: Message?

    var canShow: Bool { self.appOpenAd != nil }

    func loadAd() {
        self.message = Message.loading

        AppOpenAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "app_open_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ App Open failed: \(error.localizedDescription)")
                self.message = Message.failed
                return
            }

            guard let loadedAd else { return }

            print("✅ App Open loaded")
            self.appOpenAd = loadedAd
            self.message = Message.ready
        }
    }

    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.appOpenAd else {
            print("⚠️ App Open not ready")
            return
        }

        loadedAd.present(from: viewController)
    }

}

extension AppOpenAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        if adObject is AppOpenAd {
            self.appOpenAd = nil
            self.message = nil
        }
    }
}
