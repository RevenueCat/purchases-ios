import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RCAdMobDelegateRetentionTests: RCAdMobTestCase {

    func testRetainFullScreenDelegateKeepsDelegateAliveWhileOwnerExists() {
        var owner: NSObject? = NSObject()
        weak var weakDelegate: NSObject?

        autoreleasepool {
            var delegate: NSObject? = NSObject()
            weakDelegate = delegate
            guard let owner, let strongDelegate = delegate else {
                XCTFail("Expected owner and delegate to be non-nil")
                return
            }

            RCAdMob.shared.retainFullScreenDelegate(strongDelegate, for: owner)
            delegate = nil

            XCTAssertNotNil(weakDelegate)
        }

        owner = nil
        self.flushRunLoop()
        XCTAssertNil(weakDelegate)
    }

    func testRetainNativeDelegateKeepsDelegateAliveWhileOwnerExists() {
        var owner: NSObject? = NSObject()
        weak var weakDelegate: NSObject?

        autoreleasepool {
            var delegate: NSObject? = NSObject()
            weakDelegate = delegate
            guard let owner, let strongDelegate = delegate else {
                XCTFail("Expected owner and delegate to be non-nil")
                return
            }

            RCAdMob.shared.retainNativeDelegate(strongDelegate, for: owner)
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
