import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class AssociatedObjectStoreTests: AdapterTestCase {

    func testRetainThenRetrieveReturnsSameInstance() {
        let store = Tracking.AssociatedObjectStore<NSObject>()
        let owner = NSObject()
        let value = NSObject()

        store.set(value, for: owner)

        XCTAssertIdentical(store.retrieve(for: owner), value)
    }

    func testRetrieveOnUnknownOwnerReturnsNil() {
        let store = Tracking.AssociatedObjectStore<NSObject>()
        let owner = NSObject()

        XCTAssertNil(store.retrieve(for: owner))
    }

    func testTwoStoresOfSameTypeOnSameOwnerDontCollide() {
        let storeA = Tracking.AssociatedObjectStore<NSObject>()
        let storeB = Tracking.AssociatedObjectStore<NSObject>()
        let owner = NSObject()
        let valueA = NSObject()
        let valueB = NSObject()

        storeA.set(valueA, for: owner)
        storeB.set(valueB, for: owner)

        XCTAssertIdentical(storeA.retrieve(for: owner), valueA)
        XCTAssertIdentical(storeB.retrieve(for: owner), valueB)
    }

    func testRetainNilClearsPreviousValue() {
        let store = Tracking.AssociatedObjectStore<NSObject>()
        let owner = NSObject()

        store.set(NSObject(), for: owner)
        store.set(nil, for: owner)

        XCTAssertNil(store.retrieve(for: owner))
    }

}
#endif
