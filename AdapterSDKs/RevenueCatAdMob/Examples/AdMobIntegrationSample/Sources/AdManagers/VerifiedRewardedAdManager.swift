import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

final class VerifiedRewardedAdManager: NSObject, ObservableObject {

    private static var adUnitID: String {
        return Constants.configuredAdUnitID(
            forOverrideKey: "RC_REWARDED_AD_UNIT_ID_OVERRIDE",
            defaultValue: "ca-app-pub-3940256099942544/1712485313"
        )
    }

    var rewardedAd: RewardedAd?
    @Published var message: String?

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
        self.message = Messages.Rewarded.loading
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

        let presentingAdObjectID = ObjectIdentifier(loadedAd)
        self.presentingAdObjectID = presentingAdObjectID
        self.shouldReportDismissedBeforeReward = true
        self.message = Messages.Rewarded.waitingForReward
        loadedAd.present(
            from: viewController,
            placement: "rewarded_reward_verification_main",
            rewardVerificationStarted: { [weak self] in
                guard let self, self.presentingAdObjectID == presentingAdObjectID else { return }
                self.shouldReportDismissedBeforeReward = false
                self.message = Messages.Rewarded.verifyingReward
                print("⏳ Rewarded verification started")
            },
            rewardVerificationResult: { [weak self] result in
                guard let self, self.presentingAdObjectID == presentingAdObjectID else { return }
                self.presentingAdObjectID = nil
                self.shouldReportDismissedBeforeReward = false
                self.message = Messages.verificationResultMessage(for: result)
                print("✅ Rewarded verification finished: \(String(describing: result.verifiedReward))")
            }
        )
    }

}

extension VerifiedRewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ adObject: any FullScreenPresentingAd) {
        if self.shouldReportDismissedBeforeReward {
            self.presentingAdObjectID = nil
            self.message = Messages.Rewarded.dismissedBeforeReward
            self.shouldReportDismissedBeforeReward = false
        }

        if adObject is RewardedAd {
            self.rewardedAd = nil
        }
    }
}
