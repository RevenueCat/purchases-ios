import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class NativeAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/2247696110"

    var nativeAdLoader: AdLoader?

    @Published var nativeAd: NativeAd?
    @Published var message = Messages.notLoaded

    func loadAd() {
        self.message = Messages.loading
        let adLoader = AdLoader(
            adUnitID: Self.adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        adLoader.delegate = self
        adLoader.loadAndTrack(
            Request(),
            placement: "native_main",
            nativeAdDelegate: nil
        )

        self.nativeAdLoader = adLoader
    }

}

extension NativeAdManager: NativeAdLoaderDelegate, AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard adLoader === self.nativeAdLoader else { return }
        print("✅ Native ad loaded")
        self.nativeAd = nativeAd
        self.message = Messages.ready
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        guard adLoader === self.nativeAdLoader else { return }
        print("❌ Native ad failed: \(error.localizedDescription)")
        self.message = Messages.failed
    }
}
