import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class StateStoreTests: AdapterTestCase {

    // MARK: - Round-trip

    func testStateForReturnsNilWhenNothingStashed() {
        let host = StateHost()

        XCTAssertNil(RewardVerification.stateStore.retrieve(for: host))
    }

    func testStoredStateIsRetrievableViaStateAccessor() throws {
        let host = StateHost()
        let state = RewardVerification.State(clientTransactionID: "tx-store-1")

        RewardVerification.stateStore.set(state, for: host)

        let retrieved = try XCTUnwrap(RewardVerification.stateStore.retrieve(for: host))
        XCTAssertTrue(retrieved === state,
                      "retrieve(for:) must return the exact instance passed to retain(_:for:)")
    }

    func testStoreOverwritesPreviouslyStashedStateOnSameHost() throws {
        let host = StateHost()
        let firstState = RewardVerification.State(clientTransactionID: "tx-first")
        let secondState = RewardVerification.State(clientTransactionID: "tx-second")

        RewardVerification.stateStore.set(firstState, for: host)
        RewardVerification.stateStore.set(secondState, for: host)

        let retrieved = try XCTUnwrap(RewardVerification.stateStore.retrieve(for: host))
        XCTAssertTrue(retrieved === secondState)
        XCTAssertFalse(retrieved === firstState)
    }

    // MARK: - Per-host isolation

    func testStateStashedOnOneHostIsNotVisibleFromAnother() {
        let firstHost = StateHost()
        let secondHost = StateHost()
        let state = RewardVerification.State(clientTransactionID: "tx-only-on-first")

        RewardVerification.stateStore.set(state, for: firstHost)

        XCTAssertNotNil(RewardVerification.stateStore.retrieve(for: firstHost))
        XCTAssertNil(RewardVerification.stateStore.retrieve(for: secondHost),
                     "Associated state must be scoped to the host instance it was stashed on")
    }

    // MARK: - Lifetime

    func testStashedStateIsRetainedForTheLifetimeOfTheHost() {
        weak var weakState: RewardVerification.State?
        let host = StateHost()

        autoreleasepool {
            let state = RewardVerification.State(clientTransactionID: "tx-retained")
            weakState = state
            RewardVerification.stateStore.set(state, for: host)
        }

        XCTAssertNotNil(weakState,
                        "Stashed state must be strongly retained by the host via the associated object")
        _ = host
    }
}

// MARK: - Test doubles

/// A bare `NSObject` subclass that hosts associated objects without bringing in any AdMob types.
@available(iOS 15.0, *)
private final class StateHost: NSObject {}

#endif
