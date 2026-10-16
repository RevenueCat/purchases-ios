import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
@_spi(Internal) import RevenueCat
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
        dispatcher.verificationCompleted(.verified(.noReward))
        dispatcher.dismissed()

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .verificationCompleted)
        XCTAssertEqual(result.rewardVerificationResult, .failed)
        XCTAssertNil(result.presentationError)
    }

    func testVerificationEnabledWaitsForDismissalAfterVerificationCompletes() throws {
        let verificationResults: [RewardVerificationResult] = [.failed, .verified(.noReward)]
        for verificationResult in verificationResults {
            var receivedResults: [RewardedAdPromptVerificationResult] = []
            let dispatcher = VerifiedRewardResultDispatcher(onResult: { receivedResults.append($0) })

            dispatcher.rewardEarned()
            dispatcher.verificationCompleted(verificationResult)
            dispatcher.verificationCompleted(.failed)

            XCTAssertTrue(receivedResults.isEmpty)

            dispatcher.dismissed()
            dispatcher.dismissed()
            dispatcher.notPresented(.init(code: .adFailedToPresent))

            XCTAssertEqual(receivedResults.count, 1)
            let result = try XCTUnwrap(receivedResults.first)
            XCTAssertEqual(result.kind, .verificationCompleted)
            XCTAssertEqual(result.rewardVerificationResult, verificationResult)
            XCTAssertNil(result.presentationError)
        }
    }

    func testVerificationEnabledDismissalBeforeRewardIsTerminal() throws {
        var receivedResults: [RewardedAdPromptVerificationResult] = []
        let dispatcher = VerifiedRewardResultDispatcher(onResult: {
            receivedResults.append($0)
        })

        dispatcher.dismissed()
        dispatcher.rewardEarned()
        dispatcher.verificationCompleted(.failed)
        dispatcher.dismissed()

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .dismissed)
        XCTAssertNil(result.rewardVerificationResult)
        XCTAssertNil(result.presentationError)
    }

    func testVerificationDisabledWaitsForDismissalAfterRewardIsEarned() throws {
        var receivedResults: [RewardedAdPromptUnverifiedResult] = []
        let dispatcher = UnverifiedRewardResultDispatcher(onResult: {
            receivedResults.append($0)
        })

        dispatcher.rewardEarned()
        dispatcher.rewardEarned()

        XCTAssertTrue(receivedResults.isEmpty)

        dispatcher.dismissed()
        dispatcher.dismissed()

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .rewardEarned)
        XCTAssertNil(result.presentationError)
    }

    func testVerificationDisabledDismissalBeforeRewardIsTerminal() throws {
        var receivedResults: [RewardedAdPromptUnverifiedResult] = []
        let dispatcher = UnverifiedRewardResultDispatcher(onResult: { receivedResults.append($0) })

        dispatcher.dismissed()
        dispatcher.rewardEarned()
        dispatcher.dismissed()

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .dismissed)
        XCTAssertNil(result.presentationError)
    }

    func testVerifiedPresentationFailureIsDeferredAndDeliveredOnlyOnce() async throws {
        let delivered = self.expectation(description: "Presentation failure delivered")
        var receivedResults: [RewardedAdPromptVerificationResult] = []
        var dispatcher: VerifiedRewardResultDispatcher? = .init(onResult: {
            receivedResults.append($0)
            delivered.fulfill()
        })
        let error = RewardedAdPromptError(code: .presentationContextUnavailable)

        dispatcher?.notPresented(error)
        dispatcher?.notPresented(error)
        dispatcher?.dismissed()
        dispatcher?.verificationCompleted(.failed)
        dispatcher = nil

        XCTAssertTrue(receivedResults.isEmpty)
        await self.fulfillment(of: [delivered], timeout: 1)

        XCTAssertEqual(receivedResults.count, 1)
        let result = try XCTUnwrap(receivedResults.first)
        XCTAssertEqual(result.kind, .notPresented)
        XCTAssertEqual(result.presentationError?.code, .presentationContextUnavailable)
        XCTAssertNil(result.rewardVerificationResult)
    }

    func testUnverifiedPresentationFailureIsDeferredAndDeliveredOnlyOnce() async throws {
        let delivered = self.expectation(description: "Presentation failure delivered")
        var receivedResults: [RewardedAdPromptUnverifiedResult] = []
        var dispatcher: UnverifiedRewardResultDispatcher? = .init(onResult: {
            receivedResults.append($0)
            delivered.fulfill()
        })
        let underlyingError = NSError(domain: "test", code: 1)
        let error = RewardedAdPromptError(code: .adFailedToPresent, underlyingError: underlyingError)

        dispatcher?.notPresented(error)
        dispatcher?.notPresented(error)
        dispatcher?.dismissed()
        dispatcher?.rewardEarned()
        dispatcher = nil

        XCTAssertTrue(receivedResults.isEmpty)
        await self.fulfillment(of: [delivered], timeout: 1)

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
