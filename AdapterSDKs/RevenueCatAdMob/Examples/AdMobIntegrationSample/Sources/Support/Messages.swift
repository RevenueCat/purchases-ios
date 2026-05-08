import Foundation
@_spi(Experimental) import RevenueCatAdMob

enum Messages {

    static let loading = "Loading..."
    static let ready = "Ready"
    static let failed = "Failed"

    enum Rewarded {
        static let loading = "⏳ Loading ad..."
        static let readyWithoutVerification = "🔓 Ready"
        static let readyWithVerification = "🔐 Ready"
        static let waitingForReward = "⏳ Waiting for reward..."
        static let verifyingReward = "⏳ Verifying reward..."
        static let loadFailed = "❌ Load failed"
        static let dismissedBeforeReward = "⚠️ Ad dismissed before reward was earned"

        static func rewardGranted(amount: NSDecimalNumber, type: String) -> String {
            return """
            ✅ Reward granted
            🎁 \(amount) \(type)
            """
        }
    }

    static func isLoading(_ message: String?) -> Bool {
        return message == Self.loading || message == Rewarded.loading
    }

    static func verificationResultMessage(for result: RewardVerificationResult) -> String {
        guard result.isVerified, let verifiedReward = result.verifiedReward else {
            return "❌ Verification failed"
        }

        if let virtualCurrency = verifiedReward.virtualCurrency {
            return """
            ✅ Verified
            🎁 Reward granted: \(virtualCurrency.amount) \(virtualCurrency.code)
            """
        } else if verifiedReward == .noReward {
            return """
            ✅ Verified
            ℹ️ No reward
            """
        } else {
            return """
            ✅ Verified
            ⚠️ Unsupported reward
            """
        }
    }

}
