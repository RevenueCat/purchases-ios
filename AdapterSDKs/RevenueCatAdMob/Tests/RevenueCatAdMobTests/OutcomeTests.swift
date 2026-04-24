import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class OutcomeTests: AdapterTestCase {

    // MARK: - Case construction

    func testVerifiedCarriesVirtualCurrencyRewardPayload() {
        let reward = VirtualCurrencyReward(code: "coins", amount: 5)
        let outcome = RewardVerification.Outcome.verified(.virtualCurrency(reward))

        guard case .verified(.virtualCurrency(let captured)) = outcome else {
            return XCTFail("Expected .verified(.virtualCurrency), got \(outcome)")
        }
        XCTAssertEqual(captured, reward)
        XCTAssertEqual(captured.code, "coins")
        XCTAssertEqual(captured.amount, 5)
    }

    func testVerifiedCarriesNoRewardPayload() {
        let outcome = RewardVerification.Outcome.verified(.noReward)

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
    }

    func testVerifiedCarriesUnsupportedRewardPayload() {
        let outcome = RewardVerification.Outcome.verified(.unsupportedReward)

        guard case .verified(.unsupportedReward) = outcome else {
            return XCTFail("Expected .verified(.unsupportedReward), got \(outcome)")
        }
    }

    func testFailedIsConstructible() {
        let outcome = RewardVerification.Outcome.failed

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
    }

    func testAllCasesAreConstructibleAndExhaustiveInSwitch() {
        let cases: [RewardVerification.Outcome] = [
            .verified(.virtualCurrency(VirtualCurrencyReward(code: "coins", amount: 1))),
            .verified(.noReward),
            .verified(.unsupportedReward),
            .failed
        ]

        for outcome in cases {
            switch outcome {
            case .verified: continue
            case .failed: continue
            }
        }
        XCTAssertEqual(cases.count, 4)
    }
}

#endif
