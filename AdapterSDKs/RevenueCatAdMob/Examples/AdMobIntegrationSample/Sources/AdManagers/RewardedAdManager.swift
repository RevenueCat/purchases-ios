import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class RewardedAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    var rewardedAd: RewardedAd?
    @Published var message = "Not Loaded"

    var canShow: Bool { self.rewardedAd != nil }

    private var isWaitingForReward = false

    func resetSelection() {
        self.isWaitingForReward = false
        self.rewardedAd = nil
        self.message = "Not Loaded"
    }

    func loadAd() {
        self.message = "⏳ Loading ad..."
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
                self.message = "❌ Load failed"
                return
            }

            guard let loadedAd else { return }

            print("✅ Rewarded loaded")
            self.rewardedAd = loadedAd
            self.message = "🔓 Ready"
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedAd else {
            print("⚠️ Rewarded not ready")
            return
        }

        self.isWaitingForReward = true
        self.message = "⏳ Waiting for reward..."
        loadedAd.present(from: viewController, userDidEarnRewardHandler: { [weak self] in
            guard let self else { return }
            let reward = loadedAd.adReward
            self.isWaitingForReward = false
            self.message = """
            ✅ Reward granted
            🎁 \(reward.amount) \(reward.type)
            """
            print("✅ User earned reward")
        })
    }

}

extension RewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        var dismissedBeforeReward = false

        if self.isWaitingForReward {
            self.message = "⚠️ Ad dismissed before reward was earned"
            self.isWaitingForReward = false
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
