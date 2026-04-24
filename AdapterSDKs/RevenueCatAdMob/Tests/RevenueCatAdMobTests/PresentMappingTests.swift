import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class PresentMappingTests: AdapterTestCase {

    func testMapVirtualCurrencyPositiveAmount() {
        let reward = RevenueCat.VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "gems", amount: 7))
        let mapped = RewardVerification.mapVerifiedReward(reward)
        XCTAssertTrue(mapped.isVirtualCurrency)
        XCTAssertEqual(mapped.virtualCurrencyCode, "gems")
        XCTAssertEqual(mapped.virtualCurrencyAmount, 7)
    }

    func testMapNoRewardBecomesNone() {
        let mapped = RewardVerification.mapVerifiedReward(.noReward)
        XCTAssertTrue(mapped.isNone)
    }

    func testMapUnsupportedBecomesUnknown() {
        let mapped = RewardVerification.mapVerifiedReward(.unsupportedReward)
        XCTAssertTrue(mapped.isUnknown)
    }

    func testMapOutcomeVerified() {
        let reward = RevenueCat.VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "c", amount: 2))
        let result = RewardVerification.mapOutcome(.verified(reward))
        XCTAssertTrue(result.isVerified)
        XCTAssertEqual(result.verifiedReward?.virtualCurrencyCode, "c")
        XCTAssertEqual(result.verifiedReward?.virtualCurrencyAmount, 2)
    }

    func testMapOutcomeFailed() {
        let result = RewardVerification.mapOutcome(.failed)
        XCTAssertTrue(result.isFailed)
        XCTAssertNil(result.verifiedReward)
    }
}

#endif
