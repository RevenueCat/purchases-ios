import Foundation
@_spi(Experimental) import RevenueCatAdMob

struct Message: Equatable {
    let text: String
    let severity: Severity
    let isLoading: Bool
    enum Severity {
        case info
        case success
        case warning
        case error
    }

    static let loading = Message(text: "Loading...", severity: .info, isLoading: true)
    static let ready = Message(text: "Ready", severity: .info, isLoading: false)
    static let failed = Message(text: "Failed", severity: .error, isLoading: false)
    static let verificationFailed = Message(text: "❌ Verification failed", severity: .error, isLoading: false)
    private static let verificationRewardGrantedTemplate = """
    ✅ Verified
    🎁 Reward granted: %@ %@
    """
    private static let verificationNoRewardText = """
    ✅ Verified
    ℹ️ No reward
    """
    private static let verificationUnsupportedRewardText = """
    ✅ Verified
    ⚠️ Unsupported reward
    """

    enum Rewarded {
        static let loading = Message(text: "⏳ Loading ad...", severity: .info, isLoading: true)
        static let readyWithoutVerification = Message(text: "🔓 Ready", severity: .info, isLoading: false)
        static let readyWithVerification = Message(text: "🔐 Ready", severity: .info, isLoading: false)
        static let waitingForReward = Message(text: "⏳ Waiting for reward...", severity: .info, isLoading: false)
        static let verifyingReward = Message(text: "⏳ Verifying reward...", severity: .info, isLoading: false)
        static let loadFailed = Message(text: "❌ Load failed", severity: .error, isLoading: false)
        static let dismissedBeforeReward = Message(
            text: "⚠️ Ad dismissed before reward was earned",
            severity: .warning,
            isLoading: false
        )

        static func rewardGranted(amount: NSDecimalNumber, type: String) -> Message {
            return .init(
                text: """
                ✅ Reward granted
                🎁 \(amount) \(type)
                """,
                severity: .success,
                isLoading: false
            )
        }
    }

    static func isLoading(_ message: Message?) -> Bool {
        return message?.isLoading == true
    }

    static func forVerificationResult(_ result: RewardVerificationResult) -> Message {
        guard result.isVerified, let verifiedReward = result.verifiedReward else {
            return Self.verificationFailed
        }

        if let virtualCurrency = verifiedReward.virtualCurrency {
            return .init(
                text: String(
                    format: Self.verificationRewardGrantedTemplate,
                    "\(virtualCurrency.amount)",
                    virtualCurrency.code
                ),
                severity: .success,
                isLoading: false
            )
        } else if verifiedReward == .noReward {
            return .init(
                text: Self.verificationNoRewardText,
                severity: .success,
                isLoading: false
            )
        } else {
            return .init(
                text: Self.verificationUnsupportedRewardText,
                severity: .warning,
                isLoading: false
            )
        }
    }
}
