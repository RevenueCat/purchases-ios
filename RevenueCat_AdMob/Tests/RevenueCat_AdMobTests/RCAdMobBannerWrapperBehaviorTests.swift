import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) @testable import RevenueCat_AdMob

@available(iOS 15.0, *)
final class RCAdMobBannerWrapperBehaviorTests: RCAdMobTestCase {

    func testLoadAndTrackPrefersExplicitDelegateOverExistingDelegate() {
        let bannerView = BannerView(adSize: AdSizeBanner)
        let existingDelegate = BannerDelegateMarker()
        let explicitDelegate = BannerDelegateMarker()
        bannerView.delegate = existingDelegate

        bannerView.loadAndTrack(
            request: Request(),
            placement: "home_banner",
            delegate: explicitDelegate
        )

        let trackingDelegate = bannerView.delegate as? RCAdMobBannerViewDelegate
        XCTAssertNotNil(trackingDelegate)
        XCTAssertTrue(trackingDelegate?.delegate === explicitDelegate)
    }

    func testLoadAndTrackTwiceDoesNotNestTrackingDelegates() {
        let bannerView = BannerView(adSize: AdSizeBanner)
        let userDelegate = BannerDelegateMarker()
        bannerView.delegate = userDelegate

        bannerView.loadAndTrack(request: Request(), placement: "home_banner")
        let firstTrackingDelegate = bannerView.delegate as? RCAdMobBannerViewDelegate
        XCTAssertNotNil(firstTrackingDelegate)

        bannerView.loadAndTrack(request: Request(), placement: "home_banner")
        let secondTrackingDelegate = bannerView.delegate as? RCAdMobBannerViewDelegate

        XCTAssertNotNil(secondTrackingDelegate)
        XCTAssertTrue(secondTrackingDelegate?.delegate === userDelegate)
        XCTAssertFalse(secondTrackingDelegate?.delegate === firstTrackingDelegate)
    }

}

@available(iOS 15.0, *)
private final class BannerDelegateMarker: NSObject, BannerViewDelegate {}

#endif
