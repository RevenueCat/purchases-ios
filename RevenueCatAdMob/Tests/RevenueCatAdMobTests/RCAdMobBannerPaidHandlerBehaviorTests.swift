import Foundation
import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) @testable import RevenueCatAdMob

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

    private static func makeAdValuePlaceholder() -> RCGoogleMobileAds.AdValue {
        let backing = AdValuePlaceholder()
        return unsafeBitCast(backing, to: RCGoogleMobileAds.AdValue.self)
    }

}

@available(iOS 15.0, *)
private final class AdValuePlaceholder: NSObject {
    @objc var value: NSDecimalNumber { NSDecimalNumber(value: 1) }
    @objc var currencyCode: String { "USD" }
    @objc var precision: Int { 0 }
}

#endif
