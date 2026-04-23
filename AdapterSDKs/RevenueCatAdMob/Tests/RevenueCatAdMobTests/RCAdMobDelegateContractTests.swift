import Foundation
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RCAdMobDelegateContractTests: RCAdMobTestCase {

    func testFullScreenTrackingDelegateImplementsExpectedCallbacks() {
        XCTAssertTrue(
            Tracking.FullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adDidRecordImpression:")
            )
        )
        XCTAssertTrue(
            Tracking.FullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adDidRecordClick:")
            )
        )
        XCTAssertTrue(
            Tracking.FullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adWillPresentFullScreenContent:")
            )
        )
        XCTAssertTrue(
            Tracking.FullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adWillDismissFullScreenContent:")
            )
        )
        XCTAssertTrue(
            Tracking.FullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adDidDismissFullScreenContent:")
            )
        )
        XCTAssertTrue(
            Tracking.FullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("ad:didFailToPresentFullScreenContentWithError:")
            )
        )
    }

    func testBannerTrackingDelegateImplementsExpectedCallbacks() {
        XCTAssertTrue(
            Tracking.BannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewDidReceiveAd:")
            )
        )
        XCTAssertTrue(
            Tracking.BannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerView:didFailToReceiveAdWithError:")
            )
        )
        XCTAssertTrue(
            Tracking.BannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewDidRecordImpression:")
            )
        )
        XCTAssertTrue(
            Tracking.BannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewDidRecordClick:")
            )
        )
        XCTAssertTrue(
            Tracking.BannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewWillPresentScreen:")
            )
        )
        XCTAssertTrue(
            Tracking.BannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewWillDismissScreen:")
            )
        )
        XCTAssertTrue(
            Tracking.BannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewDidDismissScreen:")
            )
        )
    }

    func testNativeTrackingDelegateImplementsExpectedCallbacks() {
        XCTAssertTrue(
            Tracking.NativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdDidRecordImpression:")
            )
        )
        XCTAssertTrue(
            Tracking.NativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdDidRecordClick:")
            )
        )
        XCTAssertTrue(
            Tracking.NativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdWillPresentScreen:")
            )
        )
        XCTAssertTrue(
            Tracking.NativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdWillDismissScreen:")
            )
        )
        XCTAssertTrue(
            Tracking.NativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdDidDismissScreen:")
            )
        )
    }

}

#endif
