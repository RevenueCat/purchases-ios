import Nimble
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class PresentMappingTests: AdapterTestCase {

    func testMapOutcomeVerifiedPassesRewardThrough() {
        let reward = AdReward.virtualCurrency(VirtualCurrencyReward(code: "c", amount: 2))
        let result = RewardVerification.mapOutcome(.verified(reward))
        XCTAssertNotNil(result.reward)
        XCTAssertEqual(result.reward?.virtualCurrency?.code, "c")
        XCTAssertEqual(result.reward?.virtualCurrency?.amount, 2)
    }

    func testMapOutcomeVerifiedNoReward() {
        let result = RewardVerification.mapOutcome(.verified(.noReward))
        XCTAssertEqual(result.reward, .noReward)
    }

    func testMapOutcomeVerifiedUnsupportedReward() {
        let result = RewardVerification.mapOutcome(.verified(.unsupportedReward))
        XCTAssertEqual(result.reward, .unsupportedReward)
    }

    func testMapOutcomeFailed() {
        let result = RewardVerification.mapOutcome(.failed(.unknown))
        XCTAssertTrue(result.isFailed)
        XCTAssertNil(result.reward)
    }
}

#endif
