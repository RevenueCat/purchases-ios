// swiftlint:disable file_length
import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class MockAdTracker: AdTracking {
    var isConfigured: Bool = true

    struct Call: Equatable {
        let method: String
        let adFormat: String
        let placement: String?
        let adUnitId: String?
    }

    private(set) var calls: [Call] = []

    func trackAdLoaded(_ data: AdLoaded) {
        self.calls.append(Call(
            method: "trackAdLoaded",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
    }

    func trackAdDisplayed(_ data: AdDisplayed) {
        self.calls.append(Call(
            method: "trackAdDisplayed",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
    }

    func trackAdOpened(_ data: AdOpened) {
        self.calls.append(Call(
            method: "trackAdOpened",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
    }

    func trackAdRevenue(_ data: AdRevenue) {
        self.calls.append(Call(
            method: "trackAdRevenue",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
    }

    func trackAdFailedToLoad(_ data: AdFailedToLoad) {
        self.calls.append(Call(
            method: "trackAdFailedToLoad",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
    }
}

// MARK: - Core RCAdMob tracking tests

@available(iOS 15.0, *)
final class RCAdMobTrackingTests: RCAdMobTestCase {

    private var mockTracker: MockAdTracker!
    private var rcAdMob: RCAdMob!

    override func setUp() {
        super.setUp()
        self.mockTracker = MockAdTracker()
        self.rcAdMob = RCAdMob(tracker: self.mockTracker)
    }

    func testTrackLoadedCallsTrackerWithCorrectData() {
        self.rcAdMob.trackLoaded(
            responseInfo: nil,
            placement: "home_banner",
            adUnitID: "ca-app-pub-123",
            adFormat: .interstitial
        )

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdLoaded",
            adFormat: AdFormat.interstitial.rawValue,
            placement: "home_banner",
            adUnitId: "ca-app-pub-123"
        ))
    }

    func testTrackFailedToLoadCallsTrackerWithCorrectData() {
        let error = NSError(domain: "com.google.ads", code: 3, userInfo: nil)
        self.rcAdMob.trackFailedToLoad(
            placement: "feed",
            adUnitID: "ca-app-pub-456",
            adFormat: .banner,
            error: error
        )

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdFailedToLoad",
            adFormat: AdFormat.banner.rawValue,
            placement: "feed",
            adUnitId: "ca-app-pub-456"
        ))
    }

    func testTrackDisplayedCallsTrackerWithCorrectData() {
        self.rcAdMob.trackDisplayed(
            responseInfo: nil,
            placement: "screen_top",
            adUnitID: "ca-app-pub-789",
            adFormat: .rewarded
        )

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdDisplayed",
            adFormat: AdFormat.rewarded.rawValue,
            placement: "screen_top",
            adUnitId: "ca-app-pub-789"
        ))
    }

    func testTrackOpenedCallsTrackerWithCorrectData() {
        self.rcAdMob.trackOpened(
            responseInfo: nil,
            placement: nil,
            adUnitID: "ca-app-pub-000",
            adFormat: .native
        )

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdOpened",
            adFormat: AdFormat.native.rawValue,
            placement: nil,
            adUnitId: "ca-app-pub-000"
        ))
    }

    func testTrackingNoOpsWhenNotConfigured() {
        self.mockTracker.isConfigured = false
        self.rcAdMob.trackLoaded(
            responseInfo: nil,
            placement: "test",
            adUnitID: "unit",
            adFormat: .interstitial
        )

        XCTAssertTrue(self.mockTracker.calls.isEmpty)
    }

    func testHandleLoadOutcomeOnErrorTracksFailedToLoad() {
        let error = NSError(domain: "com.google.ads", code: 2, userInfo: nil)
        let context = FullScreenLoadContext(
            placement: "test_placement",
            adUnitID: "ca-app-pub-test",
            adFormat: .interstitial,
            fullScreenContentDelegate: nil,
            paidEventHandler: nil,
            responseInfo: nil
        )

        var completionCalled = false
        self.rcAdMob.handleLoadOutcome(
            loadedAd: nil as FakeFullScreenAd?,
            error: error,
            context: context
        ) { loadedAd, completionError in
            XCTAssertNil(loadedAd)
            XCTAssertNotNil(completionError)
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdFailedToLoad",
            adFormat: AdFormat.interstitial.rawValue,
            placement: "test_placement",
            adUnitId: "ca-app-pub-test"
        ))
    }

    func testHandleLoadOutcomeNilAdNilErrorForwardsBothNils() {
        let context = FullScreenLoadContext(
            placement: nil,
            adUnitID: "unit",
            adFormat: .appOpen,
            fullScreenContentDelegate: nil,
            paidEventHandler: nil,
            responseInfo: nil
        )

        var completionCalled = false
        self.rcAdMob.handleLoadOutcome(
            loadedAd: nil as FakeFullScreenAd?,
            error: nil,
            context: context
        ) { loadedAd, completionError in
            XCTAssertNil(loadedAd)
            XCTAssertNil(completionError)
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertTrue(self.mockTracker.calls.isEmpty)
    }

    func testHandleLoadOutcomeOnSuccessTracksLoaded() {
        let fakeAd = FakeFullScreenAd()
        let context = FullScreenLoadContext(
            placement: "reward_screen",
            adUnitID: "ca-app-pub-reward",
            adFormat: .rewarded,
            fullScreenContentDelegate: nil,
            paidEventHandler: nil,
            responseInfo: nil
        )

        var completionCalled = false
        self.rcAdMob.handleLoadOutcome(
            loadedAd: fakeAd,
            error: nil,
            context: context
        ) { loadedAd, completionError in
            XCTAssertNotNil(loadedAd)
            XCTAssertNil(completionError)
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdLoaded",
            adFormat: AdFormat.rewarded.rawValue,
            placement: "reward_screen",
            adUnitId: "ca-app-pub-reward"
        ))
    }

    func testHandleLoadOutcomeOnSuccessInstallsFullScreenDelegate() {
        let fakeAd = FakeFullScreenAd()
        let context = FullScreenLoadContext(
            placement: nil, adUnitID: "unit", adFormat: .interstitial,
            fullScreenContentDelegate: nil, paidEventHandler: nil, responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(
            loadedAd: fakeAd, error: nil, context: context
        ) { _, _ in }

        XCTAssertNotNil(fakeAd.fullScreenContentDelegate)
        XCTAssertTrue(fakeAd.fullScreenContentDelegate is RCAdMobFullScreenContentDelegate)
    }

    func testHandleLoadOutcomeOnSuccessInstallsPaidEventHandler() {
        let fakeAd = FakeFullScreenAd()
        let context = FullScreenLoadContext(
            placement: nil, adUnitID: "unit", adFormat: .interstitial,
            fullScreenContentDelegate: nil, paidEventHandler: nil, responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(
            loadedAd: fakeAd, error: nil, context: context
        ) { _, _ in }

        XCTAssertNotNil(fakeAd.paidEventHandler)
    }
}

// MARK: - Delegate tracking tests

@available(iOS 15.0, *)
final class RCAdMobDelegateTrackingTests: RCAdMobTestCase {

    private var mockTracker: MockAdTracker!
    private var rcAdMob: RCAdMob!

    override func setUp() {
        super.setUp()
        self.mockTracker = MockAdTracker()
        self.rcAdMob = RCAdMob(tracker: self.mockTracker)
    }

    func testBannerDelegateTracksLoadedViaTracker() {
        let bannerDelegate = RCAdMobBannerViewDelegate(
            rcAdMob: self.rcAdMob, delegate: nil, placement: "banner_top"
        )
        let fakeBanner = RCGoogleMobileAds.BannerView()
        fakeBanner.adUnitID = "ca-app-pub-banner"

        bannerDelegate.bannerViewDidReceiveAd(fakeBanner)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdLoaded")
        XCTAssertEqual(self.mockTracker.calls.first?.adFormat, AdFormat.banner.rawValue)
    }

    func testBannerDelegateTracksFailedToLoadViaTracker() {
        let bannerDelegate = RCAdMobBannerViewDelegate(
            rcAdMob: self.rcAdMob, delegate: nil, placement: "banner_bottom"
        )
        let fakeBanner = RCGoogleMobileAds.BannerView()
        fakeBanner.adUnitID = "ca-app-pub-banner"
        let error = NSError(domain: "test", code: 1, userInfo: nil)

        bannerDelegate.bannerView(fakeBanner, didFailToReceiveAdWithError: error)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdFailedToLoad")
    }

    func testBannerDelegateTracksImpressionViaTracker() {
        let bannerDelegate = RCAdMobBannerViewDelegate(
            rcAdMob: self.rcAdMob, delegate: nil, placement: "banner_mid"
        )
        let fakeBanner = RCGoogleMobileAds.BannerView()
        fakeBanner.adUnitID = "ca-app-pub-banner"

        bannerDelegate.bannerViewDidRecordImpression(fakeBanner)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdDisplayed")
    }

    func testBannerDelegateTracksClickViaTracker() {
        let bannerDelegate = RCAdMobBannerViewDelegate(
            rcAdMob: self.rcAdMob, delegate: nil, placement: "banner_mid"
        )
        let fakeBanner = RCGoogleMobileAds.BannerView()
        fakeBanner.adUnitID = "ca-app-pub-banner"

        bannerDelegate.bannerViewDidRecordClick(fakeBanner)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdOpened")
    }

    func testFullScreenDelegateTracksImpressionViaTracker() {
        let fakeAd = FakeFullScreenPresentingAd()
        let delegate = RCAdMobFullScreenContentDelegate(
            rcAdMob: self.rcAdMob,
            delegate: nil,
            placement: "interstitial_mid",
            adUnitID: "ca-app-pub-interstitial",
            adFormat: .interstitial,
            responseInfoProvider: { nil }
        )

        delegate.adDidRecordImpression(fakeAd)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdDisplayed")
        XCTAssertEqual(self.mockTracker.calls.first?.adFormat, AdFormat.interstitial.rawValue)
    }

    func testFullScreenDelegateTracksClickViaTracker() {
        let fakeAd = FakeFullScreenPresentingAd()
        let delegate = RCAdMobFullScreenContentDelegate(
            rcAdMob: self.rcAdMob,
            delegate: nil,
            placement: "interstitial_mid",
            adUnitID: "ca-app-pub-interstitial",
            adFormat: .interstitial,
            responseInfoProvider: { nil }
        )

        delegate.adDidRecordClick(fakeAd)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdOpened")
    }

    func testNativeDelegateTracksImpressionViaTracker() {
        let nativeDelegate = RCAdMobNativeAdDelegate(
            rcAdMob: self.rcAdMob, delegate: nil, placement: "native_feed", adUnitID: "ca-app-pub-native"
        )
        let fakeNativeAd = RCGoogleMobileAds.NativeAd()

        nativeDelegate.nativeAdDidRecordImpression(fakeNativeAd)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdDisplayed")
        XCTAssertEqual(self.mockTracker.calls.first?.adFormat, AdFormat.native.rawValue)
    }

    func testNativeDelegateTracksClickViaTracker() {
        let nativeDelegate = RCAdMobNativeAdDelegate(
            rcAdMob: self.rcAdMob, delegate: nil, placement: "native_feed", adUnitID: "ca-app-pub-native"
        )
        let fakeNativeAd = RCGoogleMobileAds.NativeAd()

        nativeDelegate.nativeAdDidRecordClick(fakeNativeAd)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdOpened")
        XCTAssertEqual(self.mockTracker.calls.first?.adFormat, AdFormat.native.rawValue)
    }
}

// MARK: - Test doubles

@available(iOS 15.0, *)
private final class FakeFullScreenAd: NSObject, RCFullScreenAdTracking {
    var fullScreenContentDelegate: RCGoogleMobileAds.FullScreenContentDelegate?
    var paidEventHandler: ((RCGoogleMobileAds.AdValue) -> Void)?
}

@available(iOS 15.0, *)
private final class FakeFullScreenPresentingAd: NSObject, RCGoogleMobileAds.FullScreenPresentingAd {
    var fullScreenContentDelegate: RCGoogleMobileAds.FullScreenContentDelegate?
    var responseInfo: GoogleMobileAds.ResponseInfo? { nil }
}

#endif
