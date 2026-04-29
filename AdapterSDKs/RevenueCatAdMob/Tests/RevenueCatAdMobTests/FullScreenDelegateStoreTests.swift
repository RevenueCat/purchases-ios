import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class FullScreenDelegateStoreTests: AdapterTestCase {

    @MainActor
    func testRetainKeepsDelegateAliveWhileOwnerExists() {
        var owner: NSObject? = NSObject()
        weak var weakDelegate: Tracking.FullScreenContentDelegate?

        autoreleasepool {
            var delegate: Tracking.FullScreenContentDelegate? = Tracking.FullScreenContentDelegate(
                adapter: .shared,
                delegate: nil,
                placement: nil,
                adUnitID: "test_ad_unit",
                adFormat: .interstitial,
                responseInfoProvider: { nil }
            )
            weakDelegate = delegate
            guard let owner, let strongDelegate = delegate else {
                XCTFail("Expected owner and delegate to be non-nil")
                return
            }

            Tracking.Adapter.shared.fullScreenDelegateStore.set(strongDelegate, for: owner)
            delegate = nil

            XCTAssertNotNil(weakDelegate)
        }

        owner = nil
        self.flushRunLoop()
        XCTAssertNil(weakDelegate)
    }

    private func flushRunLoop() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }

}

#endif
