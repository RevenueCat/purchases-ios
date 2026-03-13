import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) @testable import RevenueCat_AdMob

@available(iOS 15.0, *)
final class RCAdMobNativeDelegateForwardingTests: RCAdMobTestCase {

    func testTrackingNativeDelegateForwardsScreenLifecycleCallbacks() {
        let spy = NativeDelegateSpy()
        let subject = RCAdMobNativeAdDelegate(
            delegate: spy,
            placement: "feed_native",
            adUnitID: "test_unit"
        )
        let nativeAd = Self.makeNativeAdPlaceholder()

        subject.nativeAdDidRecordImpression(nativeAd)
        subject.nativeAdDidRecordClick(nativeAd)
        subject.nativeAdWillPresentScreen(nativeAd)
        subject.nativeAdWillDismissScreen(nativeAd)
        subject.nativeAdDidDismissScreen(nativeAd)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(spy.didRecordClick)
        XCTAssertTrue(spy.willPresent)
        XCTAssertTrue(spy.willDismiss)
        XCTAssertTrue(spy.didDismiss)
    }

    func testTrackingNativeDelegateLifecycleCallbacksDoNotCrashWithoutDelegate() {
        let subject = RCAdMobNativeAdDelegate(
            delegate: nil,
            placement: "feed_native",
            adUnitID: "test_unit"
        )
        let nativeAd = Self.makeNativeAdPlaceholder()

        subject.nativeAdWillPresentScreen(nativeAd)
        subject.nativeAdWillDismissScreen(nativeAd)
        subject.nativeAdDidDismissScreen(nativeAd)
    }

    func testTrackingNativeDelegateImpressionAndClickDoNotCrashWithoutDelegate() {
        let subject = RCAdMobNativeAdDelegate(
            delegate: nil,
            placement: "feed_native",
            adUnitID: "test_unit"
        )
        let nativeAd = Self.makeNativeAdPlaceholder()

        subject.nativeAdDidRecordImpression(nativeAd)
        subject.nativeAdDidRecordClick(nativeAd)
    }

    func testTrackingNativeDelegateReadsResponseInfoOnlyForTrackedCallbacks() {
        let subject = RCAdMobNativeAdDelegate(
            delegate: nil,
            placement: nil,
            adUnitID: ""
        )
        let backing = CountingNativeAdPlaceholder()
        let nativeAd = unsafeBitCast(backing, to: GoogleMobileAds.NativeAd.self)

        subject.nativeAdDidRecordImpression(nativeAd)
        subject.nativeAdDidRecordClick(nativeAd)
        subject.nativeAdWillPresentScreen(nativeAd)
        subject.nativeAdWillDismissScreen(nativeAd)
        subject.nativeAdDidDismissScreen(nativeAd)

        XCTAssertEqual(backing.responseInfoReads, 2)
    }

    private static func makeNativeAdPlaceholder() -> GoogleMobileAds.NativeAd {
        let backing = NativeAdPlaceholder()
        return unsafeBitCast(backing, to: GoogleMobileAds.NativeAd.self)
    }

}

@available(iOS 15.0, *)
private final class NativeDelegateSpy: NSObject, GoogleMobileAds.NativeAdDelegate {

    var didRecordImpression = false
    var didRecordClick = false
    var willPresent = false
    var willDismiss = false
    var didDismiss = false

    func nativeAdDidRecordImpression(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.didRecordImpression = true
    }

    func nativeAdDidRecordClick(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.didRecordClick = true
    }

    func nativeAdWillPresentScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.willPresent = true
    }

    func nativeAdWillDismissScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.willDismiss = true
    }

    func nativeAdDidDismissScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.didDismiss = true
    }

}

@available(iOS 15.0, *)
private final class NativeAdPlaceholder: NSObject {
    @objc var responseInfo: GoogleMobileAds.ResponseInfo? { nil }
}

@available(iOS 15.0, *)
private final class CountingNativeAdPlaceholder: NSObject {
    private(set) var responseInfoReads = 0

    @objc var responseInfo: GoogleMobileAds.ResponseInfo? {
        self.responseInfoReads += 1
        return nil
    }
}

#endif
