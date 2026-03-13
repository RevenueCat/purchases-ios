import Foundation
import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCat_AdMob

@available(iOS 15.0, *)
final class RCAdMobDelegateContractTests: RCAdMobTestCase {

    func testFullScreenTrackingDelegateImplementsExpectedCallbacks() {
        XCTAssertTrue(
            RCAdMobFullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adDidRecordImpression:")
            )
        )
        XCTAssertTrue(
            RCAdMobFullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adDidRecordClick:")
            )
        )
        XCTAssertTrue(
            RCAdMobFullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adWillPresentFullScreenContent:")
            )
        )
        XCTAssertTrue(
            RCAdMobFullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adWillDismissFullScreenContent:")
            )
        )
        XCTAssertTrue(
            RCAdMobFullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("adDidDismissFullScreenContent:")
            )
        )
        XCTAssertTrue(
            RCAdMobFullScreenContentDelegate.instancesRespond(
                to: NSSelectorFromString("ad:didFailToPresentFullScreenContentWithError:")
            )
        )
    }

    func testBannerTrackingDelegateImplementsExpectedCallbacks() {
        XCTAssertTrue(
            RCAdMobBannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewDidReceiveAd:")
            )
        )
        XCTAssertTrue(
            RCAdMobBannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerView:didFailToReceiveAdWithError:")
            )
        )
        XCTAssertTrue(
            RCAdMobBannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewDidRecordImpression:")
            )
        )
        XCTAssertTrue(
            RCAdMobBannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewDidRecordClick:")
            )
        )
        XCTAssertTrue(
            RCAdMobBannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewWillPresentScreen:")
            )
        )
        XCTAssertTrue(
            RCAdMobBannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewWillDismissScreen:")
            )
        )
        XCTAssertTrue(
            RCAdMobBannerViewDelegate.instancesRespond(
                to: NSSelectorFromString("bannerViewDidDismissScreen:")
            )
        )
    }

    func testNativeTrackingDelegateImplementsExpectedCallbacks() {
        XCTAssertTrue(
            RCAdMobNativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdDidRecordImpression:")
            )
        )
        XCTAssertTrue(
            RCAdMobNativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdDidRecordClick:")
            )
        )
        XCTAssertTrue(
            RCAdMobNativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdWillPresentScreen:")
            )
        )
        XCTAssertTrue(
            RCAdMobNativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdWillDismissScreen:")
            )
        )
        XCTAssertTrue(
            RCAdMobNativeAdDelegate.instancesRespond(
                to: NSSelectorFromString("nativeAdDidDismissScreen:")
            )
        )
    }

}

#endif
