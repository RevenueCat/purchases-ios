import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import GoogleMobileAds
import RevenueCat
import RevenueCatAdMob
import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptAPISurfaceTests: AdapterTestCase {

    // Keep construction inside uninvoked closures so these checks also support the API-only stubs.
    func testVerifiedEntryPointAcceptsLoadedAdInSwift() {
        let makePrompt: @MainActor (RewardedAd) -> Void = { rewardedAd in
            let prompt: RewardedAdPrompt<Text> = RewardedAdPrompt(
                session: RewardedAdPromptSession(),
                ad: rewardedAd,
                placement: "placement",
                onVerificationCompleted: { result in
                    let _: RewardVerificationResult = result
                },
                onDismiss: {},
                onPresentationFailed: { error in
                    let _: RewardedAdPromptError = error
                },
                content: { context in
                    let _: ConfiguredAdRewards? = context.rewardConfiguration
                    let _: @MainActor () -> Void = context.accept
                    return Text("Reward")
                }
            )
            _ = prompt
        }

        _ = makePrompt
    }

    func testUnverifiedEntryPointAcceptsLoadedAdInSwift() {
        let makePrompt: @MainActor (RewardedAd) -> Void = { rewardedAd in
            let prompt: RewardedAdPromptWithoutVerification<Text> = RewardedAdPromptWithoutVerification(
                ad: rewardedAd,
                onRewardEarned: {},
                onDismiss: {},
                onPresentationFailed: { error in
                    let _: RewardedAdPromptError = error
                },
                content: { (context: RewardedAdPromptUnverifiedContext) in
                    let _: @MainActor () -> Void = context.accept
                    return Text("App-defined reward")
                }
            )
            _ = prompt
        }

        _ = makePrompt
    }

    func testMinimalEntryPointsSupportTrailingContentClosure() {
        let makePrompt: @MainActor (RewardedAd) -> Void = { rewardedAd in
            let verifiedResult: (RewardVerificationResult) -> Void = { _ in }
            let rewardEarned: () -> Void = {}
            let verified = RewardedAdPrompt(ad: rewardedAd, onVerificationCompleted: verifiedResult) { context in
                let _: @MainActor () -> Void = context.accept
                Text("Reward")
            }
            let unverified = RewardedAdPromptWithoutVerification(
                ad: rewardedAd, onRewardEarned: rewardEarned
            ) { context in
                let _: RewardedAdPromptUnverifiedContext = context
                let _: @MainActor () -> Void = context.accept
                Text("Reward")
            }
            let _: RewardedAdPrompt<Text> = verified
            let _: RewardedAdPromptWithoutVerification<Text> = unverified
        }

        _ = makePrompt
    }

    func testBothEntryPointsAcceptRewardedInterstitialAds() {
        let makePrompt: @MainActor (RewardedInterstitialAd) -> Void = { rewardedAd in
            let verifiedResult: (RewardVerificationResult) -> Void = { _ in }
            let rewardEarned: () -> Void = {}
            let verified = RewardedAdPrompt(ad: rewardedAd, onVerificationCompleted: verifiedResult) { _ in
                Text("Reward")
            }
            let unverified = RewardedAdPromptWithoutVerification(
                ad: rewardedAd, onRewardEarned: rewardEarned
            ) { context in
                let _: RewardedAdPromptUnverifiedContext = context
                let _: @MainActor () -> Void = context.accept
                Text("Reward")
            }
            let _: RewardedAdPrompt<Text> = verified
            let _: RewardedAdPromptWithoutVerification<Text> = unverified
        }

        _ = makePrompt
    }

    func testPresentationErrorCodesRemainAvailableInSwift() {
        let _: RewardedAdPromptError.Code = .adFailedToPresent
        let _: RewardedAdPromptError.Code = .presentationContextUnavailable
    }

}
#endif
