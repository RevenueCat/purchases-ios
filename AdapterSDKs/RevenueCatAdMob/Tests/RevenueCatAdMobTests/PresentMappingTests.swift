import Nimble
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class PresentMappingTests: AdapterTestCase {

    func testMapVirtualCurrencyPositiveAmount() {
        let reward = RevenueCat.VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "gems", amount: 7))
        let mapped = RewardVerification.mapVerifiedReward(reward)
        XCTAssertEqual(mapped.virtualCurrency?.code, "gems")
        XCTAssertEqual(mapped.virtualCurrency?.amount, 7)
    }

    func testMapVirtualCurrencyWithNonPositiveAmountAsserts() {
        let reward = RevenueCat.VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "gems", amount: 0))

        expect {
            _ = RewardVerification.mapVerifiedReward(reward)
        }.to(throwAssertion())
    }

    func testMapNoReward() {
        let mapped = RewardVerification.mapVerifiedReward(.noReward)
        XCTAssertEqual(mapped, .noReward)
    }

    func testMapUnsupportedReward() {
        let mapped = RewardVerification.mapVerifiedReward(.unsupportedReward)
        XCTAssertEqual(mapped, .unsupportedReward)
    }

    func testMapOutcomeVerified() {
        let reward = RevenueCat.VerifiedReward.virtualCurrency(VirtualCurrencyReward(code: "c", amount: 2))
        var sideEffectCallCount = 0
        let originalInvalidation = RewardVerification.SideEffects.invalidateVirtualCurrenciesCache
        RewardVerification.SideEffects.invalidateVirtualCurrenciesCache = {
            sideEffectCallCount += 1
        }
        defer { RewardVerification.SideEffects.invalidateVirtualCurrenciesCache = originalInvalidation }

        let result = RewardVerification.mapOutcome(.verified(reward))

        XCTAssertEqual(sideEffectCallCount, 1)
        XCTAssertNotNil(result.verifiedReward)
        XCTAssertEqual(result.verifiedReward?.virtualCurrency?.code, "c")
        XCTAssertEqual(result.verifiedReward?.virtualCurrency?.amount, 2)
    }

    func testMapOutcomeFailed() {
        var sideEffectCallCount = 0
        let originalInvalidation = RewardVerification.SideEffects.invalidateVirtualCurrenciesCache
        RewardVerification.SideEffects.invalidateVirtualCurrenciesCache = {
            sideEffectCallCount += 1
        }
        defer { RewardVerification.SideEffects.invalidateVirtualCurrenciesCache = originalInvalidation }

        let result = RewardVerification.mapOutcome(.failed)

        XCTAssertTrue(result.isFailed)
        XCTAssertNil(result.verifiedReward)
        XCTAssertEqual(sideEffectCallCount, 0)
    }

    func testMapOutcomeVerifiedNoRewardDoesNotInvalidateVirtualCurrenciesCache() {
        var sideEffectCallCount = 0
        let originalInvalidation = RewardVerification.SideEffects.invalidateVirtualCurrenciesCache
        RewardVerification.SideEffects.invalidateVirtualCurrenciesCache = {
            sideEffectCallCount += 1
        }
        defer { RewardVerification.SideEffects.invalidateVirtualCurrenciesCache = originalInvalidation }

        let result = RewardVerification.mapOutcome(.verified(.noReward))

        XCTAssertNotNil(result.verifiedReward)
        XCTAssertEqual(result.verifiedReward, .noReward)
        XCTAssertEqual(sideEffectCallCount, 0)
    }

    func testMapOutcomeVerifiedUnsupportedRewardDoesNotInvalidateVirtualCurrenciesCache() {
        var sideEffectCallCount = 0
        let originalInvalidation = RewardVerification.SideEffects.invalidateVirtualCurrenciesCache
        RewardVerification.SideEffects.invalidateVirtualCurrenciesCache = {
            sideEffectCallCount += 1
        }
        defer { RewardVerification.SideEffects.invalidateVirtualCurrenciesCache = originalInvalidation }

        let result = RewardVerification.mapOutcome(.verified(.unsupportedReward))

        XCTAssertNotNil(result.verifiedReward)
        XCTAssertEqual(result.verifiedReward, .unsupportedReward)
        XCTAssertEqual(sideEffectCallCount, 0)
    }
}

#endif
