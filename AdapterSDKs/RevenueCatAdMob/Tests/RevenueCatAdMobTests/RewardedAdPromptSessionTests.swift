import XCTest

#if ENABLE_CONFIGURED_AD_REWARDS && os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RewardedAdPromptSessionTests: AdapterTestCase {

    @MainActor
    func testConsumesPromptShownOnlyOnceUntilAcceptance() {
        let session = RewardedAdPromptSession()

        XCTAssertTrue(session.consumePromptShown())
        XCTAssertFalse(session.consumePromptShown())

        session.resetAfterAcceptance()

        XCTAssertTrue(session.consumePromptShown())
        XCTAssertFalse(session.consumePromptShown())
    }

    func testPromptErrorDescriptionsExplainEachFailure() {
        let purchasesError = RewardedAdPromptError(code: .purchasesNotConfigured)
        let rewardsError = RewardedAdPromptError(code: .configuredRewardsUnavailable)
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Network unavailable"
        ])
        let adError = RewardedAdPromptError(code: .adFailedToLoad, underlyingError: underlyingError)

        XCTAssertEqual(purchasesError.localizedDescription, "RevenueCat is not configured.")
        XCTAssertEqual(rewardsError.localizedDescription, "No configured rewards are available for this ad unit.")
        XCTAssertEqual(adError.localizedDescription, "The rewarded ad failed to load: Network unavailable")
    }

}
#endif
