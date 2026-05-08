import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class ErrorTestingAdManager: NSObject, ObservableObject {

    private static let invalidAdUnitID = "invalid-ad-unit-id"

    private var errorTestBannerView: BannerView?

    func loadAd() {
        print("Loading ad with invalid ID to test error tracking")

        let bannerSize = AdSize(size: CGSize(width: 320, height: 50), flags: 0)
        let banner = BannerView(adSize: bannerSize)
        banner.adUnitID = Self.invalidAdUnitID
        // Keep a strong reference until the async load callback runs.
        // Otherwise the banner can be deallocated early and the failure event is never tracked.
        self.errorTestBannerView = banner
        banner.loadAndTrack(request: Request(), placement: "error_test")
    }

}
