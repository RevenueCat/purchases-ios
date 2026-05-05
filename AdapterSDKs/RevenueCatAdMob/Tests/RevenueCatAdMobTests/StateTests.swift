import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@testable import RevenueCatAdMob

@MainActor
@available(iOS 15.0, *)
final class StateTests: AdapterTestCase {

    // MARK: - Storage

    func testStoresClientTransactionID() {
        let state = RewardVerification.State(clientTransactionID: "tx-42")

        XCTAssertEqual(state.clientTransactionID, "tx-42")
    }

    // MARK: - One-shot guard

    func testFirstConsumeFireTokenReturnsTrueAndSubsequentReturnFalse() {
        let state = RewardVerification.State(clientTransactionID: "tx-1")

        XCTAssertTrue(state.consumeFireToken())
        XCTAssertFalse(state.consumeFireToken())
        XCTAssertFalse(state.consumeFireToken())
    }

}

#endif
