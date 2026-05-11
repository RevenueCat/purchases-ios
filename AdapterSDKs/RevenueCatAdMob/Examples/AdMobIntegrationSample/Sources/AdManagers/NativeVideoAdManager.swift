import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class NativeVideoAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/1044960115"

    var nativeVideoAdLoader: AdLoader?

    @Published var nativeAd: NativeAd?
    @Published var message: Message?

    func loadAd() {
        self.message = Message.loading
        let adLoader = AdLoader(
            adUnitID: Self.adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        adLoader.delegate = self
        adLoader.loadAndTrack(
            Request(),
            placement: "native_video_main",
            nativeAdDelegate: nil
        )

        self.nativeVideoAdLoader = adLoader
    }

}

extension NativeVideoAdManager: NativeAdLoaderDelegate, AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard adLoader === self.nativeVideoAdLoader else { return }
        print("✅ Native video ad loaded")
        self.nativeAd = nativeAd
        self.message = Message.ready
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        guard adLoader === self.nativeVideoAdLoader else { return }
        print("❌ Native video ad failed: \(error.localizedDescription)")
        self.message = Message.failed
    }
}
