import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class RewardedInterstitialAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/6978759866"

    var rewardedInterstitialAd: RewardedInterstitialAd?
    @Published var message: Message?

    var canShow: Bool { self.rewardedInterstitialAd != nil }

    private var shouldReportDismissedBeforeReward = false
    private var presentingAdObjectID: ObjectIdentifier?

    func resetSelection() {
        self.presentingAdObjectID = nil
        self.shouldReportDismissedBeforeReward = false
        self.rewardedInterstitialAd = nil
        self.message = nil
    }

    func loadAd() {
        self.presentingAdObjectID = nil
        self.message = Message.Rewarded.loading
        self.shouldReportDismissedBeforeReward = false

        RewardedInterstitialAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "rewarded_interstitial_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Rewarded Interstitial failed: \(error.localizedDescription)")
                self.message = Message.Rewarded.loadFailed
                return
            }

            guard let loadedAd else { return }

            print("✅ Rewarded Interstitial loaded")
            self.rewardedInterstitialAd = loadedAd
            self.message = Message.Rewarded.readyWithoutVerification
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedInterstitialAd else {
            print("⚠️ Rewarded Interstitial not ready")
            return
        }

        let presentingAdObjectID = ObjectIdentifier(loadedAd)
        self.presentingAdObjectID = presentingAdObjectID
        self.shouldReportDismissedBeforeReward = true
        self.message = Message.Rewarded.waitingForReward
        loadedAd.present(from: viewController, userDidEarnRewardHandler: { [weak self] in
            guard let self else { return }
            guard self.presentingAdObjectID == presentingAdObjectID else { return }
            let reward = loadedAd.adReward
            self.presentingAdObjectID = nil
            self.shouldReportDismissedBeforeReward = false
            self.message = Message.Rewarded.rewardGranted(amount: reward.amount, type: reward.type)
            print("✅ User earned reward (rewarded interstitial)")
        })
    }

}

extension RewardedInterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        if self.shouldReportDismissedBeforeReward {
            self.presentingAdObjectID = nil
            self.message = Message.Rewarded.dismissedBeforeReward
            self.shouldReportDismissedBeforeReward = false
        }

        if adObject is RewardedInterstitialAd {
            self.rewardedInterstitialAd = nil
        }
    }
}
