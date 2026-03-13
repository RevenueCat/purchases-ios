import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) @testable import RevenueCat_AdMob

@available(iOS 15.0, *)
final class RCAdMobBannerDelegateForwardingTests: RCAdMobTestCase {

    func testTrackingBannerDelegateForwardsReceiveAndClickCallbacks() {
        let spy = BannerDelegateSpy()
        let bannerView = BannerView(adSize: AdSizeBanner)
        let trackingDelegate = RCAdMobBannerViewDelegate(
            delegate: spy,
            placement: "home_banner"
        )

        trackingDelegate.bannerViewDidReceiveAd(bannerView)
        trackingDelegate.bannerViewDidRecordClick(bannerView)

        XCTAssertTrue(spy.didReceiveAd)
        XCTAssertTrue(spy.didRecordClick)
    }

    func testTrackingBannerDelegateForwardsImpressionAndScreenLifecycleCallbacks() {
        let spy = BannerDelegateSpy()
        let bannerView = BannerView(adSize: AdSizeBanner)
        let trackingDelegate = RCAdMobBannerViewDelegate(
            delegate: spy,
            placement: "home_banner"
        )

        trackingDelegate.bannerViewDidRecordImpression(bannerView)
        trackingDelegate.bannerViewWillPresentScreen(bannerView)
        trackingDelegate.bannerViewWillDismissScreen(bannerView)
        trackingDelegate.bannerViewDidDismissScreen(bannerView)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(spy.willPresentScreen)
        XCTAssertTrue(spy.willDismissScreen)
        XCTAssertTrue(spy.didDismissScreen)
    }

    func testTrackingBannerDelegateForwardsFailureCallback() {
        let spy = BannerDelegateSpy()
        let bannerView = BannerView(adSize: AdSizeBanner)
        let trackingDelegate = RCAdMobBannerViewDelegate(
            delegate: spy,
            placement: "home_banner"
        )

        trackingDelegate.bannerView(
            bannerView,
            didFailToReceiveAdWithError: NSError(domain: "test", code: 1)
        )

        XCTAssertTrue(spy.didFailToReceiveAd)
    }

    func testTrackingBannerDelegateCallbacksDoNotCrashWithoutDelegate() {
        let bannerView = BannerView(adSize: AdSizeBanner)
        let trackingDelegate = RCAdMobBannerViewDelegate(
            delegate: nil,
            placement: "home_banner"
        )

        trackingDelegate.bannerViewDidReceiveAd(bannerView)
        trackingDelegate.bannerViewDidRecordImpression(bannerView)
        trackingDelegate.bannerViewDidRecordClick(bannerView)
        trackingDelegate.bannerViewWillPresentScreen(bannerView)
        trackingDelegate.bannerViewWillDismissScreen(bannerView)
        trackingDelegate.bannerViewDidDismissScreen(bannerView)
        trackingDelegate.bannerView(
            bannerView,
            didFailToReceiveAdWithError: NSError(domain: "test", code: 1)
        )
    }

    func testTrackingBannerDelegateReadsResponseInfoOnlyForTrackedCallbacks() {
        let spy = BannerDelegateSpy()
        let bannerBacking = CountingBannerPlaceholder()
        bannerBacking.adUnitID = ""
        let bannerView = unsafeBitCast(bannerBacking, to: BannerView.self)
        let trackingDelegate = RCAdMobBannerViewDelegate(
            delegate: spy,
            placement: nil
        )

        trackingDelegate.bannerViewDidReceiveAd(bannerView)
        trackingDelegate.bannerViewDidRecordImpression(bannerView)
        trackingDelegate.bannerViewDidRecordClick(bannerView)
        trackingDelegate.bannerViewWillPresentScreen(bannerView)
        trackingDelegate.bannerViewWillDismissScreen(bannerView)
        trackingDelegate.bannerViewDidDismissScreen(bannerView)
        trackingDelegate.bannerView(
            bannerView,
            didFailToReceiveAdWithError: NSError(domain: "test", code: 2)
        )

        XCTAssertEqual(bannerBacking.responseInfoReads, 3)
    }

}

@available(iOS 15.0, *)
private final class BannerDelegateSpy: NSObject, BannerViewDelegate {

    var didReceiveAd = false
    var didRecordClick = false
    var didRecordImpression = false
    var didFailToReceiveAd = false
    var willPresentScreen = false
    var willDismissScreen = false
    var didDismissScreen = false

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        self.didReceiveAd = true
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        self.didRecordImpression = true
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        self.didRecordClick = true
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
        self.didFailToReceiveAd = true
    }

    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        self.willPresentScreen = true
    }

    func bannerViewWillDismissScreen(_ bannerView: BannerView) {
        self.willDismissScreen = true
    }

    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        self.didDismissScreen = true
    }

}

@available(iOS 15.0, *)
private final class CountingBannerPlaceholder: NSObject {
    private(set) var responseInfoReads = 0
    @objc var adUnitID: String?

    @objc var responseInfo: ResponseInfo? {
        self.responseInfoReads += 1
        return nil
    }
}
#endif
