import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class InterstitialAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/4411468910"

    var interstitialAd: InterstitialAd?
    @Published var status = "Not Loaded"

    func loadAd() {
        self.status = "Loading..."

        InterstitialAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "interstitial_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Interstitial failed: \(error.localizedDescription)")
                self.status = "Failed"
                return
            }

            guard let loadedAd else { return }

            print("✅ Interstitial loaded")
            self.interstitialAd = loadedAd
            self.status = "Ready"
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
            self.status = "Not Loaded"
        }
    }
}
