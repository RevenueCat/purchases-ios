import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class VerifiedRewardedInterstitialAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/6978759866"

    var rewardedInterstitialAd: RewardedInterstitialAd?
    @Published var message = Messages.notLoaded

    var canShow: Bool { self.rewardedInterstitialAd != nil }

    func resetSelection() {
        self.rewardedInterstitialAd = nil
        self.message = Messages.notLoaded
    }

    func loadAd() {
        self.message = Messages.Rewarded.loading

        RewardedInterstitialAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "rewarded_interstitial_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Rewarded Interstitial failed: \(error.localizedDescription)")
                self.message = Messages.Rewarded.loadFailed
                return
            }

            guard let loadedAd else { return }

            loadedAd.enableRewardVerification()
            print("✅ Rewarded Interstitial loaded (verification)")
            self.rewardedInterstitialAd = loadedAd
            self.message = Messages.Rewarded.readyWithVerification
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedInterstitialAd else {
            print("⚠️ Rewarded Interstitial not ready")
            return
        }

        self.message = Messages.Rewarded.waitingForReward
        loadedAd.present(
            from: viewController,
            placement: "rewarded_interstitial_reward_verification_main",
            rewardVerificationStarted: { [weak self] in
                self?.message = Messages.Rewarded.verifyingReward
                print("⏳ Rewarded interstitial verification started")
            },
            rewardVerificationResult: { [weak self] result in
                self?.message = Messages.verificationResultMessage(for: result)
                print("✅ Rewarded interstitial verification finished: \(String(describing: result.verifiedReward))")
            }
        )
    }

}

extension VerifiedRewardedInterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        var dismissedBeforeReward = false

        if self.message == Messages.Rewarded.waitingForReward {
            self.message = Messages.Rewarded.dismissedBeforeReward
            dismissedBeforeReward = true
        }

        if adObject is RewardedInterstitialAd {
            self.rewardedInterstitialAd = nil
            if !dismissedBeforeReward {
                self.message = Messages.notLoaded
            }
        }
    }
}
