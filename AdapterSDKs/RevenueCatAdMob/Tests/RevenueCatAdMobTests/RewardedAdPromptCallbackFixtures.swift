#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
func makeVerifiedPromptCallbacks(
    onVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void = { _ in },
    onDismiss: (@MainActor () -> Void)? = nil,
    onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)? = nil
) -> VerifiedRewardCallbackDispatcher {
    return .init(
        onVerificationCompleted: onVerificationCompleted,
        onDismiss: onDismiss,
        onPresentationFailed: onPresentationFailed
    )
}

@available(iOS 15.0, *)
@MainActor
func makeUnverifiedPromptCallbacks(
    onRewardEarned: @escaping @MainActor () -> Void = {},
    onDismiss: (@MainActor () -> Void)? = nil,
    onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)? = nil
) -> UnverifiedRewardCallbackDispatcher {
    return .init(onRewardEarned: onRewardEarned, onDismiss: onDismiss, onPresentationFailed: onPresentationFailed)
}
#endif
