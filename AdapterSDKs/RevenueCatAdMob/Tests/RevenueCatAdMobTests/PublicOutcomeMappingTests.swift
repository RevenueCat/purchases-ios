import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class PublicOutcomeMappingTests: AdapterTestCase {

    func testMapVirtualCurrencyPositiveAmount() {
        let reward = RevenueCat.VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "gems", amount: 7))
        let mapped = RewardVerification.mapVerifiedReward(reward)
        XCTAssertTrue(mapped.isVirtualCurrency)
        XCTAssertEqual(mapped.virtualCurrencyCode, "gems")
        XCTAssertEqual(mapped.virtualCurrencyAmount, 7)
    }

    func testMapVirtualCurrencyNonPositiveAmountBecomesNone() {
        let reward = RevenueCat.VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "gems", amount: 0))
        let mapped = RewardVerification.mapVerifiedReward(reward)
        XCTAssertTrue(mapped.isNone)
    }

    func testMapNoRewardBecomesNone() {
        let mapped = RewardVerification.mapVerifiedReward(.noReward)
        XCTAssertTrue(mapped.isNone)
    }

    func testMapUnsupportedBecomesUnknown() {
        let mapped = RewardVerification.mapVerifiedReward(.unsupportedReward)
        XCTAssertTrue(mapped.isUnknown)
    }

    func testMapPublicOutcomeVerified() {
        let reward = RevenueCat.VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "c", amount: 2))
        let outcome = RewardVerification.mapPublicOutcome(.verified(reward))
        XCTAssertTrue(outcome.isVerified)
        XCTAssertEqual(outcome.verifiedReward?.virtualCurrencyCode, "c")
        XCTAssertEqual(outcome.verifiedReward?.virtualCurrencyAmount, 2)
    }

    func testMapPublicOutcomeFailed() {
        let outcome = RewardVerification.mapPublicOutcome(.failed)
        XCTAssertTrue(outcome.isFailed)
        XCTAssertNil(outcome.verifiedReward)
    }
}

#endif
