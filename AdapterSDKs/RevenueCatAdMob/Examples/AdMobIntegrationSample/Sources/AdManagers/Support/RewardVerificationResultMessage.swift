import Foundation
@_spi(Experimental) import RevenueCatAdMob

enum RewardVerificationResultMessage {

    static func message(for result: RewardVerificationResult) -> String {
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
