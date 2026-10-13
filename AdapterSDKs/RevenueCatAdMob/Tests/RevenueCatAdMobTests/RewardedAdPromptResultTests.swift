import XCTest

#if ENABLE_CONFIGURED_AD_REWARDS && os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptResultTests: AdapterTestCase {

    func testVerificationEnabledWaitsForVerificationAfterRewardIsEarned() throws {
        var receivedResults: [RewardedAdPromptVerificationResult] = []
        let dispatcher = RewardedAdPromptResultDispatcher(mode: .verificationEnabled {
            receivedResults.append($0)
        })

        dispatcher.rewardEarned()
        dispatcher.dismissed()

        XCTAssertTrue(receivedResults.isEmpty)

        dispatcher.verificationCompleted(.failed)

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .verificationCompleted)
        XCTAssertEqual(result.rewardVerificationResult, .failed)
        XCTAssertNil(result.presentationError)
    }

    func testVerificationEnabledDismissalBeforeRewardIsTerminal() throws {
        var receivedResults: [RewardedAdPromptVerificationResult] = []
        let dispatcher = RewardedAdPromptResultDispatcher(mode: .verificationEnabled {
            receivedResults.append($0)
        })

        dispatcher.dismissed()
        dispatcher.verificationCompleted(.failed)

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .dismissed)
        XCTAssertNil(result.rewardVerificationResult)
        XCTAssertNil(result.presentationError)
    }

    func testVerificationDisabledRewardEarnedIsTerminal() throws {
        var receivedResults: [RewardedAdPromptUnverifiedResult] = []
        let dispatcher = RewardedAdPromptResultDispatcher(mode: .verificationDisabled {
            receivedResults.append($0)
        })

        dispatcher.rewardEarned()
        dispatcher.dismissed()

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .rewardEarned)
        XCTAssertNil(result.presentationError)
    }

    func testPresentationFailureIsDeliveredOnlyOnce() throws {
        var receivedResults: [RewardedAdPromptUnverifiedResult] = []
        let dispatcher = RewardedAdPromptResultDispatcher(mode: .verificationDisabled {
            receivedResults.append($0)
        })
        let underlyingError = NSError(domain: "test", code: 1)
        let error = RewardedAdPromptError(code: .adFailedToPresent, underlyingError: underlyingError)

        dispatcher.presentationFailed(error)
        dispatcher.dismissed()
        dispatcher.rewardEarned()

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .presentationFailed)
        XCTAssertEqual(result.presentationError?.code, .adFailedToPresent)
        XCTAssertEqual(result.presentationError?.underlyingError as NSError?, underlyingError)
    }

    func testPromptErrorDescriptionExplainsPresentationFailure() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "View controller unavailable"
        ])
        let error = RewardedAdPromptError(code: .adFailedToPresent, underlyingError: underlyingError)

        XCTAssertEqual(
            error.localizedDescription,
            "The rewarded ad failed to present: View controller unavailable"
        )
    }

}
#endif
