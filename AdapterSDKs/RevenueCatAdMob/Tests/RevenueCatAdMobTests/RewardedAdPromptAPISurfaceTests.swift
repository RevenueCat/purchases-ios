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
                onResult: { result in
                    let _: RewardedAdPromptVerificationResult.Kind = result.kind
                    let _: RewardVerificationResult? = result.rewardVerificationResult
                    let _: RewardedAdPromptError? = result.presentationError
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
                onResult: { result in
                    let _: RewardedAdPromptUnverifiedResult.Kind = result.kind
                    let _: RewardedAdPromptError? = result.presentationError
                },
                content: { _ in Text("Reward") }
            )
            _ = prompt
        }

        _ = makePrompt
    }

    func testMinimalEntryPointsSupportTrailingContentClosure() {
        let makePrompt: @MainActor (RewardedAd) -> Void = { rewardedAd in
            let verifiedResult: (RewardedAdPromptVerificationResult) -> Void = { _ in }
            let unverifiedResult: (RewardedAdPromptUnverifiedResult) -> Void = { _ in }
            let verified = RewardedAdPrompt(ad: rewardedAd, onResult: verifiedResult) { context in
                let _: @MainActor () -> Void = context.accept
                Text("Reward")
            }
            let unverified = RewardedAdPromptWithoutVerification(ad: rewardedAd, onResult: unverifiedResult) { _ in
                Text("Reward")
            }
            let _: RewardedAdPrompt<Text> = verified
            let _: RewardedAdPromptWithoutVerification<Text> = unverified
        }

        _ = makePrompt
    }

    func testBothEntryPointsAcceptRewardedInterstitialAds() {
        let makePrompt: @MainActor (RewardedInterstitialAd) -> Void = { rewardedAd in
            let verifiedResult: (RewardedAdPromptVerificationResult) -> Void = { _ in }
            let unverifiedResult: (RewardedAdPromptUnverifiedResult) -> Void = { _ in }
            let verified = RewardedAdPrompt(ad: rewardedAd, onResult: verifiedResult) { _ in Text("Reward") }
            let unverified = RewardedAdPromptWithoutVerification(ad: rewardedAd, onResult: unverifiedResult) { _ in
                Text("Reward")
            }
            let _: RewardedAdPrompt<Text> = verified
            let _: RewardedAdPromptWithoutVerification<Text> = unverified
        }

        _ = makePrompt
    }

    func testResultKindsRemainAvailableInSwift() {
        let _: RewardedAdPromptError.Code = .adFailedToPresent
        let _: RewardedAdPromptError.Code = .presentationContextUnavailable
        let _: RewardedAdPromptVerificationResult.Kind = .verificationCompleted
        let _: RewardedAdPromptVerificationResult.Kind = .dismissed
        let _: RewardedAdPromptVerificationResult.Kind = .notPresented
        let _: RewardedAdPromptUnverifiedResult.Kind = .rewardEarned
        let _: RewardedAdPromptUnverifiedResult.Kind = .dismissed
        let _: RewardedAdPromptUnverifiedResult.Kind = .notPresented
    }

}
#endif
