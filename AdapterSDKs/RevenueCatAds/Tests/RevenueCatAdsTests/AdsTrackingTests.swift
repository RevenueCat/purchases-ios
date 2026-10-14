//
//  AdsTrackingTests.swift
//
//  Created by RevenueCat.
//

import XCTest

#if os(iOS) && canImport(PrebidMobile)
import RevenueCat
@_spi(Experimental) @testable import RevenueCatAds

@MainActor
final class AdsTrackingTests: TestCase {

    private var module: FakeAdModule!
    private var tracking: FakeAdTracking!
    private var interstitial: AdsInterstitial!

    override func setUp() async throws {
        try await super.setUp()
        self.module = FakeAdModule()
        self.tracking = FakeAdTracking()
        let module = self.module
        self.interstitial = AdsInterstitial(
            placementID: "placement",
            moduleProvider: { module },
            tracking: self.tracking
        )
    }

    func testMediatorIsRevenueCat() {
        XCTAssertEqual(MediatorName.revenueCat.rawValue, "RevenueCat")
    }

    func testLoadTracksLoaded() async throws {
        try await self.loadSuccessfully()

        let loaded = try XCTUnwrap(self.tracking.loaded.onlyElement)
        XCTAssertEqual(loaded.mediatorName, .revenueCat)
        XCTAssertEqual(loaded.adFormat, .interstitial)
        XCTAssertEqual(loaded.networkName, "FakeNetwork")
        XCTAssertEqual(loaded.placement, "placement")
        XCTAssertEqual(loaded.adUnitId, "placement")
        XCTAssertFalse(loaded.impressionId.isEmpty)
        XCTAssertEqual(self.tracking.trackedEventCount, 1)
    }

    func testLoadFailureTracksFailedToLoadWithUnderlyingErrorCode() async {
        let underlying = NSError(domain: "prebid", code: 42)
        self.module.interstitialEvent = .failedToLoad(
            AdsError(code: .loadFailed, message: "boom", underlyingError: underlying)
        )

        try? await self.interstitial.load()

        let failed = self.tracking.failedToLoad.onlyElement
        XCTAssertEqual(failed?.mediatorName, .revenueCat)
        XCTAssertEqual(failed?.adFormat, .interstitial)
        XCTAssertEqual(failed?.placement, "placement")
        XCTAssertEqual(failed?.adUnitId, "placement")
        XCTAssertEqual(failed?.mediatorErrorCode, 42)
        XCTAssertEqual(self.tracking.trackedEventCount, 1)
    }

    func testLoadFailureWithoutUnderlyingErrorHasNoErrorCode() async {
        self.module.interstitialEvent = .failedToLoad(AdsError(code: .noFill, message: "none"))

        try? await self.interstitial.load()

        XCTAssertEqual(self.tracking.failedToLoad.count, 1)
        XCTAssertNil(self.tracking.failedToLoad.first?.mediatorErrorCode)
    }

    func testLoadWithoutModuleTracksNothing() async {
        let interstitial = AdsInterstitial(placementID: "placement", moduleProvider: { nil }, tracking: self.tracking)

        try? await interstitial.load()

        XCTAssertEqual(self.tracking.trackedEventCount, 0)
    }

    func testPresentTracksDisplayed() async throws {
        try await self.presentLoadedAd()

        let displayed = try XCTUnwrap(self.tracking.displayed.onlyElement)
        XCTAssertEqual(displayed.mediatorName, .revenueCat)
        XCTAssertEqual(displayed.adFormat, .interstitial)
        XCTAssertEqual(displayed.networkName, "FakeNetwork")
        XCTAssertEqual(displayed.placement, "placement")
        XCTAssertEqual(displayed.impressionId, self.tracking.loaded.first?.impressionId)
    }

    func testClickTracksOpened() async throws {
        try await self.presentLoadedAd()

        self.module.lastInterstitial?.emit(.clicked)

        let opened = try XCTUnwrap(self.tracking.opened.onlyElement)
        XCTAssertEqual(opened.mediatorName, .revenueCat)
        XCTAssertEqual(opened.adFormat, .interstitial)
        XCTAssertEqual(opened.impressionId, self.tracking.loaded.first?.impressionId)
    }

