import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class BannerAdManager: NSObject, ObservableObject {

    private static var adUnitID: String {
        return Constants.configuredAdUnitID(
            forOverrideKey: "RC_BANNER_AD_UNIT_ID_OVERRIDE",
            defaultValue: "ca-app-pub-3940256099942544/2435281174"
        )
    }

    private(set) var bannerView: BannerView?

    func loadAd() -> BannerView {
        let bannerSize = AdSize(size: CGSize(width: 320, height: 50), flags: 0)
        let banner = BannerView(adSize: bannerSize)
        banner.adUnitID = Self.adUnitID
        banner.loadAndTrack(request: Request(), placement: "home_banner")
        self.bannerView = banner
        return banner
    }

}
