import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class VerifiedRewardedAdManager: NSObject, ObservableObject {

    private static let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    @Published private(set) var rewardedAd: RewardedAd?
    @Published var message: Message?

    var canShow: Bool { self.rewardedAd != nil }
    private var shouldReportDismissedBeforeReward = false
    private var presentingAdObjectID: ObjectIdentifier?

    func resetSelection() {
        self.presentingAdObjectID = nil
        self.rewardedAd = nil
        self.shouldReportDismissedBeforeReward = false
        self.message = nil
    }

    func loadAd() {
        self.presentingAdObjectID = nil
        self.message = Message.Rewarded.loading
        self.shouldReportDismissedBeforeReward = false

        RewardedAd.loadAndTrack(
            withAdUnitID: Self.adUnitID,
            request: Request(),
            placement: "rewarded_main",
            fullScreenContentDelegate: self
        ) { [weak self] loadedAd, error in
            guard let self else { return }

            if let error {
                print("❌ Rewarded failed: \(error.localizedDescription)")
                self.message = Message.Rewarded.loadFailed
                return
            }

            guard let loadedAd else { return }

            loadedAd.enableRewardVerification()
            print("✅ Rewarded loaded (verification)")
            self.rewardedAd = loadedAd
            self.message = Message.Rewarded.readyWithVerification
        }
    }

    @MainActor
    func showAd(from viewController: UIViewController) {
        guard let loadedAd = self.rewardedAd else {
            print("⚠️ Rewarded not ready")
            return
        }

        let presentingAdObjectID = ObjectIdentifier(loadedAd)
        self.presentingAdObjectID = presentingAdObjectID
        self.shouldReportDismissedBeforeReward = true
        self.message = Message.Rewarded.waitingForReward
        loadedAd.present(
            from: viewController,
            placement: "rewarded_reward_verification_main",
            rewardVerificationStarted: { [weak self] in
                guard let self, self.presentingAdObjectID == presentingAdObjectID else { return }
                self.shouldReportDismissedBeforeReward = false
                self.message = Message.Rewarded.verifyingReward
                print("⏳ Rewarded verification started")
            },
            rewardVerificationCompleted: { [weak self] result in
                guard let self, self.presentingAdObjectID == presentingAdObjectID else { return }
                self.presentingAdObjectID = nil
                self.shouldReportDismissedBeforeReward = false
                self.rewardedAd = nil
                self.message = Message.forVerificationResult(result)
                print("✅ Rewarded verification finished: \(String(describing: result.verifiedReward))")
            }
        )
    }

}

extension VerifiedRewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        if self.shouldReportDismissedBeforeReward {
            self.presentingAdObjectID = nil
            self.message = Message.Rewarded.dismissedBeforeReward
            self.shouldReportDismissedBeforeReward = false
        }

        if adObject is RewardedAd {
            self.rewardedAd = nil
        }
    }
}
