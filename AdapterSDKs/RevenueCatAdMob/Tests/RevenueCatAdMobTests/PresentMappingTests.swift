import Nimble
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class PresentMappingTests: AdapterTestCase {

    func testMapOutcomeVerifiedPassesRewardThrough() throws {
        let payload = try XCTUnwrap(VirtualCurrencyReward(code: "c", amount: 2))
        let reward = AdReward.virtualCurrency(payload)
        let result = RewardVerification.mapOutcome(.verified(reward))
        XCTAssertEqual(result.verifiedReward, reward)
    }

    func testMapOutcomeVerifiedNoReward() {
        let result = RewardVerification.mapOutcome(.verified(.noReward))
        XCTAssertEqual(result.verifiedReward, .noReward)
    }

    func testMapOutcomeVerifiedUnsupportedReward() {
        let result = RewardVerification.mapOutcome(.verified(.unsupportedReward))
        XCTAssertEqual(result.verifiedReward, .unsupportedReward)
    }

    func testMapOutcomeFailed() {
        let result = RewardVerification.mapOutcome(.failed(.unknown))
        XCTAssertEqual(result, .failed)
        XCTAssertNil(result.verifiedReward)
    }
}

#endif
