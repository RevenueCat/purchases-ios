import Foundation
import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCat_AdMob

@available(iOS 15.0, *)
final class RCAdMobBannerPaidHandlerBehaviorTests: RCAdMobTestCase {

    func testLoadAndTrackPrefersExplicitPaidHandlerOverExistingOne() {
        let bannerView = BannerView(adSize: AdSizeBanner)
        var existingCount = 0
        var explicitCount = 0

        bannerView.paidEventHandler = { _ in existingCount += 1 }
        bannerView.loadAndTrack(
            request: Request(),
            placement: "home_banner",
            paidEventHandler: { _ in explicitCount += 1 }
        )

        bannerView.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertEqual(explicitCount, 1)
        XCTAssertEqual(existingCount, 0)
    }

    func testLoadAndTrackTwiceDoesNotDoubleWrapPaidHandler() {
        let bannerView = BannerView(adSize: AdSizeBanner)
        var userHandlerCount = 0

        bannerView.paidEventHandler = { _ in userHandlerCount += 1 }

        bannerView.loadAndTrack(request: Request(), placement: "home_banner")
        bannerView.loadAndTrack(request: Request(), placement: "home_banner")

        bannerView.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertEqual(userHandlerCount, 1)
    }

    /// Regression: calling loadAndTrack twice with no paidEventHandler must not cause infinite recursion
    /// when the paid event fires (second call would capture our own wrapper as "original" and recurse).
    func testLoadAndTrackTwiceWithNoPaidHandlerDoesNotRecurse() {
        let bannerView = BannerView(adSize: AdSizeBanner)

        bannerView.loadAndTrack(request: Request(), placement: "home_banner")
        bannerView.loadAndTrack(request: Request(), placement: "home_banner")

        // Invoking the wrapper must not stack overflow; with the bug this recurses infinitely.
        bannerView.paidEventHandler?(Self.makeAdValuePlaceholder())
    }

    /// Regression: user's paid handler must be invoked even when the paid event fires after the banner was deallocated.
    /// (e.g. ad SDK invokes the handler asynchronously after the view is gone.)
    func testPaidEventHandlerInvokedWhenBannerDeallocatedBeforeCallback() {
        var userHandlerCalled = false
        var banner: BannerView? = BannerView(adSize: AdSizeBanner)
        banner?.loadAndTrack(
            request: Request(),
            placement: "dealloc_test",
            paidEventHandler: { _ in userHandlerCalled = true }
        )
        let wrapperClosure = banner?.paidEventHandler
        XCTAssertNotNil(wrapperClosure, "loadAndTrack should set paidEventHandler")

        banner = nil // Release banner so it can deallocate; wrapper may still be invoked by ad SDK later

        wrapperClosure?(Self.makeAdValuePlaceholder()) // Simulate ad SDK invoking after deallocation

        XCTAssertTrue(userHandlerCalled, "User's paid handler should be called even when banner was deallocated")
    }

    func testBannerPaidEventTracksRevenueViaMockTracker() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-banner"

        bannerView.loadAndTrack(
            request: Request(),
            placement: "home_banner",
            delegate: nil,
            paidEventHandler: nil,
            rcAdMob: rcAdMob
        )

        bannerView.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertEqual(mockTracker.revenueData.count, 1)
        let revenue = mockTracker.revenueData[0]
        XCTAssertEqual(revenue.revenueMicros, 1_000_000)
        XCTAssertEqual(revenue.currency, "USD")
        XCTAssertEqual(revenue.precision, AdRevenue.Precision.unknown)
        XCTAssertEqual(revenue.adFormat, AdFormat.banner)
        XCTAssertEqual(revenue.placement, "home_banner")
        XCTAssertEqual(revenue.adUnitId, "ca-app-pub-banner")
        XCTAssertEqual(revenue.mediatorName, MediatorName.adMob)
    }

    func testBannerPaidEventForwardsToUserHandlerAndTracksRevenue() {
        let mockTracker = MockAdTracker()
        let rcAdMob = RCAdMob(tracker: mockTracker)
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-banner"
        var userHandlerCalled = false

        bannerView.loadAndTrack(
            request: Request(),
            placement: "home_banner",
            delegate: nil,
            paidEventHandler: { _ in userHandlerCalled = true },
            rcAdMob: rcAdMob
        )

        bannerView.paidEventHandler?(Self.makeAdValuePlaceholder())

        XCTAssertTrue(userHandlerCalled)
        XCTAssertEqual(mockTracker.revenueData.count, 1)
    }

    private static func makeAdValuePlaceholder() -> GoogleMobileAds.AdValue {
        let backing = AdValuePlaceholder()
        return unsafeBitCast(backing, to: GoogleMobileAds.AdValue.self)
    }

}

@available(iOS 15.0, *)
private final class AdValuePlaceholder: NSObject {
    @objc var value: NSDecimalNumber { NSDecimalNumber(value: 1) }
    @objc var currencyCode: String { "USD" }
    @objc var precision: Int { 0 }
}

#endif
