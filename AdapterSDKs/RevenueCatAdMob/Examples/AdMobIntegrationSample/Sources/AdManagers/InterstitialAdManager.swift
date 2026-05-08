import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class InterstitialAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/4411468910"

    var interstitialAd: InterstitialAd?
    @Published var message: String?

    var canShow: Bool { self.interstitialAd != nil }

    func loadAd() {
        self.message = Messages.loading

        InterstitialAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "interstitial_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Interstitial failed: \(error.localizedDescription)")
                self.message = Messages.failed
                return
            }

            guard let loadedAd else { return }

            print("✅ Interstitial loaded")
            self.interstitialAd = loadedAd
            self.message = Messages.ready
        }
    }

    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.interstitialAd else {
            print("⚠️ Interstitial not ready")
            return
        }

        loadedAd.present(from: viewController)
    }

}

extension InterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        if adObject is InterstitialAd {
            self.interstitialAd = nil
            self.message = nil
        }
    }
}
