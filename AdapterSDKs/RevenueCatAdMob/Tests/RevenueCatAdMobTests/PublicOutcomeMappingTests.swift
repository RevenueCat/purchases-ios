import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class PublicOutcomeMappingTests: AdapterTestCase {

    func testMapVirtualCurrencyPositiveAmount() {
        let reward = VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "gems", amount: 7))
        let mapped = RewardVerification.mapValidatedReward(reward)
        XCTAssertTrue(mapped.isVirtualCurrency)
        XCTAssertEqual(mapped.virtualCurrencyCode, "gems")
        XCTAssertEqual(mapped.virtualCurrencyAmount, 7)
    }

    func testMapVirtualCurrencyNonPositiveAmountBecomesNone() {
        let reward = VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "gems", amount: 0))
        let mapped = RewardVerification.mapValidatedReward(reward)
        XCTAssertTrue(mapped.isNone)
    }

    func testMapNoRewardBecomesNone() {
        let mapped = RewardVerification.mapValidatedReward(.noReward)
        XCTAssertTrue(mapped.isNone)
    }

    func testMapUnsupportedBecomesUnknown() {
        let mapped = RewardVerification.mapValidatedReward(.unsupportedReward)
        XCTAssertTrue(mapped.isUnknown)
    }

    func testMapPublicOutcomeVerified() {
        let reward = VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "c", amount: 2))
        let outcome = RewardVerification.mapPublicOutcome(.verified(reward))
        XCTAssertTrue(outcome.isValidated)
        XCTAssertEqual(outcome.validatedReward?.virtualCurrencyCode, "c")
        XCTAssertEqual(outcome.validatedReward?.virtualCurrencyAmount, 2)
    }

    func testMapPublicOutcomeFailed() {
        let outcome = RewardVerification.mapPublicOutcome(.failed)
        XCTAssertTrue(outcome.isFailed)
        XCTAssertNil(outcome.validatedReward)
    }
}

#endif
