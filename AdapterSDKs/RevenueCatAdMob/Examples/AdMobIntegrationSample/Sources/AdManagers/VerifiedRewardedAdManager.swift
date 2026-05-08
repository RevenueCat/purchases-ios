import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class VerifiedRewardedAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    var rewardedAd: RewardedAd?
    @Published var message = "Not Loaded"

    var canShow: Bool { self.rewardedAd != nil }

    func resetSelection() {
        self.rewardedAd = nil
        self.message = "Not Loaded"
    }

    func loadAd() {
        self.message = "⏳ Loading ad..."

        RewardedAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "rewarded_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Rewarded failed: \(error.localizedDescription)")
                self.message = "❌ Load failed"
                return
            }

            guard let loadedAd else { return }

            loadedAd.enableRewardVerification()
            print("✅ Rewarded loaded (verification)")
            self.rewardedAd = loadedAd
            self.message = "🔐 Ready"
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedAd else {
            print("⚠️ Rewarded not ready")
            return
        }

        self.message = "⏳ Waiting for reward..."
        loadedAd.present(
            from: viewController,
            placement: "rewarded_reward_verification_main",
            rewardVerificationStarted: { [weak self] in
                self?.message = "⏳ Verifying reward..."
                print("⏳ Rewarded verification started")
            },
            rewardVerificationResult: { [weak self] result in
                self?.message = RewardVerificationResultMessage.message(for: result)
                print("✅ Rewarded verification finished: \(String(describing: result.verifiedReward))")
            }
        )
    }

}

extension VerifiedRewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        var dismissedBeforeReward = false

        if self.message == "⏳ Waiting for reward..." {
            self.message = "⚠️ Ad dismissed before reward was earned"
            dismissedBeforeReward = true
        }

        if adObject is RewardedAd {
            self.rewardedAd = nil
            if !dismissedBeforeReward {
                self.message = "Not Loaded"
            }
        }
    }
}
