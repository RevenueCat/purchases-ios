import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@testable import RevenueCatAdMob

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

    func testConcurrentConsumeFireTokenAttemptsYieldExactlyOneSuccess() async {
        let state = RewardVerification.State(clientTransactionID: "tx-1")
        let attemptCount = 200

        let successCount = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<attemptCount {
                group.addTask { state.consumeFireToken() }
            }
            var total = 0
            for await result in group where result {
                total += 1
            }
            return total
        }

        XCTAssertEqual(successCount, 1)
    }
}

#endif
