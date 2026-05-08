import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class VerifiedRewardedAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    var rewardedAd: RewardedAd?
    @Published var message = "Not Loaded"
    @Published var verificationResult: String?

    func resetSelection() {
        self.rewardedAd = nil
        self.message = "Not Loaded"
        self.verificationResult = nil
    }

    func loadAd() {
        self.message = "Loading..."
        self.verificationResult = "⏳ Loading ad..."

        RewardedAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "rewarded_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Rewarded failed: \(error.localizedDescription)")
                self.message = "Failed"
                self.verificationResult = "❌ Load failed"
                return
            }

            guard let loadedAd else { return }

            loadedAd.enableRewardVerification()
            print("✅ Rewarded loaded (verification)")
            self.rewardedAd = loadedAd
            self.message = "Ready"
            self.verificationResult = "🔐 Loaded"
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedAd else {
            print("⚠️ Rewarded not ready")
            return
        }

        self.verificationResult = "⏳ Waiting for reward..."
        loadedAd.present(
            from: viewController,
            placement: "rewarded_reward_verification_main",
            rewardVerificationStarted: { [weak self] in
                self?.verificationResult = "⏳ Verifying reward..."
                print("⏳ Rewarded verification started")
            },
            rewardVerificationResult: { [weak self] result in
                self?.verificationResult = RewardVerificationResultMessage.message(for: result)
                print("✅ Rewarded verification finished: \(String(describing: result.verifiedReward))")
            }
        )
    }

}

extension VerifiedRewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        if self.verificationResult == "⏳ Waiting for reward..." {
            self.verificationResult = "⚠️ Ad dismissed before reward was earned"
        }

        if adObject is RewardedAd {
            self.rewardedAd = nil
            self.message = "Not Loaded"
        }
    }
}
