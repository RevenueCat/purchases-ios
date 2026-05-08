import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class VerifiedRewardedAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    var rewardedAd: RewardedAd?
    @Published var message: String?

    var canShow: Bool { self.rewardedAd != nil }
    private var isWaitingForReward = false

    func resetSelection() {
        self.rewardedAd = nil
        self.isWaitingForReward = false
        self.message = nil
    }

    func loadAd() {
        self.message = Messages.Rewarded.loading
        self.isWaitingForReward = false

        RewardedAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "rewarded_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Rewarded failed: \(error.localizedDescription)")
                self.message = Messages.Rewarded.loadFailed
                return
            }

            guard let loadedAd else { return }

            loadedAd.enableRewardVerification()
            print("✅ Rewarded loaded (verification)")
            self.rewardedAd = loadedAd
            self.message = Messages.Rewarded.readyWithVerification
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedAd else {
            print("⚠️ Rewarded not ready")
            return
        }

        self.isWaitingForReward = true
        self.message = Messages.Rewarded.waitingForReward
        loadedAd.present(
            from: viewController,
            placement: "rewarded_reward_verification_main",
            rewardVerificationStarted: { [weak self] in
                self?.isWaitingForReward = false
                self?.message = Messages.Rewarded.verifyingReward
                print("⏳ Rewarded verification started")
            },
            rewardVerificationResult: { [weak self] result in
                self?.isWaitingForReward = false
                self?.message = Messages.verificationResultMessage(for: result)
                print("✅ Rewarded verification finished: \(String(describing: result.verifiedReward))")
            }
        )
    }

}

extension VerifiedRewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        if self.isWaitingForReward {
            self.message = Messages.Rewarded.dismissedBeforeReward
            self.isWaitingForReward = false
        }

        if adObject is RewardedAd {
            self.rewardedAd = nil
        }
    }
}
