// swiftlint:disable file_length
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class MockAdTracker: Tracking.Tracker {
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

// MARK: - Core Tracking.Adapter tracking tests

@MainActor
@available(iOS 15.0, *)
// swiftlint:disable:next type_body_length
final class RCAdMobTrackingTests: RCAdMobTestCase {

    private var mockTracker: MockAdTracker!
    private var adapter: Tracking.Adapter!

    override func setUp() {
        super.setUp()
        self.mockTracker = MockAdTracker()
        self.adapter = Tracking.Adapter(tracker: self.mockTracker)
    }

    func testTrackLoadedCallsTrackerWithCorrectData() {
        self.adapter.trackLoaded(
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
        self.adapter.trackFailedToLoad(
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
        self.adapter.trackDisplayed(
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
        self.adapter.trackOpened(
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
        self.adapter.trackLoaded(
            responseInfo: nil,
            placement: "test",
            adUnitID: "unit",
            adFormat: .interstitial
        )

        XCTAssertTrue(self.mockTracker.calls.isEmpty)
    }

    func testHandleLoadOutcomeOnErrorTracksFailedToLoad() async {
        let error = NSError(domain: "com.google.ads", code: 2, userInfo: nil)
        let context = Tracking.FullScreenLoadContext(
            placement: "test_placement",
            adUnitID: "ca-app-pub-test",
            adFormat: .interstitial,
            fullScreenContentDelegate: nil,
            paidEventHandler: nil
        )

        do {
            let _: FakeFullScreenAd = try await self.adapter.handleLoadOutcome(
                loadAd: { throw error },
                context: context
            )
            XCTFail("Expected error to be thrown")
        } catch let caughtError as NSError {
            XCTAssertEqual(caughtError.code, 2)
        }

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdFailedToLoad",
            adFormat: AdFormat.interstitial.rawValue,
            placement: "test_placement",
            adUnitId: "ca-app-pub-test"
        ))
    }

    func testHandleLoadOutcomeOnSuccessTracksLoaded() async throws {
        let fakeAd = FakeFullScreenAd()
        let context = Tracking.FullScreenLoadContext(
            placement: "reward_screen",
            adUnitID: "ca-app-pub-reward",
            adFormat: .rewarded,
            fullScreenContentDelegate: nil,
            paidEventHandler: nil
        )

        let result = try await self.adapter.handleLoadOutcome(
            loadAd: { fakeAd },
            context: context
        )

        XCTAssertTrue(result === fakeAd)
        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first, MockAdTracker.Call(
            method: "trackAdLoaded",
            adFormat: AdFormat.rewarded.rawValue,
            placement: "reward_screen",
            adUnitId: "ca-app-pub-reward"
        ))
    }

    func testHandleLoadOutcomeOnSuccessInstallsFullScreenDelegate() async throws {
        let fakeAd = FakeFullScreenAd()
        let context = Tracking.FullScreenLoadContext(
            placement: nil, adUnitID: "unit", adFormat: .interstitial,
            fullScreenContentDelegate: nil, paidEventHandler: nil
        )

        _ = try await self.adapter.handleLoadOutcome(
            loadAd: { fakeAd }, context: context
        )

        XCTAssertNotNil(fakeAd.fullScreenContentDelegate)
        XCTAssertTrue(fakeAd.fullScreenContentDelegate is Tracking.FullScreenContentDelegate)
    }

    func testHandleLoadOutcomeOnSuccessInstallsPaidEventHandler() async throws {
        let fakeAd = FakeFullScreenAd()
        let context = Tracking.FullScreenLoadContext(
            placement: nil, adUnitID: "unit", adFormat: .interstitial,
            fullScreenContentDelegate: nil, paidEventHandler: nil
        )

        _ = try await self.adapter.handleLoadOutcome(
            loadAd: { fakeAd }, context: context
        )

        XCTAssertNotNil(fakeAd.paidEventHandler)
    }

    func testTrackRevenueCallsTrackerWithCorrectRevenueData() {
        self.adapter.trackRevenue(
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

        self.adapter.trackRevenue(
            placement: "test",
            adUnitID: "unit",
            adFormat: .interstitial,
            responseInfo: nil,
            adValue: Self.makeAdValuePlaceholder()
        )

        XCTAssertTrue(self.mockTracker.revenueData.isEmpty)
    }

    func testHandleLoadOutcomeOnSuccessPaidHandlerTracksRevenue() async throws {
        let fakeAd = FakeFullScreenAd()
        let context = Tracking.FullScreenLoadContext(
            placement: "reward_screen",
            adUnitID: "ca-app-pub-reward",
            adFormat: .rewarded,
            fullScreenContentDelegate: nil,
            paidEventHandler: nil
        )

        _ = try await self.adapter.handleLoadOutcome(
            loadAd: { fakeAd }, context: context
        )

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

    func testHandleLoadOutcomeOnSuccessPaidHandlerForwardsToUserHandler() async throws {
        let fakeAd = FakeFullScreenAd()
        var userHandlerCalled = false
        let context = Tracking.FullScreenLoadContext(
            placement: "reward_screen",
            adUnitID: "ca-app-pub-reward",
            adFormat: .rewarded,
            fullScreenContentDelegate: nil,
            paidEventHandler: { _ in userHandlerCalled = true }
        )

        _ = try await self.adapter.handleLoadOutcome(
            loadAd: { fakeAd }, context: context
        )

        fakeAd.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertTrue(userHandlerCalled)
        XCTAssertEqual(self.mockTracker.revenueData.count, 1)
    }

    func testTrackFailedToLoadCapturesErrorCode() {
        let error = NSError(domain: "com.google.ads", code: 42, userInfo: nil)
        self.adapter.trackFailedToLoad(
            placement: "feed",
            adUnitID: "ca-app-pub-456",
            adFormat: .banner,
            error: error
        )

        XCTAssertEqual(self.mockTracker.failedToLoadData.count, 1)
        XCTAssertEqual(self.mockTracker.failedToLoadData[0].mediatorErrorCode, 42)
    }

    func testTrackLoadedExtractsResponseInfoFields() {
        self.adapter.trackLoaded(
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
        self.adapter.trackRevenue(
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

    func testHandleLoadOutcomeForwardsCallbacksToUserDelegate() async throws {
        let fakeAd = FakeFullScreenAd()
        let spy = FullScreenContentDelegateSpy()
        let context = Tracking.FullScreenLoadContext(
            placement: "test",
            adUnitID: "unit",
            adFormat: .interstitial,
            fullScreenContentDelegate: spy,
            paidEventHandler: nil
        )

        _ = try await self.adapter.handleLoadOutcome(
            loadAd: { fakeAd }, context: context
        )

        let presentingAd = FakeFullScreenPresentingAd()
        await fakeAd.fullScreenContentDelegate?.adDidRecordImpression?(presentingAd)
        await fakeAd.fullScreenContentDelegate?.adDidRecordClick?(presentingAd)
        await fakeAd.fullScreenContentDelegate?.adWillPresentFullScreenContent?(presentingAd)
        await fakeAd.fullScreenContentDelegate?.adWillDismissFullScreenContent?(presentingAd)
        await fakeAd.fullScreenContentDelegate?.adDidDismissFullScreenContent?(presentingAd)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(spy.didRecordClick)
        XCTAssertTrue(spy.willPresent)
        XCTAssertTrue(spy.willDismiss)
        XCTAssertTrue(spy.didDismiss)
    }

    func testNilAdUnitIDMapsToEmptyString() {
        self.adapter.trackLoaded(
            responseInfo: nil,
            placement: "test",
            adUnitID: nil,
            adFormat: .banner
        )

        XCTAssertEqual(self.mockTracker.loadedData.count, 1)
        XCTAssertEqual(self.mockTracker.loadedData[0].adUnitId, "")
    }

    // MARK: - Show-time placement override

    func testShowTimePlacementOverrideIsUsedInRevenueEvent() async throws {
        let fakeAd = FakeFullScreenAd()
        let context = Tracking.FullScreenLoadContext(
            placement: "load_time_placement",
            adUnitID: "ca-app-pub-test",
            adFormat: .rewarded,
            fullScreenContentDelegate: nil,
            paidEventHandler: nil
        )

        _ = try await self.adapter.handleLoadOutcome(
            loadAd: { fakeAd }, context: context
        )
        await MainActor.run {
            (fakeAd.fullScreenContentDelegate as? Tracking.FullScreenContentDelegate)?.placement = "show_time_placement"
        }
        fakeAd.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertEqual(self.mockTracker.revenueData.count, 1)
        XCTAssertEqual(self.mockTracker.revenueData[0].placement, "show_time_placement")
    }

    // MARK: - updateFullScreenContentDelegate

    func testUpdateDelegateAfterLoadUpdatesWrapper() async throws {
        let fakeAd = FakeFullScreenAd()
        let context = Tracking.FullScreenLoadContext(
            placement: "test", adUnitID: "ca-app-pub-test", adFormat: .interstitial,
            fullScreenContentDelegate: nil, paidEventHandler: nil
        )

        _ = try await self.adapter.handleLoadOutcome(loadAd: { fakeAd }, context: context)

        let spy = FullScreenContentDelegateSpy()
        self.adapter.updateFullScreenContentDelegate(on: fakeAd, newDelegate: spy)

        let presentingAd = FakeFullScreenPresentingAd()
        fakeAd.fullScreenContentDelegate?.adDidRecordImpression?(presentingAd)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertEqual(self.mockTracker.displayedData.count, 1)
    }

    func testUpdateDelegateAfterDirectOverwriteFallsBackToDirectAssignment() async throws {
        let fakeAd = FakeFullScreenAd()
        let context = Tracking.FullScreenLoadContext(
            placement: "test", adUnitID: "ca-app-pub-test", adFormat: .interstitial,
            fullScreenContentDelegate: nil, paidEventHandler: nil
        )

        _ = try await self.adapter.handleLoadOutcome(loadAd: { fakeAd }, context: context)

        // Simulate developer overwriting the delegate directly
        fakeAd.fullScreenContentDelegate = FullScreenContentDelegateSpy()

        let spy = FullScreenContentDelegateSpy()
        self.adapter.updateFullScreenContentDelegate(on: fakeAd, newDelegate: spy)

        let presentingAd = FakeFullScreenPresentingAd()
        fakeAd.fullScreenContentDelegate?.adDidRecordImpression?(presentingAd)

        XCTAssertTrue(spy.didRecordImpression)
        XCTAssertTrue(fakeAd.fullScreenContentDelegate === spy)
        XCTAssertTrue(self.mockTracker.displayedData.isEmpty)
    }

    func testUpdateDelegateWithNilClearsUserDelegate() async throws {
        let fakeAd = FakeFullScreenAd()
        let initialSpy = FullScreenContentDelegateSpy()
        let context = Tracking.FullScreenLoadContext(
            placement: "test", adUnitID: "ca-app-pub-test", adFormat: .interstitial,
            fullScreenContentDelegate: initialSpy, paidEventHandler: nil
        )

        _ = try await self.adapter.handleLoadOutcome(loadAd: { fakeAd }, context: context)

        self.adapter.updateFullScreenContentDelegate(on: fakeAd, newDelegate: nil)

        let presentingAd = FakeFullScreenPresentingAd()
        fakeAd.fullScreenContentDelegate?.adDidRecordImpression?(presentingAd)

        XCTAssertFalse(initialSpy.didRecordImpression)
        XCTAssertEqual(self.mockTracker.displayedData.count, 1)
    }

    func testUpdateDelegateWithoutLoadAndTrackFallsBackToDirectAssignment() {
        let fakeAd = FakeFullScreenAd()
        let spy = FullScreenContentDelegateSpy()

        self.adapter.updateFullScreenContentDelegate(on: fakeAd, newDelegate: spy)

        XCTAssertTrue(fakeAd.fullScreenContentDelegate === spy)
    }

    func testPaidEventHandlerStillWorksAfterDelegateUpdate() async throws {
        let fakeAd = FakeFullScreenAd()
        let context = Tracking.FullScreenLoadContext(
            placement: "original_placement", adUnitID: "ca-app-pub-test", adFormat: .rewarded,
            fullScreenContentDelegate: nil, paidEventHandler: nil
        )

        _ = try await self.adapter.handleLoadOutcome(loadAd: { fakeAd }, context: context)

        let spy = FullScreenContentDelegateSpy()
        self.adapter.updateFullScreenContentDelegate(on: fakeAd, newDelegate: spy)

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

@MainActor
@available(iOS 15.0, *)
final class RCAdMobDelegateTrackingTests: RCAdMobTestCase {

    private var mockTracker: MockAdTracker!
    private var adapter: Tracking.Adapter!

    override func setUp() {
        super.setUp()
        self.mockTracker = MockAdTracker()
        self.adapter = Tracking.Adapter(tracker: self.mockTracker)
    }

    func testBannerDelegateTracksLoadedViaTracker() {
        let bannerDelegate = Tracking.BannerViewDelegate(
            adapter: self.adapter, delegate: nil, placement: "banner_top"
        )
        let fakeBanner = GoogleMobileAds.BannerView()
        fakeBanner.adUnitID = "ca-app-pub-banner"

        bannerDelegate.bannerViewDidReceiveAd(fakeBanner)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdLoaded")
        XCTAssertEqual(self.mockTracker.calls.first?.adFormat, AdFormat.banner.rawValue)
    }

    func testBannerDelegateTracksFailedToLoadViaTracker() {
        let bannerDelegate = Tracking.BannerViewDelegate(
            adapter: self.adapter, delegate: nil, placement: "banner_bottom"
        )
        let fakeBanner = GoogleMobileAds.BannerView()
        fakeBanner.adUnitID = "ca-app-pub-banner"
        let error = NSError(domain: "test", code: 1, userInfo: nil)

        bannerDelegate.bannerView(fakeBanner, didFailToReceiveAdWithError: error)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdFailedToLoad")
    }

    func testBannerDelegateTracksImpressionViaTracker() {
        let bannerDelegate = Tracking.BannerViewDelegate(
            adapter: self.adapter, delegate: nil, placement: "banner_mid"
        )
        let fakeBanner = GoogleMobileAds.BannerView()
        fakeBanner.adUnitID = "ca-app-pub-banner"

        bannerDelegate.bannerViewDidRecordImpression(fakeBanner)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdDisplayed")
    }

    func testBannerDelegateTracksClickViaTracker() {
        let bannerDelegate = Tracking.BannerViewDelegate(
            adapter: self.adapter, delegate: nil, placement: "banner_mid"
        )
        let fakeBanner = GoogleMobileAds.BannerView()
        fakeBanner.adUnitID = "ca-app-pub-banner"

        bannerDelegate.bannerViewDidRecordClick(fakeBanner)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdOpened")
    }

    func testFullScreenDelegateTracksImpressionViaTracker() {
        let fakeAd = FakeFullScreenPresentingAd()
        let delegate = Tracking.FullScreenContentDelegate(
            adapter: self.adapter,
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
        let delegate = Tracking.FullScreenContentDelegate(
            adapter: self.adapter,
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
        let nativeDelegate = Tracking.NativeAdDelegate(
            adapter: self.adapter, delegate: nil, placement: "native_feed", adUnitID: "ca-app-pub-native"
        )
        let fakeNativeAd = GoogleMobileAds.NativeAd()

        nativeDelegate.nativeAdDidRecordImpression(fakeNativeAd)

        XCTAssertEqual(self.mockTracker.calls.count, 1)
        XCTAssertEqual(self.mockTracker.calls.first?.method, "trackAdDisplayed")
        XCTAssertEqual(self.mockTracker.calls.first?.adFormat, AdFormat.native.rawValue)
    }

    func testNativeDelegateTracksClickViaTracker() {
        let nativeDelegate = Tracking.NativeAdDelegate(
            adapter: self.adapter, delegate: nil, placement: "native_feed", adUnitID: "ca-app-pub-native"
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
private final class FakeFullScreenAd: NSObject, Tracking.FullScreenAd {
    var fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?
    var paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?
    let responseInfo: GoogleMobileAds.ResponseInfo = unsafeBitCast(
        FakeResponseInfo(),
        to: GoogleMobileAds.ResponseInfo.self
    )
}

@available(iOS 15.0, *)
private final class FakeResponseInfo: NSObject {
    @objc var responseIdentifier: String? { nil }
    @objc var loadedAdNetworkResponseInfo: AnyObject? { nil }
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
