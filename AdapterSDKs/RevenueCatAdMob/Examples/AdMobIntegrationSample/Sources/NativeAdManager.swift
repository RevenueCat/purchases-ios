import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class NativeAdManager: NSObject, ObservableObject {

    enum AdType {
        case native
        case nativeVideo
    }

    private static let nativeAdUnitID = "ca-app-pub-3940256099942544/2247696110"
    private static let nativeVideoAdUnitID = "ca-app-pub-3940256099942544/1044960115"

    var nativeAdLoader: AdLoader?
    var nativeVideoAdLoader: AdLoader?

    @Published var nativeAd: NativeAd?
    @Published var nativeVideoAd: NativeAd?
    @Published var nativeAdStatus = "Not Loaded"
    @Published var nativeVideoAdStatus = "Not Loaded"

    func loadAd(_ type: AdType) {
        let adUnitID: String
        let placement: String

        switch type {
        case .native:
            self.nativeAdStatus = "Loading..."
            adUnitID = Self.nativeAdUnitID
            placement = "native_main"
        case .nativeVideo:
            self.nativeVideoAdStatus = "Loading..."
            adUnitID = Self.nativeVideoAdUnitID
            placement = "native_video_main"
        }

        let adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        adLoader.delegate = self
        adLoader.loadAndTrack(
            Request(),
            placement: placement,
            nativeAdDelegate: nil
        )

        if type == .native {
            self.nativeAdLoader = adLoader
        } else {
            self.nativeVideoAdLoader = adLoader
        }
    }

}

extension NativeAdManager: NativeAdLoaderDelegate, AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        let isNativeVideo = adLoader === self.nativeVideoAdLoader
        let isNative = adLoader === self.nativeAdLoader
        guard isNativeVideo || isNative else { return }

        print("✅ \(isNativeVideo ? "Native video" : "Native") ad loaded")

        if isNativeVideo {
            self.nativeVideoAd = nativeAd
            self.nativeVideoAdStatus = "Ready"
        } else {
            self.nativeAd = nativeAd
            self.nativeAdStatus = "Ready"
        }
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        let isNativeVideo = adLoader === self.nativeVideoAdLoader
        let isNative = adLoader === self.nativeAdLoader
        guard isNativeVideo || isNative else { return }

        print("❌ \(isNativeVideo ? "Native video" : "Native") ad failed: \(error.localizedDescription)")

        if isNativeVideo {
            self.nativeVideoAdStatus = "Failed"
        } else {
            self.nativeAdStatus = "Failed"
        }
    }
}
