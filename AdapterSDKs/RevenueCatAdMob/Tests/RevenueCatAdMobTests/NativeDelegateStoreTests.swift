import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class NativeDelegateStoreTests: AdapterTestCase {

    func testRetainKeepsDelegateAliveWhileOwnerExists() {
        var owner: NSObject? = NSObject()
        weak var weakDelegate: NSObject?

        autoreleasepool {
            var delegate: NSObject? = NSObject()
            weakDelegate = delegate
            guard let owner, let strongDelegate = delegate else {
                XCTFail("Expected owner and delegate to be non-nil")
                return
            }

            Tracking.Adapter.shared.nativeDelegateStore.retain(strongDelegate, for: owner)
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
