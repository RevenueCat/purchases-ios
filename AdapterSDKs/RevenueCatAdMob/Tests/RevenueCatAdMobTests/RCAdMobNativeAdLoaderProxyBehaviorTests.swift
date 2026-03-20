// swiftlint:disable file_length
import Foundation
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
// swiftlint:disable:next type_body_length
final class RCAdMobNativeAdLoaderProxyBehaviorTests: RCAdMobTestCase {

    func testLoadAndTrackInstallsProxyAndForwardsFailAndFinishLoading() {
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "feed",
            nativeAdDelegate: nil
        )

        XCTAssertFalse(adLoader.delegate === spy)

        let loaderDelegate = adLoader.delegate
        loaderDelegate?.adLoader(adLoader, didFailToReceiveAdWithError: NSError(domain: "test", code: 1))
        loaderDelegate?.adLoaderDidFinishLoading?(adLoader)

        XCTAssertTrue(spy.didFailToReceive)
        XCTAssertTrue(spy.didFinishLoading)
    }

    func testLoadAndTrackProxyForwardsNativeLoadCallback() {
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "feed",
            nativeAdDelegate: nil
        )

        let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
        nativeDelegate?.adLoader(adLoader, didReceive: Self.makeNativeAdPlaceholder())

        XCTAssertTrue(spy.didReceiveNative)
    }

    func testLoadAndTrackProxyWrapsPaidHandlerAndPreservesExistingOne() {
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        var existingPaidHandlerCalls = 0
        let nativeBacking = NativeAdPlaceholder()
        nativeBacking.paidEventHandler = { _ in existingPaidHandlerCalls += 1 }

        adLoader.loadAndTrack(
            Request(),
            placement: "feed",
            nativeAdDelegate: nil
        )

        let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
        nativeDelegate?.adLoader(adLoader, didReceive: Self.makeNativeAdPlaceholder(backing: nativeBacking))

        XCTAssertNotNil(nativeBacking.paidEventHandler)

        nativeBacking.paidEventHandler?(Self.makeAdValuePlaceholder())
        XCTAssertEqual(existingPaidHandlerCalls, 1)
    }

    func testLoadAndTrackUsesExplicitNativeDelegateOverExistingNativeAdDelegate() {
        let adLoader = Self.makeAdLoader()
        let loaderSpy = AdLoaderDelegateSpy()
        let existingNativeDelegate = NativeDelegateSpy()
        let explicitNativeDelegate = NativeDelegateSpy()
        adLoader.delegate = loaderSpy

        let nativeBacking = NativeAdPlaceholder()
        nativeBacking.delegate = existingNativeDelegate

        adLoader.loadAndTrack(
            Request(),
            placement: "feed",
            nativeAdDelegate: explicitNativeDelegate
        )

        let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
        let nativeAd = Self.makeNativeAdPlaceholder(backing: nativeBacking)
        nativeDelegate?.adLoader(adLoader, didReceive: nativeAd)

        nativeBacking.delegate?.nativeAdWillPresentScreen?(nativeAd)

        XCTAssertTrue(explicitNativeDelegate.didPresentScreen)
        XCTAssertFalse(existingNativeDelegate.didPresentScreen)
    }

    func testLoadAndTrackFallsBackToExistingNativeAdDelegateWhenNoExplicitDelegate() {
        let adLoader = Self.makeAdLoader()
        let loaderSpy = AdLoaderDelegateSpy()
        let existingNativeDelegate = NativeDelegateSpy()
        adLoader.delegate = loaderSpy

        let nativeBacking = NativeAdPlaceholder()
        nativeBacking.delegate = existingNativeDelegate

        adLoader.loadAndTrack(
            Request(),
            placement: "feed",
            nativeAdDelegate: nil
        )

        let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
        let nativeAd = Self.makeNativeAdPlaceholder(backing: nativeBacking)
        nativeDelegate?.adLoader(adLoader, didReceive: nativeAd)

        nativeBacking.delegate?.nativeAdWillPresentScreen?(nativeAd)

        XCTAssertTrue(existingNativeDelegate.didPresentScreen)
    }

    private static func makeAdLoader() -> AdLoader {
        return AdLoader(
            adUnitID: "native_unit",
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
    }

    func testPlaceholderSelectorsMatchRealNativeAdClass() {
        let nativeAdClass: AnyClass = GoogleMobileAds.NativeAd.self
        for sel in [
            #selector(getter: NativeAdPlaceholder.responseInfo),
            #selector(getter: NativeAdPlaceholder.paidEventHandler),
            #selector(setter: NativeAdPlaceholder.paidEventHandler),
            #selector(getter: NativeAdPlaceholder.delegate),
            #selector(setter: NativeAdPlaceholder.delegate)
        ] {
            XCTAssertTrue(
                nativeAdClass.instancesRespond(to: sel),
                "NativeAd no longer responds to \(sel) — update NativeAdPlaceholder to match the new SDK."
            )
        }
    }

    func testPlaceholderSelectorsMatchRealAdValueClass() {
        let adValueClass: AnyClass = GoogleMobileAds.AdValue.self
        for sel in [
            NSSelectorFromString("value"),
            #selector(getter: AdValuePlaceholder.currencyCode),
            #selector(getter: AdValuePlaceholder.precision)
        ] {
            XCTAssertTrue(
                adValueClass.instancesRespond(to: sel),
                "AdValue no longer responds to \(sel) — update AdValuePlaceholder to match the new SDK."
            )
        }
    }

    // MARK: - Tracking verification (uses injectable rcAdMob)

    func testLoadAndTrackTracksLoadedOnNativeAdReceived() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "native_feed",
            nativeAdDelegate: nil,
            rcAdMob: rcAdMob
        )

        let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
        nativeDelegate?.adLoader(adLoader, didReceive: Self.makeNativeAdPlaceholder())

        XCTAssertEqual(mockTracker.calls.count, 1)
        XCTAssertEqual(mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdLoaded",
            adFormat: "native",
            placement: "native_feed",
            adUnitId: "native_unit"
        ))
    }

    func testLoadAndTrackTracksFailedToLoadOnError() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "native_feed",
            nativeAdDelegate: nil,
            rcAdMob: rcAdMob
        )

        let loaderDelegate = adLoader.delegate
        loaderDelegate?.adLoader(
            adLoader,
            didFailToReceiveAdWithError: NSError(domain: "com.google.ads", code: 3)
        )

        XCTAssertEqual(mockTracker.calls.count, 1)
        XCTAssertEqual(mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdFailedToLoad",
            adFormat: "native",
            placement: "native_feed",
            adUnitId: "native_unit"
        ))
    }

    func testLoadAndTrackTracksRevenueOnPaidEvent() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "native_feed",
            nativeAdDelegate: nil,
            rcAdMob: rcAdMob
        )

        let nativeBacking = NativeAdPlaceholder()
        let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
        nativeDelegate?.adLoader(adLoader, didReceive: Self.makeNativeAdPlaceholder(backing: nativeBacking))

        let callsBeforePaid = mockTracker.calls.count

        nativeBacking.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertEqual(mockTracker.calls.count, callsBeforePaid + 1)
        XCTAssertEqual(mockTracker.calls.last, MockAdTracker.Call(
            method: "trackAdRevenue",
            adFormat: "native",
            placement: "native_feed",
            adUnitId: "native_unit"
        ))
    }

    func testLoadAndTrackDoesNotTrackWhenNotConfigured() {
        let mockTracker = MockAdTracker()
        mockTracker.isConfigured = false
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "native_feed",
            nativeAdDelegate: nil,
            rcAdMob: rcAdMob
        )

        let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
        nativeDelegate?.adLoader(adLoader, didReceive: Self.makeNativeAdPlaceholder())

        XCTAssertTrue(mockTracker.calls.isEmpty)
    }

    func testLoadAndTrackTracksNativeImpressionAndClickViaDelegateProxy() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "native_feed",
            nativeAdDelegate: nil,
            rcAdMob: rcAdMob
        )

        let nativeBacking = NativeAdPlaceholder()
        let nativeAd = Self.makeNativeAdPlaceholder(backing: nativeBacking)
        let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
        nativeDelegate?.adLoader(adLoader, didReceive: nativeAd)

        let callsBeforeEvents = mockTracker.calls.count

        nativeBacking.delegate?.nativeAdDidRecordImpression?(nativeAd)
        nativeBacking.delegate?.nativeAdDidRecordClick?(nativeAd)

        XCTAssertEqual(mockTracker.calls.count, callsBeforeEvents + 2)
        XCTAssertEqual(mockTracker.calls[callsBeforeEvents], MockAdTracker.Call(
            method: "trackAdDisplayed",
            adFormat: "native",
            placement: "native_feed",
            adUnitId: "native_unit"
        ))
        XCTAssertEqual(mockTracker.calls[callsBeforeEvents + 1], MockAdTracker.Call(
            method: "trackAdOpened",
            adFormat: "native",
            placement: "native_feed",
            adUnitId: "native_unit"
        ))
    }

    func testLoadAndTrackRevenueEventContainsCorrectRevenueData() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "native_feed",
            nativeAdDelegate: nil,
            rcAdMob: rcAdMob
        )

        let nativeBacking = NativeAdPlaceholder()
        let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
        nativeDelegate?.adLoader(adLoader, didReceive: Self.makeNativeAdPlaceholder(backing: nativeBacking))

        nativeBacking.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertEqual(mockTracker.revenueData.count, 1)
        let revenue = mockTracker.revenueData[0]
        XCTAssertEqual(revenue.revenueMicros, 1_000_000)
        XCTAssertEqual(revenue.currency, "USD")
        XCTAssertEqual(revenue.precision, AdRevenue.Precision.unknown)
        XCTAssertEqual(revenue.adFormat, AdFormat.native)
        XCTAssertEqual(revenue.placement, "native_feed")
        XCTAssertEqual(revenue.adUnitId, "native_unit")
        XCTAssertEqual(revenue.mediatorName, MediatorName.adMob)
    }

    func testLoadAndTrackFailedToLoadCapturesErrorCode() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "native_feed",
            nativeAdDelegate: nil,
            rcAdMob: rcAdMob
        )

        adLoader.delegate?.adLoader(
            adLoader,
            didFailToReceiveAdWithError: NSError(domain: "com.google.ads", code: 7)
        )

        XCTAssertEqual(mockTracker.failedToLoadData.count, 1)
        XCTAssertEqual(mockTracker.failedToLoadData[0].mediatorErrorCode, 7)
    }

    func testPaidHandlerWhenNativeAdDeallocatedSkipsTrackingButCallsExistingHandler() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let adLoader = Self.makeAdLoader()
        let spy = AdLoaderDelegateSpy()
        adLoader.delegate = spy

        adLoader.loadAndTrack(
            Request(),
            placement: "native_feed",
            nativeAdDelegate: nil,
            rcAdMob: rcAdMob
        )

        var existingHandlerCalled = false
        var capturedHandler: ((GoogleMobileAds.AdValue) -> Void)?
        var callsAfterLoad = 0

        do {
            let backing = NativeAdPlaceholder()
            backing.paidEventHandler = { _ in existingHandlerCalled = true }

            let nativeDelegate = adLoader.delegate as? NativeAdLoaderDelegate
            nativeDelegate?.adLoader(adLoader, didReceive: Self.makeNativeAdPlaceholder(backing: backing))

            capturedHandler = backing.paidEventHandler
            callsAfterLoad = mockTracker.calls.count
        }

        capturedHandler?(Self.makeAdValuePlaceholder())

        XCTAssertTrue(existingHandlerCalled)
        XCTAssertEqual(
            mockTracker.calls.filter { $0.method == "trackAdRevenue" }.count,
            0,
            "Revenue should not be tracked when the native ad has been deallocated"
        )
        XCTAssertEqual(mockTracker.calls.count, callsAfterLoad)
    }

    // MARK: - Helpers

    private static func makeNativeAdPlaceholder(
        backing: NativeAdPlaceholder = NativeAdPlaceholder()
    ) -> GoogleMobileAds.NativeAd {
        return unsafeBitCast(backing, to: GoogleMobileAds.NativeAd.self)
    }

    private static func makeAdValuePlaceholder() -> GoogleMobileAds.AdValue {
        return unsafeBitCast(AdValuePlaceholder(), to: GoogleMobileAds.AdValue.self)
    }

}

@available(iOS 15.0, *)
private final class AdLoaderDelegateSpy: NSObject, AdLoaderDelegate, NativeAdLoaderDelegate {

    var didFailToReceive = false
    var didFinishLoading = false
    var didReceiveNative = false

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        self.didFailToReceive = true
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        self.didFinishLoading = true
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.didReceiveNative = true
    }

}

@available(iOS 15.0, *)
private final class NativeDelegateSpy: NSObject, GoogleMobileAds.NativeAdDelegate {
    var didPresentScreen = false

    func nativeAdWillPresentScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.didPresentScreen = true
    }
}

@available(iOS 15.0, *)
private final class NativeAdPlaceholder: NSObject {
    @objc var responseInfo: GoogleMobileAds.ResponseInfo? { nil }
    @objc var paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?
    @objc var delegate: GoogleMobileAds.NativeAdDelegate?
}

@available(iOS 15.0, *)
private final class AdValuePlaceholder: NSObject {
    @objc var value: NSDecimalNumber { NSDecimalNumber(value: 1) }
    @objc var currencyCode: String { "USD" }
    @objc var precision: Int { 0 }
}

#endif
