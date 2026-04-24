import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class APISurfaceTests: AdapterTestCase {

    func testBannerAndNativeEntryPointsRemainAvailableInSwift() {
        let bannerLoadAndTrack: (GoogleMobileAds.BannerView) -> (
            GoogleMobileAds.Request,
            String?,
            GoogleMobileAds.BannerViewDelegate?,
            ((GoogleMobileAds.AdValue) -> Void)?
        ) -> Void = GoogleMobileAds.BannerView.loadAndTrack(
            request:placement:delegate:paidEventHandler:
        )
        let nativeLoadAndTrackWithDelegate:
            (GoogleMobileAds.AdLoader) -> (
                GoogleMobileAds.Request,
                String?,
                GoogleMobileAds.NativeAdDelegate?
            ) -> Void = GoogleMobileAds.AdLoader.loadAndTrack(
                _:placement:nativeAdDelegate:
            )

        XCTAssertNotNil(bannerLoadAndTrack)
        XCTAssertNotNil(nativeLoadAndTrackWithDelegate)
    }

    func testFullScreenCompletionEntryPointsRemainAvailableInSwift() {
        let interstitialLoadAndTrack: (
            String,
            GoogleMobileAds.Request,
            String?,
            GoogleMobileAds.FullScreenContentDelegate?,
            ((GoogleMobileAds.AdValue) -> Void)?,
            @escaping @MainActor (GoogleMobileAds.InterstitialAd?, Error?) -> Void
        ) -> Void = GoogleMobileAds.InterstitialAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:
        )
        let appOpenLoadAndTrack: (
            String,
            GoogleMobileAds.Request,
            String?,
            GoogleMobileAds.FullScreenContentDelegate?,
            ((GoogleMobileAds.AdValue) -> Void)?,
            @escaping @MainActor (GoogleMobileAds.AppOpenAd?, Error?) -> Void
        ) -> Void = GoogleMobileAds.AppOpenAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:
        )
        let rewardedLoadAndTrack: (
            String,
            GoogleMobileAds.Request,
            String?,
            GoogleMobileAds.FullScreenContentDelegate?,
            ((GoogleMobileAds.AdValue) -> Void)?,
            @escaping @MainActor (GoogleMobileAds.RewardedAd?, Error?) -> Void
        ) -> Void = GoogleMobileAds.RewardedAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:
        )
        let rewardedInterstitialLoadAndTrack: (
            String,
            GoogleMobileAds.Request,
            String?,
            GoogleMobileAds.FullScreenContentDelegate?,
            ((GoogleMobileAds.AdValue) -> Void)?,
            @escaping @MainActor (GoogleMobileAds.RewardedInterstitialAd?, Error?) -> Void
        ) -> Void = GoogleMobileAds.RewardedInterstitialAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:
        )

        XCTAssertNotNil(interstitialLoadAndTrack)
        XCTAssertNotNil(appOpenLoadAndTrack)
        XCTAssertNotNil(rewardedLoadAndTrack)
        XCTAssertNotNil(rewardedInterstitialLoadAndTrack)
    }

    func testFullScreenAsyncEntryPointsRemainAvailableInSwift() {
        let interstitialLoadAndTrack: (
            String,
            GoogleMobileAds.Request,
            String?,
            GoogleMobileAds.FullScreenContentDelegate?,
            ((GoogleMobileAds.AdValue) -> Void)?
        ) async throws -> GoogleMobileAds.InterstitialAd = GoogleMobileAds.InterstitialAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:
        )
        let appOpenLoadAndTrack: (
            String,
            GoogleMobileAds.Request,
            String?,
            GoogleMobileAds.FullScreenContentDelegate?,
            ((GoogleMobileAds.AdValue) -> Void)?
        ) async throws -> GoogleMobileAds.AppOpenAd = GoogleMobileAds.AppOpenAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:
        )
        let rewardedLoadAndTrack: (
            String,
            GoogleMobileAds.Request,
            String?,
            GoogleMobileAds.FullScreenContentDelegate?,
            ((GoogleMobileAds.AdValue) -> Void)?
        ) async throws -> GoogleMobileAds.RewardedAd = GoogleMobileAds.RewardedAd.loadAndTrack(
            withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:
        )
        let rewardedInterstitialLoadAndTrack: (
            String,
            GoogleMobileAds.Request,
            String?,
            GoogleMobileAds.FullScreenContentDelegate?,
            ((GoogleMobileAds.AdValue) -> Void)?
        ) async throws -> GoogleMobileAds.RewardedInterstitialAd
            = GoogleMobileAds.RewardedInterstitialAd.loadAndTrack(
                withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:
            )

        XCTAssertNotNil(interstitialLoadAndTrack)
        XCTAssertNotNil(appOpenLoadAndTrack)
        XCTAssertNotNil(rewardedLoadAndTrack)
        XCTAssertNotNil(rewardedInterstitialLoadAndTrack)
    }

    @MainActor
    func testFullScreenPresentWithPlacementRemainAvailableInSwift() {
        let interstitialPresent: (
            GoogleMobileAds.InterstitialAd
        ) -> (UIViewController, String?) -> Void = GoogleMobileAds.InterstitialAd.present(
            from:placement:
        )
        let appOpenPresent: (
            GoogleMobileAds.AppOpenAd
        ) -> (UIViewController, String?) -> Void = GoogleMobileAds.AppOpenAd.present(
            from:placement:
        )
        let rewardedPresent: (
            GoogleMobileAds.RewardedAd
        ) -> (UIViewController, String?, @escaping () -> Void) -> Void = GoogleMobileAds.RewardedAd.present(
            from:placement:userDidEarnRewardHandler:
        )
        let rewardedInterstitialPresent: (
            GoogleMobileAds.RewardedInterstitialAd
        ) -> (UIViewController, String?, @escaping () -> Void)
            -> Void = GoogleMobileAds.RewardedInterstitialAd.present(
                from:placement:userDidEarnRewardHandler:
            )

        XCTAssertNotNil(interstitialPresent)
        XCTAssertNotNil(appOpenPresent)
        XCTAssertNotNil(rewardedPresent)
        XCTAssertNotNil(rewardedInterstitialPresent)
    }

    @MainActor
    func testEnableRewardVerificationEntryPointsRemainAvailableInSwift() {
        let rewardedEnable: (GoogleMobileAds.RewardedAd) -> Void = { $0.enableRewardVerification() }
        let rewardedInterstitialEnable: (GoogleMobileAds.RewardedInterstitialAd) -> Void = {
            $0.enableRewardVerification()
        }

        XCTAssertNotNil(rewardedEnable)
        XCTAssertNotNil(rewardedInterstitialEnable)
    }

}
#endif
