import Nimble
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class PresentMappingTests: AdapterTestCase {

    func testMapOutcomeVerifiedPassesRewardThrough() {
        let reward = AdReward.virtualCurrency(VirtualCurrencyReward(code: "c", amount: 2))
        let result = RewardVerification.mapOutcome(.verified(reward))
        XCTAssertNotNil(result.verifiedReward)
        XCTAssertEqual(result.verifiedReward?.virtualCurrency?.code, "c")
        XCTAssertEqual(result.verifiedReward?.virtualCurrency?.amount, 2)
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
        XCTAssertTrue(result.isFailed)
        XCTAssertNil(result.verifiedReward)
    }
}

#endif
