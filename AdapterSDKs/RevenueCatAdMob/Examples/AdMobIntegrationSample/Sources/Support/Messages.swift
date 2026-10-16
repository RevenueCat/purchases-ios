import Foundation
import RevenueCat
import RevenueCatAdMob

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
    enum Rewarded {
        static let loading = Message(text: "⏳ Loading ad...", severity: .info, isLoading: true)
        static let readyWithoutVerification = Message(text: "🔓 Ready", severity: .info, isLoading: false)
        static let readyWithVerification = Message(text: "🔐 Ready", severity: .info, isLoading: false)
        static let waitingForReward = Message(text: "⏳ Waiting for reward...", severity: .info, isLoading: false)
        static let verifyingReward = Message(text: "⏳ Verifying reward...", severity: .info, isLoading: true)
        static let loadFailed = Message(text: "❌ Load failed", severity: .error, isLoading: false)
        static let rewardEarned = Message(text: "✅ AdMob reported that the reward was earned", severity: .success,
                                          isLoading: false)
        static let configurationRequired = Message(
            text: "⚠️ Add a valid RevenueCat API key.",
            severity: .warning,
            isLoading: false
        )
        static let dismissedBeforeReward = Message(
            text: "⚠️ Ad dismissed before reward was earned",
            severity: .warning,
            isLoading: false
        )

        static func loadFailed(_ error: Error) -> Message {
            return Message(
                text: "❌ \(error.localizedDescription)",
                severity: .error,
                isLoading: false
            )
        }

        static func notPresented(_ error: RewardedAdPromptError) -> Message {
            return Message(
                text: "⚠️ Ad not presented\n\(error.localizedDescription)",
                severity: .warning,
                isLoading: false
            )
        }

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
        guard let reward = result.verifiedReward else {
            return Self.verificationFailed
        }

        let rewards = [reward] + result.moreRewards
        let lines = rewards.map(Self.verificationLine)
        let severity: Severity = lines.contains { $0.isWarning } ? .warning : .success

        return .init(
            text: (["✅ Verified"] + lines.map { $0.text }).joined(separator: "\n"),
            severity: severity,
            isLoading: false
        )
    }

    private static func verificationLine(for reward: AdReward) -> (text: String, isWarning: Bool) {
        if let virtualCurrency = reward.virtualCurrency {
            return ("🎁 Reward granted: \(virtualCurrency.amount) \(virtualCurrency.code)", false)
        } else if let entitlement = reward.entitlement {
            return ("🎁 Reward granted: entitlement \(entitlement.identifier)", false)
        } else if reward == .noReward {
            return ("ℹ️ No reward", false)
        } else if reward == .unsupportedReward {
            return ("⚠️ Unsupported reward", true)
        } else {
            return ("⚠️ Unhandled reward type", true)
        }
    }
}
