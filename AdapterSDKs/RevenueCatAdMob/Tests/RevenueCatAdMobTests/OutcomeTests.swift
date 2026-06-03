import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) @_spi(Experimental) @testable import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class OutcomeTests: AdapterTestCase {

    // MARK: - Case construction

    func testVerifiedCarriesVirtualCurrencyRewardPayload() throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let outcome = RewardVerification.Outcome.verified(.virtualCurrency(reward))

        guard case .verified(let adReward) = outcome, let captured = adReward.virtualCurrency else {
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

    func testAllCasesAreConstructibleAndExhaustiveInSwitch() throws {
        let payload = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 1))
        let cases: [RewardVerification.Outcome] = [
            .verified(.virtualCurrency(payload)),
            .verified(.noReward),
            .verified(.unsupportedReward),
            .failed(.timeout),
            .failed(.backendError),
            .failed(.unknown)
        ]

        for outcome in cases {
            switch outcome {
            case .verified: continue
            case .failed: continue
            }
        }
        XCTAssertEqual(cases.count, 6)
    }
}

#endif
