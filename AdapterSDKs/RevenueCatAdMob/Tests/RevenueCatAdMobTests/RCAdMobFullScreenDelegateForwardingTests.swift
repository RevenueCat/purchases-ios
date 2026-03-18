import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RCAdMobFullScreenDelegateForwardingTests: RCAdMobTestCase {

    func testTrackingFullScreenDelegateForwardsAllCallbacks() {
        let spy = FullScreenDelegateSpy()
        let subject = RCAdMobFullScreenContentDelegate(
            delegate: spy,
            placement: "interstitial_home",
            adUnitID: "test_unit",
            adFormat: .interstitial,
            responseInfoProvider: { nil }
        )
        let presentingAd = PresentingAdStub()
        let error = NSError(domain: "test", code: 1)

        subject.adDidRecordImpression(presentingAd)
        subject.adDidRecordClick(presentingAd)
        subject.adWillPresentFullScreenContent(presentingAd)
        subject.adWillDismissFullScreenContent(presentingAd)
        subject.adDidDismissFullScreenContent(presentingAd)
        subject.ad(presentingAd, didFailToPresentFullScreenContentWithError: error)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(spy.didRecordClick)
        XCTAssertTrue(spy.willPresent)
        XCTAssertTrue(spy.willDismiss)
        XCTAssertTrue(spy.didDismiss)
        XCTAssertEqual(spy.presentFailureCode, 1)
    }

    func testTrackingFullScreenDelegateForwardsAllCallbacksForInterstitialFormat() {
        let spy = FullScreenDelegateSpy()
        let subject = RCAdMobFullScreenContentDelegate(
            delegate: spy,
            placement: "interstitial_home_explicit",
            adUnitID: "interstitial_test_unit",
            adFormat: .interstitial,
            responseInfoProvider: { nil }
        )
        let presentingAd = PresentingAdStub()
        let error = NSError(domain: "test", code: 41)

        subject.adDidRecordImpression(presentingAd)
        subject.adDidRecordClick(presentingAd)
        subject.adWillPresentFullScreenContent(presentingAd)
        subject.adWillDismissFullScreenContent(presentingAd)
        subject.adDidDismissFullScreenContent(presentingAd)
        subject.ad(presentingAd, didFailToPresentFullScreenContentWithError: error)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(spy.didRecordClick)
        XCTAssertTrue(spy.willPresent)
        XCTAssertTrue(spy.willDismiss)
        XCTAssertTrue(spy.didDismiss)
        XCTAssertEqual(spy.presentFailureCode, 41)
    }

    func testTrackingFullScreenDelegateCallbacksDoNotCrashWithoutDelegate() {
        let subject = RCAdMobFullScreenContentDelegate(
            delegate: nil,
            placement: "interstitial_home",
            adUnitID: "test_unit",
            adFormat: .interstitial,
            responseInfoProvider: { nil }
        )
        let presentingAd = PresentingAdStub()
        let error = NSError(domain: "test", code: 2)

        subject.adDidRecordImpression(presentingAd)
        subject.adDidRecordClick(presentingAd)
        subject.adWillPresentFullScreenContent(presentingAd)
        subject.adWillDismissFullScreenContent(presentingAd)
        subject.adDidDismissFullScreenContent(presentingAd)
        subject.ad(presentingAd, didFailToPresentFullScreenContentWithError: error)
    }

    func testTrackingFullScreenDelegateForwardsAllCallbacksForAppOpenFormat() {
        let spy = FullScreenDelegateSpy()
        let subject = RCAdMobFullScreenContentDelegate(
            delegate: spy,
            placement: "app_open_launch",
            adUnitID: "app_open_test_unit",
            adFormat: .appOpen,
            responseInfoProvider: { nil }
        )
        let presentingAd = PresentingAdStub()
        let error = NSError(domain: "test", code: 11)

        subject.adDidRecordImpression(presentingAd)
        subject.adDidRecordClick(presentingAd)
        subject.adWillPresentFullScreenContent(presentingAd)
        subject.adWillDismissFullScreenContent(presentingAd)
        subject.adDidDismissFullScreenContent(presentingAd)
        subject.ad(presentingAd, didFailToPresentFullScreenContentWithError: error)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(spy.didRecordClick)
        XCTAssertTrue(spy.willPresent)
        XCTAssertTrue(spy.willDismiss)
        XCTAssertTrue(spy.didDismiss)
        XCTAssertEqual(spy.presentFailureCode, 11)
    }

    func testTrackingFullScreenDelegateForwardsAllCallbacksForRewardedFormat() {
        let spy = FullScreenDelegateSpy()
        let subject = RCAdMobFullScreenContentDelegate(
            delegate: spy,
            placement: "rewarded_bonus",
            adUnitID: "rewarded_test_unit",
            adFormat: .rewarded,
            responseInfoProvider: { nil }
        )
        let presentingAd = PresentingAdStub()
        let error = NSError(domain: "test", code: 21)

        subject.adDidRecordImpression(presentingAd)
        subject.adDidRecordClick(presentingAd)
        subject.adWillPresentFullScreenContent(presentingAd)
        subject.adWillDismissFullScreenContent(presentingAd)
        subject.adDidDismissFullScreenContent(presentingAd)
        subject.ad(presentingAd, didFailToPresentFullScreenContentWithError: error)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(spy.didRecordClick)
        XCTAssertTrue(spy.willPresent)
        XCTAssertTrue(spy.willDismiss)
        XCTAssertTrue(spy.didDismiss)
        XCTAssertEqual(spy.presentFailureCode, 21)
    }

    func testTrackingFullScreenDelegateForwardsAllCallbacksForRewardedInterstitialFormat() {
        let spy = FullScreenDelegateSpy()
        let subject = RCAdMobFullScreenContentDelegate(
            delegate: spy,
            placement: "rewarded_interstitial_bridge",
            adUnitID: "rewarded_interstitial_test_unit",
            adFormat: .rewardedInterstitial,
            responseInfoProvider: { nil }
        )
        let presentingAd = PresentingAdStub()
        let error = NSError(domain: "test", code: 31)

        subject.adDidRecordImpression(presentingAd)
        subject.adDidRecordClick(presentingAd)
        subject.adWillPresentFullScreenContent(presentingAd)
        subject.adWillDismissFullScreenContent(presentingAd)
        subject.adDidDismissFullScreenContent(presentingAd)
        subject.ad(presentingAd, didFailToPresentFullScreenContentWithError: error)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(spy.didRecordClick)
        XCTAssertTrue(spy.willPresent)
        XCTAssertTrue(spy.willDismiss)
        XCTAssertTrue(spy.didDismiss)
        XCTAssertEqual(spy.presentFailureCode, 31)
    }

    func testDidFailToPresentFullScreenContentDoesNotTriggerTracking() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let spy = FullScreenDelegateSpy()
        let subject = RCAdMobFullScreenContentDelegate(
            rcAdMob: rcAdMob,
            delegate: spy,
            placement: "interstitial_home",
            adUnitID: "test_unit",
            adFormat: .interstitial,
            responseInfoProvider: { nil }
        )
        let presentingAd = PresentingAdStub()
        let error = NSError(domain: "test", code: 99)

        subject.ad(presentingAd, didFailToPresentFullScreenContentWithError: error)

        XCTAssertTrue(mockTracker.calls.isEmpty)
        XCTAssertEqual(spy.presentFailureCode, 99)
    }

    func testTrackingFullScreenDelegateReadsResponseInfoOnlyForTrackedCallbacks() {
        var responseInfoReads = 0
        let subject = RCAdMobFullScreenContentDelegate(
            delegate: nil,
            placement: nil,
            adUnitID: "",
            adFormat: .interstitial,
            responseInfoProvider: {
                responseInfoReads += 1
                return nil
            }
        )
        let presentingAd = PresentingAdStub()
        let error = NSError(domain: "test", code: 3)

        subject.adDidRecordImpression(presentingAd)
        subject.adDidRecordClick(presentingAd)
        subject.adWillPresentFullScreenContent(presentingAd)
        subject.adWillDismissFullScreenContent(presentingAd)
        subject.adDidDismissFullScreenContent(presentingAd)
        subject.ad(presentingAd, didFailToPresentFullScreenContentWithError: error)

        XCTAssertEqual(responseInfoReads, 2)
    }

}

@available(iOS 15.0, *)
private final class FullScreenDelegateSpy: NSObject, FullScreenContentDelegate {

    var didRecordImpression = false
    var didRecordClick = false
    var willPresent = false
    var willDismiss = false
    var didDismiss = false
    var presentFailureCode: Int?

    func adDidRecordImpression(_ presentingAd: any FullScreenPresentingAd) {
        self.didRecordImpression = true
    }

    func adDidRecordClick(_ presentingAd: any FullScreenPresentingAd) {
        self.didRecordClick = true
    }

    func adWillPresentFullScreenContent(_ presentingAd: any FullScreenPresentingAd) {
        self.willPresent = true
    }

    func adWillDismissFullScreenContent(_ presentingAd: any FullScreenPresentingAd) {
        self.willDismiss = true
    }

    func adDidDismissFullScreenContent(_ presentingAd: any FullScreenPresentingAd) {
        self.didDismiss = true
    }

    func ad(
        _ presentingAd: any FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        self.presentFailureCode = (error as NSError).code
    }

}

@available(iOS 15.0, *)
private final class PresentingAdStub: NSObject, FullScreenPresentingAd {
    weak var fullScreenContentDelegate: FullScreenContentDelegate?
}

#endif
