import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class VerifiedRewardedInterstitialAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/6978759866"

    var rewardedInterstitialAd: RewardedInterstitialAd?
    @Published var message = "Not Loaded"

    var canShow: Bool { self.rewardedInterstitialAd != nil }

    func resetSelection() {
        self.rewardedInterstitialAd = nil
        self.message = "Not Loaded"
    }

    func loadAd() {
        self.message = "⏳ Loading ad..."

        RewardedInterstitialAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "rewarded_interstitial_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Rewarded Interstitial failed: \(error.localizedDescription)")
                self.message = "❌ Load failed"
                return
            }

            guard let loadedAd else { return }

            loadedAd.enableRewardVerification()
            print("✅ Rewarded Interstitial loaded (verification)")
            self.rewardedInterstitialAd = loadedAd
            self.message = "🔐 Ready"
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedInterstitialAd else {
            print("⚠️ Rewarded Interstitial not ready")
            return
        }

        self.message = "⏳ Waiting for reward..."
        loadedAd.present(
            from: viewController,
            placement: "rewarded_interstitial_reward_verification_main",
            rewardVerificationStarted: { [weak self] in
                self?.message = "⏳ Verifying reward..."
                print("⏳ Rewarded interstitial verification started")
            },
            rewardVerificationResult: { [weak self] result in
                self?.message = RewardVerificationResultMessage.message(for: result)
                print("✅ Rewarded interstitial verification finished: \(String(describing: result.verifiedReward))")
            }
        )
    }

}

extension VerifiedRewardedInterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        var dismissedBeforeReward = false

        if self.message == "⏳ Waiting for reward..." {
            self.message = "⚠️ Ad dismissed before reward was earned"
            dismissedBeforeReward = true
        }

        if adObject is RewardedInterstitialAd {
            self.rewardedInterstitialAd = nil
            if !dismissedBeforeReward {
                self.message = "Not Loaded"
            }
        }
    }
}
