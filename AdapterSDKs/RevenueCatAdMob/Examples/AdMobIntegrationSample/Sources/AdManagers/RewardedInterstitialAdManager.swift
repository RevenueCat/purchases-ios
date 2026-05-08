import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class RewardedInterstitialAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/6978759866"

    var rewardedInterstitialAd: RewardedInterstitialAd?
    @Published var status = "Not Loaded"
    @Published var result: String?
    @Published var verificationResult: String?

    private var isWaitingForReward = false
    private var loadMode: RewardVerificationLoadMode = .withoutRewardVerification
    private var loadRequestID = 0

    private enum RewardVerificationLoadMode {
        case withoutRewardVerification
        case withRewardVerification
    }

    func resetSelection() {
        self.loadRequestID += 1
        self.isWaitingForReward = false
        self.rewardedInterstitialAd = nil
        self.status = "Not Loaded"
        self.result = nil
        self.verificationResult = nil
    }

    func loadAd(withRewardVerification: Bool) {
        let mode: RewardVerificationLoadMode = withRewardVerification
            ? .withRewardVerification
            : .withoutRewardVerification

        self.loadRequestID += 1
        let requestID = self.loadRequestID
        self.loadMode = mode
        self.status = "Loading..."
        self.isWaitingForReward = false

        switch mode {
        case .withoutRewardVerification:
            self.result = "⏳ Loading ad..."
            self.verificationResult = nil
        case .withRewardVerification:
            self.result = nil
            self.verificationResult = "⏳ Loading ad..."
        }

        RewardedInterstitialAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "rewarded_interstitial_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }
            guard self.loadRequestID == requestID else { return }

            if let error {
                print("❌ Rewarded Interstitial failed: \(error.localizedDescription)")
                self.status = "Failed"
                if mode == .withRewardVerification {
                    self.verificationResult = "❌ Load failed"
                } else {
                    self.result = "❌ Load failed"
                }
                return
            }

            guard let loadedAd else { return }

            if mode == .withRewardVerification {
                loadedAd.enableRewardVerification()
            }

            print("✅ Rewarded Interstitial loaded")
            self.rewardedInterstitialAd = loadedAd
            self.status = "Ready"

            if mode == .withRewardVerification {
                self.result = nil
                self.verificationResult = "🔐 Loaded"
            } else {
                self.verificationResult = nil
                self.result = "🔓 Loaded"
            }
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedInterstitialAd else {
            print("⚠️ Rewarded Interstitial not ready")
            return
        }

        switch self.loadMode {
        case .withoutRewardVerification:
            self.verificationResult = nil
            self.isWaitingForReward = true
            self.result = "⏳ Waiting for reward..."
            loadedAd.present(from: viewController, userDidEarnRewardHandler: { [weak self] in
                guard let self else { return }
                let reward = loadedAd.adReward
                self.isWaitingForReward = false
                self.result = "🎁 Reward granted: \(reward.amount) \(reward.type)"
                print("✅ User earned reward (rewarded interstitial)")
            })
        case .withRewardVerification:
            self.result = nil
            self.verificationResult = "⏳ Waiting for reward..."
            loadedAd.present(
                from: viewController,
                placement: "rewarded_interstitial_reward_verification_main",
                rewardVerificationStarted: { [weak self] in
                    self?.verificationResult = "⏳ Verifying reward..."
                    print("⏳ Rewarded interstitial verification started")
                },
                rewardVerificationResult: { [weak self] result in
                    self?.verificationResult = RewardVerificationResultMessage.message(for: result)
                    print("✅ Rewarded interstitial verification finished: \(String(describing: result.verifiedReward))")
                }
            )
        }
    }

}

extension RewardedInterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        if self.isWaitingForReward {
            self.result = "⚠️ Ad dismissed before reward was earned"
            self.isWaitingForReward = false
        } else if self.loadMode == .withRewardVerification,
                  self.verificationResult == "⏳ Waiting for reward..." {
            self.verificationResult = "⚠️ Ad dismissed before reward was earned"
        }

        if adObject is RewardedInterstitialAd {
            self.rewardedInterstitialAd = nil
            self.status = "Not Loaded"
        }
    }
}
