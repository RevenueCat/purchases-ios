import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class NativeDelegateStoreTests: AdapterTestCase {

    func testRetainKeepsDelegateAliveWhileOwnerExists() {
        var owner: NSObject? = NSObject()
        weak var weakDelegate: Tracking.NativeAdDelegate?

        autoreleasepool {
            var delegate: Tracking.NativeAdDelegate? = Tracking.NativeAdDelegate(
                adapter: .shared,
                delegate: nil,
                placement: nil,
                adUnitID: "test_ad_unit"
            )
            weakDelegate = delegate
            guard let owner, let strongDelegate = delegate else {
                XCTFail("Expected owner and delegate to be non-nil")
                return
            }

            Tracking.Adapter.shared.nativeDelegateStore.set(strongDelegate, for: owner)
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
