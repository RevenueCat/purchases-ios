import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptResultTests: AdapterTestCase {

    func testVerificationEnabledWaitsForVerificationAfterRewardIsEarned() throws {
        var receivedResults: [RewardedAdPromptVerificationResult] = []
        let dispatcher = VerifiedRewardResultDispatcher(onResult: {
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
        let dispatcher = VerifiedRewardResultDispatcher(onResult: {
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
        let dispatcher = UnverifiedRewardResultDispatcher(onResult: {
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
        let dispatcher = UnverifiedRewardResultDispatcher(onResult: {
            receivedResults.append($0)
        })
        let underlyingError = NSError(domain: "test", code: 1)
        let error = RewardedAdPromptError(code: .adFailedToPresent, underlyingError: underlyingError)

        dispatcher.notPresented(error)
        dispatcher.dismissed()
        dispatcher.rewardEarned()

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .notPresented)
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

    func testPromptErrorDescriptionExplainsMissingPresentationContext() {
        let error = RewardedAdPromptError(code: .presentationContextUnavailable)

        XCTAssertEqual(
            error.localizedDescription,
            "The rewarded ad could not be presented because no attached presentation controller is available."
        )
    }

}
#endif
