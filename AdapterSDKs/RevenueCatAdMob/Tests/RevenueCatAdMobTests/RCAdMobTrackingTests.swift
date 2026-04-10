// swiftlint:disable file_length
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
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
    private(set) var revenueData: [AdRevenue] = []
    private(set) var failedToLoadData: [AdFailedToLoad] = []

    private(set) var loadedData: [AdLoaded] = []
    private(set) var displayedData: [AdDisplayed] = []
    private(set) var openedData: [AdOpened] = []

    func trackAdLoaded(_ data: AdLoaded) {
        self.calls.append(Call(
            method: "trackAdLoaded",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
        self.loadedData.append(data)
    }

    func trackAdDisplayed(_ data: AdDisplayed) {
        self.calls.append(Call(
            method: "trackAdDisplayed",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
        self.displayedData.append(data)
    }

    func trackAdOpened(_ data: AdOpened) {
        self.calls.append(Call(
            method: "trackAdOpened",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
        self.openedData.append(data)
    }

    func trackAdRevenue(_ data: AdRevenue) {
        self.calls.append(Call(
            method: "trackAdRevenue",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
        self.revenueData.append(data)
    }

    func trackAdFailedToLoad(_ data: AdFailedToLoad) {
        self.calls.append(Call(
            method: "trackAdFailedToLoad",
            adFormat: data.adFormat.rawValue,
            placement: data.placement,
            adUnitId: data.adUnitId
        ))
        self.failedToLoadData.append(data)
    }
}

// MARK: - Core RCAdMob tracking tests

@available(iOS 15.0, *)
// swiftlint:disable:next type_body_length
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

    func testTrackRevenueCallsTrackerWithCorrectRevenueData() {
        self.rcAdMob.trackRevenue(
            placement: "reward_screen",
            adUnitID: "ca-app-pub-reward",
            adFormat: .rewarded,
            responseInfo: nil,
            adValue: Self.makeAdValuePlaceholder()
        )

        XCTAssertEqual(self.mockTracker.revenueData.count, 1)
        let revenue = self.mockTracker.revenueData[0]
        XCTAssertEqual(revenue.revenueMicros, 2500)
        XCTAssertEqual(revenue.currency, "EUR")
        XCTAssertEqual(revenue.precision, AdRevenue.Precision.exact)
        XCTAssertEqual(revenue.adFormat, AdFormat.rewarded)
        XCTAssertEqual(revenue.placement, "reward_screen")
        XCTAssertEqual(revenue.adUnitId, "ca-app-pub-reward")
        XCTAssertEqual(revenue.mediatorName, MediatorName.adMob)
        XCTAssertEqual(revenue.networkName, "")
        XCTAssertEqual(revenue.impressionId, "")
    }

    func testTrackRevenueNoOpsWhenNotConfigured() {
        self.mockTracker.isConfigured = false

        self.rcAdMob.trackRevenue(
            placement: "test",
            adUnitID: "unit",
            adFormat: .interstitial,
            responseInfo: nil,
            adValue: Self.makeAdValuePlaceholder()
        )

        XCTAssertTrue(self.mockTracker.revenueData.isEmpty)
    }

    func testHandleLoadOutcomeOnSuccessPaidHandlerTracksRevenue() {
        let fakeAd = FakeFullScreenAd()
        let context = FullScreenLoadContext(
            placement: "reward_screen",
            adUnitID: "ca-app-pub-reward",
            adFormat: .rewarded,
            fullScreenContentDelegate: nil,
            paidEventHandler: nil,
            responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(
            loadedAd: fakeAd, error: nil, context: context
        ) { _, _ in }

        fakeAd.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertEqual(self.mockTracker.revenueData.count, 1)
        let revenue = self.mockTracker.revenueData[0]
        XCTAssertEqual(revenue.revenueMicros, 2500)
        XCTAssertEqual(revenue.currency, "EUR")
        XCTAssertEqual(revenue.precision, AdRevenue.Precision.exact)
        XCTAssertEqual(revenue.adFormat, AdFormat.rewarded)
        XCTAssertEqual(revenue.placement, "reward_screen")
        XCTAssertEqual(revenue.adUnitId, "ca-app-pub-reward")
    }

    func testHandleLoadOutcomeOnSuccessPaidHandlerForwardsToUserHandler() {
        let fakeAd = FakeFullScreenAd()
        var userHandlerCalled = false
        let context = FullScreenLoadContext(
            placement: "reward_screen",
            adUnitID: "ca-app-pub-reward",
            adFormat: .rewarded,
            fullScreenContentDelegate: nil,
            paidEventHandler: { _ in userHandlerCalled = true },
            responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(
            loadedAd: fakeAd, error: nil, context: context
        ) { _, _ in }

        fakeAd.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertTrue(userHandlerCalled)
        XCTAssertEqual(self.mockTracker.revenueData.count, 1)
    }

    func testTrackFailedToLoadCapturesErrorCode() {
        let error = NSError(domain: "com.google.ads", code: 42, userInfo: nil)
        self.rcAdMob.trackFailedToLoad(
            placement: "feed",
            adUnitID: "ca-app-pub-456",
            adFormat: .banner,
            error: error
        )

        XCTAssertEqual(self.mockTracker.failedToLoadData.count, 1)
        XCTAssertEqual(self.mockTracker.failedToLoadData[0].mediatorErrorCode, 42)
    }

    func testTrackLoadedExtractsResponseInfoFields() {
        self.rcAdMob.trackLoaded(
            responseInfo: Self.makeResponseInfoPlaceholder(),
            placement: "home",
            adUnitID: "ca-app-pub-123",
            adFormat: .interstitial
        )

        XCTAssertEqual(self.mockTracker.loadedData.count, 1)
        let loaded = self.mockTracker.loadedData[0]
        XCTAssertEqual(loaded.networkName, "GADMAdapterTestNetwork")
        XCTAssertEqual(loaded.impressionId, "resp-id-abc")
    }

    func testTrackRevenueExtractsResponseInfoFields() {
        self.rcAdMob.trackRevenue(
            placement: "home",
            adUnitID: "ca-app-pub-123",
            adFormat: .interstitial,
            responseInfo: Self.makeResponseInfoPlaceholder(),
            adValue: Self.makeAdValuePlaceholder()
        )

        XCTAssertEqual(self.mockTracker.revenueData.count, 1)
        let revenue = self.mockTracker.revenueData[0]
        XCTAssertEqual(revenue.networkName, "GADMAdapterTestNetwork")
        XCTAssertEqual(revenue.impressionId, "resp-id-abc")
    }

    func testHandleLoadOutcomeForwardsCallbacksToUserDelegate() {
        let fakeAd = FakeFullScreenAd()
        let spy = FullScreenContentDelegateSpy()
        let context = FullScreenLoadContext(
            placement: "test",
            adUnitID: "unit",
            adFormat: .interstitial,
            fullScreenContentDelegate: spy,
            paidEventHandler: nil,
            responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(
            loadedAd: fakeAd, error: nil, context: context
        ) { _, _ in }

        let presentingAd = FakeFullScreenPresentingAd()
        fakeAd.fullScreenContentDelegate?.adDidRecordImpression?(presentingAd)
        fakeAd.fullScreenContentDelegate?.adDidRecordClick?(presentingAd)
        fakeAd.fullScreenContentDelegate?.adWillPresentFullScreenContent?(presentingAd)
        fakeAd.fullScreenContentDelegate?.adWillDismissFullScreenContent?(presentingAd)
        fakeAd.fullScreenContentDelegate?.adDidDismissFullScreenContent?(presentingAd)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(spy.didRecordClick)
        XCTAssertTrue(spy.willPresent)
        XCTAssertTrue(spy.willDismiss)
        XCTAssertTrue(spy.didDismiss)
    }

    func testNilAdUnitIDMapsToEmptyString() {
        self.rcAdMob.trackLoaded(
            responseInfo: nil,
            placement: "test",
            adUnitID: nil,
            adFormat: .banner
        )

        XCTAssertEqual(self.mockTracker.loadedData.count, 1)
        XCTAssertEqual(self.mockTracker.loadedData[0].adUnitId, "")
    }

    // MARK: - Show-time placement override

    func testShowTimePlacementOverrideIsUsedInRevenueEvent() {
        // Verifies that the paidEventHandler closure (set up at load time) reads placement
        // from the delegate at fire time, so a show-time override is reflected in revenue tracking.
        let fakeAd = FakeFullScreenAd()
        let context = FullScreenLoadContext(
            placement: "load_time_placement",
            adUnitID: "ca-app-pub-test",
            adFormat: .rewarded,
            fullScreenContentDelegate: nil,
            paidEventHandler: nil,
            responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(loadedAd: fakeAd, error: nil, context: context) { _, _ in }
        (fakeAd.fullScreenContentDelegate as? RCAdMobFullScreenContentDelegate)?.placement = "show_time_placement"
        fakeAd.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertEqual(self.mockTracker.revenueData.count, 1)
        XCTAssertEqual(self.mockTracker.revenueData[0].placement, "show_time_placement")
    }

    // MARK: - updateFullScreenContentDelegate

    func testUpdateDelegateAfterLoadUpdatesWrapper() {
        let fakeAd = FakeFullScreenAd()
        let context = FullScreenLoadContext(
            placement: "test", adUnitID: "ca-app-pub-test", adFormat: .interstitial,
            fullScreenContentDelegate: nil, paidEventHandler: nil, responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(loadedAd: fakeAd, error: nil, context: context) { _, _ in }

        let spy = FullScreenContentDelegateSpy()
        self.rcAdMob.updateFullScreenContentDelegate(on: fakeAd, newDelegate: spy)

        let presentingAd = FakeFullScreenPresentingAd()
        fakeAd.fullScreenContentDelegate?.adDidRecordImpression?(presentingAd)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertEqual(self.mockTracker.displayedData.count, 1)
    }

    func testUpdateDelegateAfterDirectOverwriteRestoresWrapper() {
        let fakeAd = FakeFullScreenAd()
        let context = FullScreenLoadContext(
            placement: "test", adUnitID: "ca-app-pub-test", adFormat: .interstitial,
            fullScreenContentDelegate: nil, paidEventHandler: nil, responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(loadedAd: fakeAd, error: nil, context: context) { _, _ in }

        // Simulate developer overwriting the delegate directly
        fakeAd.fullScreenContentDelegate = FullScreenContentDelegateSpy()

        let spy = FullScreenContentDelegateSpy()
        self.rcAdMob.updateFullScreenContentDelegate(on: fakeAd, newDelegate: spy)

        let presentingAd = FakeFullScreenPresentingAd()
        fakeAd.fullScreenContentDelegate?.adDidRecordImpression?(presentingAd)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(fakeAd.fullScreenContentDelegate is RCAdMobFullScreenContentDelegate)
        XCTAssertEqual(self.mockTracker.displayedData.count, 1)
    }

    func testUpdateDelegateWithNilClearsUserDelegate() {
        let fakeAd = FakeFullScreenAd()
        let initialSpy = FullScreenContentDelegateSpy()
        let context = FullScreenLoadContext(
            placement: "test", adUnitID: "ca-app-pub-test", adFormat: .interstitial,
            fullScreenContentDelegate: initialSpy, paidEventHandler: nil, responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(loadedAd: fakeAd, error: nil, context: context) { _, _ in }

        self.rcAdMob.updateFullScreenContentDelegate(on: fakeAd, newDelegate: nil)

        let presentingAd = FakeFullScreenPresentingAd()
        fakeAd.fullScreenContentDelegate?.adDidRecordImpression?(presentingAd)

        XCTAssertFalse(initialSpy.didRecordImpression)
        XCTAssertEqual(self.mockTracker.displayedData.count, 1)
    }

    func testUpdateDelegateWithoutLoadAndTrackFallsBackToDirectAssignment() {
        let fakeAd = FakeFullScreenAd()
        let spy = FullScreenContentDelegateSpy()

        self.rcAdMob.updateFullScreenContentDelegate(on: fakeAd, newDelegate: spy)

        XCTAssertTrue(fakeAd.fullScreenContentDelegate === spy)
    }

    func testPaidEventHandlerStillWorksAfterDelegateUpdate() {
        let fakeAd = FakeFullScreenAd()
        let context = FullScreenLoadContext(
            placement: "original_placement", adUnitID: "ca-app-pub-test", adFormat: .rewarded,
            fullScreenContentDelegate: nil, paidEventHandler: nil, responseInfo: nil
        )

        self.rcAdMob.handleLoadOutcome(loadedAd: fakeAd, error: nil, context: context) { _, _ in }

        let spy = FullScreenContentDelegateSpy()
        self.rcAdMob.updateFullScreenContentDelegate(on: fakeAd, newDelegate: spy)

        fakeAd.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertEqual(self.mockTracker.revenueData.count, 1)
        XCTAssertEqual(self.mockTracker.revenueData[0].placement, "original_placement")
    }

    // MARK: - Helpers

    private static func makeAdValuePlaceholder() -> GoogleMobileAds.AdValue {
        return unsafeBitCast(TrackingTestAdValuePlaceholder(), to: GoogleMobileAds.AdValue.self)
    }

    private static func makeResponseInfoPlaceholder() -> GoogleMobileAds.ResponseInfo {
        return unsafeBitCast(
            ResponseInfoPlaceholder(
                identifier: "resp-id-abc",
                networkClassName: "GADMAdapterTestNetwork"
            ),
            to: GoogleMobileAds.ResponseInfo.self
        )
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
        let fakeBanner = GoogleMobileAds.BannerView()
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
        let fakeBanner = GoogleMobileAds.BannerView()
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
        let fakeBanner = GoogleMobileAds.BannerView()
        fakeBanner.adUnitID = "ca-app-pub-banner"

        bannerDelegate.bannerViewDidRecordImpression(fakeBanner)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdDisplayed")
    }

    func testBannerDelegateTracksClickViaTracker() {
        let bannerDelegate = RCAdMobBannerViewDelegate(
            rcAdMob: self.rcAdMob, delegate: nil, placement: "banner_mid"
        )
        let fakeBanner = GoogleMobileAds.BannerView()
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
        let fakeNativeAd = GoogleMobileAds.NativeAd()

        nativeDelegate.nativeAdDidRecordImpression(fakeNativeAd)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdDisplayed")
        XCTAssertEqual(self.mockTracker.calls.first?.adFormat, AdFormat.native.rawValue)
    }

    func testNativeDelegateTracksClickViaTracker() {
        let nativeDelegate = RCAdMobNativeAdDelegate(
            rcAdMob: self.rcAdMob, delegate: nil, placement: "native_feed", adUnitID: "ca-app-pub-native"
        )
        let fakeNativeAd = GoogleMobileAds.NativeAd()

        nativeDelegate.nativeAdDidRecordClick(fakeNativeAd)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdOpened")
        XCTAssertEqual(self.mockTracker.calls.first?.adFormat, AdFormat.native.rawValue)
    }
}

// MARK: - Test doubles

@available(iOS 15.0, *)
private final class FakeFullScreenAd: NSObject, RCFullScreenAdTracking {
    var fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?
    var paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?
}

@available(iOS 15.0, *)
private final class FakeFullScreenPresentingAd: NSObject, GoogleMobileAds.FullScreenPresentingAd {
    var fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?
    var responseInfo: GoogleMobileAds.ResponseInfo? { nil }
}

@available(iOS 15.0, *)
private final class TrackingTestAdValuePlaceholder: NSObject {
    @objc var value: NSDecimalNumber { NSDecimalNumber(string: "0.0025") }
    @objc var currencyCode: String { "EUR" }
    @objc var precision: Int { 3 }
}

@available(iOS 15.0, *)
private final class AdNetworkResponseInfoPlaceholder: NSObject {
    @objc let adNetworkClassName: String
    init(className: String) {
        self.adNetworkClassName = className
    }
}

@available(iOS 15.0, *)
private final class ResponseInfoPlaceholder: NSObject {
    @objc let responseIdentifier: String?
    @objc let loadedAdNetworkResponseInfo: AnyObject?

    init(identifier: String, networkClassName: String) {
        self.responseIdentifier = identifier
        self.loadedAdNetworkResponseInfo = AdNetworkResponseInfoPlaceholder(className: networkClassName)
    }
}

@available(iOS 15.0, *)
private final class FullScreenContentDelegateSpy: NSObject, GoogleMobileAds.FullScreenContentDelegate {
    var didRecordImpression = false
    var didRecordClick = false
    var willPresent = false
    var willDismiss = false
    var didDismiss = false

    func adDidRecordImpression(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.didRecordImpression = true
    }
    func adDidRecordClick(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.didRecordClick = true
    }
    func adWillPresentFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.willPresent = true
    }
    func adWillDismissFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.willDismiss = true
    }
    func adDidDismissFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.didDismiss = true
    }
}

#endif
