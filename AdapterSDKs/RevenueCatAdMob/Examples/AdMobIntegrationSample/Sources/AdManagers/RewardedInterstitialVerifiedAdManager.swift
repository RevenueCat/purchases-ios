import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class RewardedInterstitialVerifiedAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/6978759866"

    var rewardedInterstitialAd: RewardedInterstitialAd?
    @Published var message = "Not Loaded"
    @Published var verificationResult: String?

    func resetSelection() {
        self.rewardedInterstitialAd = nil
        self.message = "Not Loaded"
        self.verificationResult = nil
    }

    func loadAd() {
        self.message = "Loading..."
        self.verificationResult = "⏳ Loading ad..."

        RewardedInterstitialAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "rewarded_interstitial_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Rewarded Interstitial failed: \(error.localizedDescription)")
                self.message = "Failed"
                self.verificationResult = "❌ Load failed"
                return
            }

            guard let loadedAd else { return }

            loadedAd.enableRewardVerification()
            print("✅ Rewarded Interstitial loaded (verification)")
            self.rewardedInterstitialAd = loadedAd
            self.message = "Ready"
            self.verificationResult = "🔐 Loaded"
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedInterstitialAd else {
            print("⚠️ Rewarded Interstitial not ready")
            return
        }

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

extension RewardedInterstitialVerifiedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        if self.verificationResult == "⏳ Waiting for reward..." {
            self.verificationResult = "⚠️ Ad dismissed before reward was earned"
        }

        if adObject is RewardedInterstitialAd {
            self.rewardedInterstitialAd = nil
            self.message = "Not Loaded"
        }
    }
}
