import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RCAdMobAPISurfaceTests: RCAdMobTestCase {

    func testBannerAndNativeEntryPointsRemainAvailableInSwift() {
        let bannerLoadAndTrack: (RCGoogleMobileAds.BannerView) -> (
            RCGoogleMobileAds.Request,
            String?,
            RCGoogleMobileAds.BannerViewDelegate?,
            ((RCGoogleMobileAds.AdValue) -> Void)?
        ) -> Void = RCGoogleMobileAds.BannerView.loadAndTrack(
            request:placement:delegate:paidEventHandler:
        )
        let nativeLoadAndTrackWithDelegate:
            (RCGoogleMobileAds.AdLoader) -> (
                RCGoogleMobileAds.Request,
                String,
                String?,
                RCGoogleMobileAds.NativeAdDelegate?
            ) -> Void = RCGoogleMobileAds.AdLoader.loadAndTrack(
                _:adUnitID:placement:nativeAdDelegate:
            )

        XCTAssertNotNil(bannerLoadAndTrack)
        XCTAssertNotNil(nativeLoadAndTrackWithDelegate)
    }

    func testFullScreenEntryPointsRemainAvailableInSwift() {
        let interstitialLoadAndTrack: (
            String,
            RCGoogleMobileAds.Request,
            String?,
            RCGoogleMobileAds.FullScreenContentDelegate?,
            ((RCGoogleMobileAds.AdValue) -> Void)?,
            @escaping (RCGoogleMobileAds.InterstitialAd?, Error?) -> Void
        ) -> Void = RCGoogleMobileAds.InterstitialAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:
        )
        let appOpenLoadAndTrack: (
            String,
            RCGoogleMobileAds.Request,
            String?,
            RCGoogleMobileAds.FullScreenContentDelegate?,
            ((RCGoogleMobileAds.AdValue) -> Void)?,
            @escaping (RCGoogleMobileAds.AppOpenAd?, Error?) -> Void
        ) -> Void = RCGoogleMobileAds.AppOpenAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:
        )
        let rewardedLoadAndTrack: (
            String,
            RCGoogleMobileAds.Request,
            String?,
            RCGoogleMobileAds.FullScreenContentDelegate?,
            ((RCGoogleMobileAds.AdValue) -> Void)?,
            @escaping (RCGoogleMobileAds.RewardedAd?, Error?) -> Void
        ) -> Void = RCGoogleMobileAds.RewardedAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:
        )
        let rewardedInterstitialLoadAndTrack: (
            String,
            RCGoogleMobileAds.Request,
            String?,
            RCGoogleMobileAds.FullScreenContentDelegate?,
            ((RCGoogleMobileAds.AdValue) -> Void)?,
            @escaping (RCGoogleMobileAds.RewardedInterstitialAd?, Error?) -> Void
        ) -> Void = RCGoogleMobileAds.RewardedInterstitialAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:
        )

        XCTAssertNotNil(interstitialLoadAndTrack)
        XCTAssertNotNil(appOpenLoadAndTrack)
        XCTAssertNotNil(rewardedLoadAndTrack)
        XCTAssertNotNil(rewardedInterstitialLoadAndTrack)
    }

}
#endif