    func testImpressionTracksRevenueOnce() async throws {
        try await self.presentLoadedAd()
        let unit = try XCTUnwrap(self.module.lastInterstitial)
        unit.revenue = AdModuleRevenue(micros: 1_500, currency: "USD", precision: .exact)

        unit.emit(.impression)
        unit.emit(.impression)

        let revenue = try XCTUnwrap(self.tracking.revenues.onlyElement)
        XCTAssertEqual(revenue.mediatorName, .revenueCat)
        XCTAssertEqual(revenue.adFormat, .interstitial)
        XCTAssertEqual(revenue.networkName, "FakeNetwork")
        XCTAssertEqual(revenue.placement, "placement")
        XCTAssertEqual(revenue.impressionId, self.tracking.loaded.first?.impressionId)
        XCTAssertEqual(revenue.revenueMicros, 1_500)
        XCTAssertEqual(revenue.currency, "USD")
        XCTAssertEqual(revenue.precision, .exact)
    }

    func testImpressionWithoutPriceTracksNoRevenue() async throws {
        try await self.presentLoadedAd()

        self.module.lastInterstitial?.emit(.impression)

        XCTAssertTrue(self.tracking.revenues.isEmpty)
    }

    func testDismissTracksNothing() async throws {
        try await self.presentLoadedAd()
        let countBeforeDismiss = self.tracking.trackedEventCount

        self.module.lastInterstitial?.emit(.dismissed)

        XCTAssertEqual(self.tracking.trackedEventCount, countBeforeDismiss)
    }

    func testEachLoadGetsANewImpressionID() async throws {
        try await self.presentLoadedAd()
        self.module.lastInterstitial?.emit(.dismissed)

        try await self.loadSuccessfully()

        XCTAssertEqual(self.tracking.loaded.count, 2)
        XCTAssertNotEqual(self.tracking.loaded[0].impressionId, self.tracking.loaded[1].impressionId)
    }

    func testEventsOutsideTheirStateAreNotTracked() async throws {
        try await self.loadSuccessfully()
        let unit = try XCTUnwrap(self.module.lastInterstitial)

        unit.emit(.loaded)
        unit.emit(.presented)
        unit.emit(.clicked)

        XCTAssertEqual(self.tracking.trackedEventCount, 1)
    }

    func testNothingIsTrackedWhenPurchasesIsNotConfigured() async throws {
        self.tracking.isConfigured = false

        try await self.presentLoadedAd()
        let unit = try XCTUnwrap(self.module.lastInterstitial)
        unit.revenue = AdModuleRevenue(micros: 1_500, currency: "USD", precision: .exact)
        unit.emit(.impression)
        unit.emit(.clicked)
        unit.emit(.dismissed)

        XCTAssertEqual(self.tracking.trackedEventCount, 0)
        XCTAssertEqual(self.interstitial.state, .idle)
    }

    func testDefaultTrackingIsUnconfiguredWithoutPurchases() async throws {
        let interstitial = AdsInterstitial(placementID: "placement", moduleProvider: { self.module })
        self.module.interstitialEvent = .loaded

        try await interstitial.load()

        XCTAssertFalse(Purchases.isConfigured)
        XCTAssertFalse(PurchasesAdTracking().isConfigured)
        XCTAssertTrue(interstitial.isReady)
    }

    func testPrebidRevenueConvertsCPMToMicrosPerImpression() {
        let revenue = PrebidInterstitial.revenue(fromCPM: 1.37)

        XCTAssertEqual(revenue, AdModuleRevenue(micros: 1_370, currency: "USD", precision: .exact))
    }

    func testPrebidRevenueIsNilWithoutAPrice() {
        XCTAssertNil(PrebidInterstitial.revenue(fromCPM: 0))
    }

    // MARK: - Helpers

    private func loadSuccessfully() async throws {
        self.module.interstitialEvent = .loaded
        try await self.interstitial.load()
    }

    private func presentLoadedAd() async throws {
        try await self.loadSuccessfully()
        self.interstitial.present(from: UIViewController())
        self.module.lastInterstitial?.emit(.presented)
    }

}

private extension Array {

    var onlyElement: Element? { self.count == 1 ? self.first : nil }

}

#endif
