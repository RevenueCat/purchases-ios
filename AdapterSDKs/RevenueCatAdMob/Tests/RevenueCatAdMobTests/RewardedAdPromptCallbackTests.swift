import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob
import UIKit

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptCallbackTests: AdapterTestCase {

    func testVerificationAndDismissalAreDeliveredOnceInEitherOrder() {
        for dismissesFirst in [true, false] {
            for result: RewardVerificationResult in [.failed, .verified(.noReward)] {
                var events: [String] = []
                let callbacks = makeVerifiedPromptCallbacks(onVerificationCompleted: {
                    XCTAssertEqual($0, result)
                    events.append("verification")
                }, onDismiss: {
                    events.append("dismissal")
                }, onPresentationFailed: { _ in
                    XCTFail("A presented ad cannot fail to present")
                })

                if dismissesFirst {
                    callbacks.dismissed()
                    callbacks.dismissed()
                    XCTAssertEqual(events, ["dismissal"])
                    callbacks.verificationCompleted(result)
                } else {
                    callbacks.verificationCompleted(result)
                    XCTAssertEqual(events, ["verification"])
                    callbacks.dismissed()
                }
                callbacks.verificationCompleted(.verified(.noReward))
                callbacks.dismissed()
                callbacks.notPresented(.init(code: .adFailedToPresent, underlyingError: nil))

                XCTAssertEqual(events, dismissesFirst ? ["dismissal", "verification"] : ["verification", "dismissal"])
            }
        }
    }

    func testEarnedRewardAndDismissalAreDeliveredOnceInEitherOrder() {
        for dismissesFirst in [true, false] {
            var events: [String] = []
            let callbacks = makeUnverifiedPromptCallbacks(onRewardEarned: {
                events.append("reward")
            }, onDismiss: {
                events.append("dismissal")
            }, onPresentationFailed: { _ in
                XCTFail("A presented ad cannot fail to present")
            })

            if dismissesFirst {
                callbacks.dismissed()
                callbacks.dismissed()
                XCTAssertEqual(events, ["dismissal"])
                callbacks.rewardEarned()
            } else {
                callbacks.rewardEarned()
                XCTAssertEqual(events, ["reward"])
                callbacks.dismissed()
            }
            callbacks.rewardEarned()
            callbacks.dismissed()
            callbacks.notPresented(.init(code: .adFailedToPresent, underlyingError: nil))

            XCTAssertEqual(events, dismissesFirst ? ["dismissal", "reward"] : ["reward", "dismissal"])
        }
    }

    func testDismissalWithoutRewardDoesNotInventRewardOutcomeForEitherMode() {
        for verified in [true, false] {
            var dismissalCount = 0
            let onDismiss: @MainActor () -> Void = { dismissalCount += 1 }
            let callbacks: any RewardedAdPromptCallbackDispatching
            if verified {
                callbacks = makeVerifiedPromptCallbacks(onVerificationCompleted: { _ in
                    XCTFail("Dismissal does not complete verification")
                }, onDismiss: onDismiss)
            } else {
                callbacks = makeUnverifiedPromptCallbacks(onRewardEarned: {
                    XCTFail("Dismissal does not earn a reward")
                }, onDismiss: onDismiss)
            }

            callbacks.dismissed()
            callbacks.dismissed()

            XCTAssertEqual(dismissalCount, 1)
        }
    }

    func testPresentationFailureIsDeferredAndExcludesOtherCallbacksForBothModes() async throws {
        for verified in [true, false] {
            let delivered = self.expectation(description: "Presentation failure delivered")
            var errors: [RewardedAdPromptError] = []
            let underlyingError = NSError(domain: "test", code: 1)
            let onFailure: @MainActor (RewardedAdPromptError) -> Void = {
                XCTAssertTrue(Thread.isMainThread)
                errors.append($0)
                delivered.fulfill()
            }
            let onDismiss: @MainActor () -> Void = { XCTFail("A failed presentation cannot be dismissed") }
            var callbacks: (any RewardedAdPromptCallbackDispatching)?
            if verified {
                callbacks = makeVerifiedPromptCallbacks(onVerificationCompleted: { _ in
                    XCTFail("A failed presentation cannot earn a reward")
                }, onDismiss: onDismiss, onPresentationFailed: onFailure)
            } else {
                callbacks = makeUnverifiedPromptCallbacks(onRewardEarned: {
                    XCTFail("A failed presentation cannot earn a reward")
                }, onDismiss: onDismiss, onPresentationFailed: onFailure)
            }
            let rewardedAd = MockRewardedAdPromptAd()
            callbacks?.present(rewardedAd, from: UIViewController())

            callbacks?.notPresented(.init(code: .adFailedToPresent, underlyingError: underlyingError))
            callbacks?.notPresented(.init(code: .presentationContextUnavailable, underlyingError: nil))
            callbacks?.dismissed()
            rewardedAd.rewardEarned?()
            rewardedAd.verificationCompleted?(.failed)
            callbacks = nil

            XCTAssertTrue(errors.isEmpty)
            await self.fulfillment(of: [delivered], timeout: 1)

            XCTAssertEqual(errors.count, 1)
            XCTAssertEqual(errors.first?.code, .adFailedToPresent)
            XCTAssertEqual(errors.first?.underlyingError as NSError?, underlyingError)
        }
    }

    func testOmittedDismissalHandlerStillAllowsLaterRewardForBothModes() {
        var verifiedResults: [RewardVerificationResult] = []
        let verified = makeVerifiedPromptCallbacks(onVerificationCompleted: { verifiedResults.append($0) })
        verified.dismissed()
        verified.verificationCompleted(.verified(.noReward))
        XCTAssertEqual(verifiedResults, [.verified(.noReward)])

        var rewardCount = 0
        let unverified = makeUnverifiedPromptCallbacks(onRewardEarned: { rewardCount += 1 })
        unverified.dismissed()
        unverified.rewardEarned()
        XCTAssertEqual(rewardCount, 1)
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
        let error = RewardedAdPromptError(code: .presentationContextUnavailable, underlyingError: nil)

        XCTAssertEqual(
            error.localizedDescription,
            "The rewarded ad could not be presented because no attached presentation controller is available."
        )
    }

}
#endif
