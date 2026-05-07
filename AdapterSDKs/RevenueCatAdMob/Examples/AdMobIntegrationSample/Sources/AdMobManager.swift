// swiftlint:disable:next blanket_disable_command
// swiftlint:disable identifier_name
// swiftlint:disable file_length type_body_length
import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

class AdMobManager: NSObject, ObservableObject {

    var bannerView: BannerView?
    var errorTestBannerView: BannerView?
    var interstitialAd: InterstitialAd?
    var appOpenAd: AppOpenAd?
    var rewardedAd: RewardedAd?
    var rewardedInterstitialAd: RewardedInterstitialAd?
    var nativeAdLoader: AdLoader?
    var nativeVideoAdLoader: AdLoader?

    @Published var nativeAd: NativeAd?
    @Published var nativeVideoAd: NativeAd?

    @Published var interstitialStatus = "Not Loaded"
    @Published var appOpenStatus = "Not Loaded"
    @Published var rewardedStatus = "Not Loaded"
    @Published var rewardedResult: String?
    @Published var rewardedVerificationResult: String?
    @Published var rewardedInterstitialStatus = "Not Loaded"
    @Published var rewardedInterstitialResult: String?
    @Published var rewardedInterstitialVerificationResult: String?
    @Published var nativeAdStatus = "Not Loaded"
    @Published var nativeVideoAdStatus = "Not Loaded"
    private var isWaitingForRewardedReward = false
    private var isWaitingForRewardedInterstitialReward = false
    private var rewardedLoadMode: RewardVerificationLoadMode = .withoutRewardVerification
    private var rewardedInterstitialLoadMode: RewardVerificationLoadMode = .withoutRewardVerification

    private enum RewardVerificationLoadMode {
        case withoutRewardVerification
        case withRewardVerification
    }

    func resetRewardedAdSelection() {
        isWaitingForRewardedReward = false
        rewardedAd = nil
        rewardedStatus = "Not Loaded"
        rewardedResult = "Mode changed. Load again."
        rewardedVerificationResult = nil
    }

    func resetRewardedInterstitialAdSelection() {
        isWaitingForRewardedInterstitialReward = false
        rewardedInterstitialAd = nil
        rewardedInterstitialStatus = "Not Loaded"
        rewardedInterstitialResult = "Mode changed. Load again."
        rewardedInterstitialVerificationResult = nil
    }

    // MARK: - Banner Ad

    func loadBannerAd() -> BannerView {
        let bannerSize = AdSize(size: CGSize(width: 320, height: 50), flags: 0)
        let banner = BannerView(adSize: bannerSize)
        banner.adUnitID = Constants.AdMob.bannerAdUnitID
        banner.loadAndTrack(request: Request(), placement: "home_banner")
        self.bannerView = banner
        return banner
    }

    // MARK: - Interstitial Ad

    func loadInterstitialAd() {
        interstitialStatus = "Loading..."

        InterstitialAd.loadAndTrack(
            withAdUnitID: Constants.AdMob.interstitialAdUnitID,
            request: Request(),
            placement: "interstitial_main",
            fullScreenContentDelegate: self
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Interstitial failed: \(error.localizedDescription)")
                self.interstitialStatus = "Failed"
                return
            }

            guard let ad = ad else { return }

            print("✅ Interstitial loaded")
            self.interstitialAd = ad
            self.interstitialStatus = "Ready"
        }
    }

    func showInterstitialAd(from viewController: UIViewController) {
        guard let ad = interstitialAd else {
            print("⚠️ Interstitial not ready")
            return
        }
        ad.present(from: viewController)
    }

    // MARK: - App Open Ad

    func loadAppOpenAd() {
        appOpenStatus = "Loading..."

        AppOpenAd.loadAndTrack(
            withAdUnitID: Constants.AdMob.appOpenAdUnitID,
            request: Request(),
            placement: "app_open_main",
            fullScreenContentDelegate: self
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ App Open failed: \(error.localizedDescription)")
                self.appOpenStatus = "Failed"
                return
            }

            guard let ad = ad else { return }

            print("✅ App Open loaded")
            self.appOpenAd = ad
            self.appOpenStatus = "Ready"
        }
    }

    func showAppOpenAd(from viewController: UIViewController) {
        guard let ad = appOpenAd else {
            print("⚠️ App Open not ready")
            return
        }
        ad.present(from: viewController)
    }

    // MARK: - Rewarded Ad

    func loadRewardedAd(withRewardVerification: Bool) {
        let mode: RewardVerificationLoadMode = withRewardVerification
            ? .withRewardVerification
            : .withoutRewardVerification
        rewardedLoadMode = mode
        rewardedStatus = "Loading..."
        isWaitingForRewardedReward = false
        switch mode {
        case .withoutRewardVerification:
            rewardedResult = "⏳ Loading ad without Reward Verification..."
            rewardedVerificationResult = nil
        case .withRewardVerification:
            rewardedResult = nil
            rewardedVerificationResult = "⏳ Loading ad with Reward Verification..."
        }

        RewardedAd.loadAndTrack(
            withAdUnitID: Constants.AdMob.rewardedAdUnitID,
            request: Request(),
            placement: "rewarded_main",
            fullScreenContentDelegate: self
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Rewarded failed: \(error.localizedDescription)")
                self.rewardedStatus = "Failed"
                if mode == .withRewardVerification {
                    self.rewardedVerificationResult = "❌ Failed to load ad with Reward Verification."
                } else {
                    self.rewardedResult = "❌ Failed to load ad without Reward Verification."
                }
                return
            }

            guard let ad = ad else { return }

            if mode == .withRewardVerification {
                ad.enableRewardVerification()
            }

            print("✅ Rewarded loaded")
            self.rewardedAd = ad
            self.rewardedStatus = "Ready"

            if mode == .withRewardVerification {
                self.rewardedVerificationResult = "🔐 Loaded with Reward Verification."
            } else {
                self.rewardedResult = "🔓 Loaded without Reward Verification."
            }
        }
    }

    @MainActor
    func showRewardedAd(from viewController: UIViewController) {
        guard let ad = rewardedAd else {
            print("⚠️ Rewarded not ready")
            return
        }

        switch rewardedLoadMode {
        case .withoutRewardVerification:
            rewardedVerificationResult = nil
            isWaitingForRewardedReward = true
            rewardedResult = "⏳ Ad shown. Waiting for reward..."
            ad.present(from: viewController, userDidEarnRewardHandler: {
                let reward = ad.adReward
                self.isWaitingForRewardedReward = false
                self.rewardedResult = "🎁 Reward granted: \(reward.amount) \(reward.type)"
                print("✅ User earned reward")
            })
        case .withRewardVerification:
            rewardedResult = nil
            rewardedVerificationResult = "Verifying..."
            ad.present(
                from: viewController,
                placement: "rewarded_reward_verification_main",
                rewardVerificationStarted: {
                    print("⏳ Rewarded verification started")
                },
                rewardVerificationResult: { [weak self] result in
                    self?.rewardedVerificationResult = Self.message(for: result)
                    print("✅ Rewarded verification finished: \(String(describing: result.verifiedReward))")
                }
            )
        }
    }

    // MARK: - Rewarded Interstitial Ad

    func loadRewardedInterstitialAd(withRewardVerification: Bool) {
        let mode: RewardVerificationLoadMode = withRewardVerification
            ? .withRewardVerification
            : .withoutRewardVerification
        rewardedInterstitialLoadMode = mode
        rewardedInterstitialStatus = "Loading..."
        isWaitingForRewardedInterstitialReward = false
        switch mode {
        case .withoutRewardVerification:
            rewardedInterstitialResult = "⏳ Loading ad without Reward Verification..."
            rewardedInterstitialVerificationResult = nil
        case .withRewardVerification:
            rewardedInterstitialResult = nil
            rewardedInterstitialVerificationResult = "⏳ Loading ad with Reward Verification..."
        }

        RewardedInterstitialAd.loadAndTrack(
            withAdUnitID: Constants.AdMob.rewardedInterstitialAdUnitID,
            request: Request(),
            placement: "rewarded_interstitial_main",
            fullScreenContentDelegate: self
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Rewarded Interstitial failed: \(error.localizedDescription)")
                self.rewardedInterstitialStatus = "Failed"
                if mode == .withRewardVerification {
                    self.rewardedInterstitialVerificationResult = "❌ Failed to load ad with Reward Verification."
                } else {
                    self.rewardedInterstitialResult = "❌ Failed to load ad without Reward Verification."
                }
                return
            }

            guard let ad = ad else { return }

            if mode == .withRewardVerification {
                ad.enableRewardVerification()
            }

            print("✅ Rewarded Interstitial loaded")
            self.rewardedInterstitialAd = ad
            self.rewardedInterstitialStatus = "Ready"

            if mode == .withRewardVerification {
                self.rewardedInterstitialVerificationResult = "🔐 Loaded with Reward Verification."
            } else {
                self.rewardedInterstitialResult = "🔓 Loaded without Reward Verification."
            }
        }
    }

    @MainActor
    func showRewardedInterstitialAd(from viewController: UIViewController) {
        guard let ad = rewardedInterstitialAd else {
            print("⚠️ Rewarded Interstitial not ready")
            return
        }

        switch rewardedInterstitialLoadMode {
        case .withoutRewardVerification:
            rewardedInterstitialVerificationResult = nil
            isWaitingForRewardedInterstitialReward = true
            rewardedInterstitialResult = "⏳ Ad shown. Waiting for reward..."
            ad.present(from: viewController, userDidEarnRewardHandler: {
                let reward = ad.adReward
                self.isWaitingForRewardedInterstitialReward = false
                self.rewardedInterstitialResult = "🎁 Reward granted: \(reward.amount) \(reward.type)"
                print("✅ User earned reward (rewarded interstitial)")
            })
        case .withRewardVerification:
            rewardedInterstitialResult = nil
            rewardedInterstitialVerificationResult = "Verifying..."
            ad.present(
                from: viewController,
                placement: "rewarded_interstitial_reward_verification_main",
                rewardVerificationStarted: {
                    print("⏳ Rewarded interstitial verification started")
                },
                rewardVerificationResult: { [weak self] result in
                    self?.rewardedInterstitialVerificationResult = Self.message(for: result)
                    print(
                        "✅ Rewarded interstitial verification finished: "
                        + "\(String(describing: result.verifiedReward))"
                    )
                }
            )
        }
    }

    // MARK: - Native Ad

    func loadNativeAd(adUnitID: String = Constants.AdMob.nativeAdUnitID, placement: String) {
        if adUnitID == Constants.AdMob.nativeAdUnitID {
            nativeAdStatus = "Loading..."
        } else if adUnitID == Constants.AdMob.nativeVideoAdUnitID {
            nativeVideoAdStatus = "Loading..."
        }

        let adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        adLoader.delegate = self
        adLoader.loadAndTrack(
            Request(),
            placement: placement,
            nativeAdDelegate: nil
        )

        if adUnitID == Constants.AdMob.nativeAdUnitID {
            nativeAdLoader = adLoader
        } else if adUnitID == Constants.AdMob.nativeVideoAdUnitID {
            nativeVideoAdLoader = adLoader
        }
    }

    // MARK: - Error Testing

    func loadAdWithError() {
        print("Loading ad with invalid ID to test error tracking")

        let bannerSize = AdSize(size: CGSize(width: 320, height: 50), flags: 0)
        let banner = BannerView(adSize: bannerSize)
        banner.adUnitID = Constants.AdMob.invalidAdUnitID
        // Keep a strong reference until the async load callback runs.
        // Otherwise the banner can be deallocated early and the failure event is never tracked.
        self.errorTestBannerView = banner
        banner.loadAndTrack(request: Request(), placement: "error_test")
    }
}

// MARK: - FullScreenContentDelegate

extension AdMobManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        if ad is InterstitialAd {
            interstitialAd = nil
            interstitialStatus = "Not Loaded"
        } else if ad is AppOpenAd {
            appOpenAd = nil
            appOpenStatus = "Not Loaded"
        } else if ad is RewardedAd {
            if isWaitingForRewardedReward {
                rewardedResult = "⚠️ Ad dismissed before reward was earned"
                isWaitingForRewardedReward = false
            } else if rewardedLoadMode == .withRewardVerification,
                      rewardedVerificationResult == "Verifying..." {
                rewardedVerificationResult = "⚠️ Ad dismissed before reward verification completed"
            }
            rewardedAd = nil
            rewardedStatus = "Not Loaded"
        } else if ad is RewardedInterstitialAd {
            if isWaitingForRewardedInterstitialReward {
                rewardedInterstitialResult = "⚠️ Ad dismissed before reward was earned"
                isWaitingForRewardedInterstitialReward = false
            } else if rewardedInterstitialLoadMode == .withRewardVerification,
                      rewardedInterstitialVerificationResult == "Verifying..." {
                rewardedInterstitialVerificationResult = "⚠️ Ad dismissed before reward verification completed"
            }
            rewardedInterstitialAd = nil
            rewardedInterstitialStatus = "Not Loaded"
        }
    }
}

private extension AdMobManager {

    static func message(for result: RewardVerificationResult) -> String {
        guard result.isVerified, let verifiedReward = result.verifiedReward else {
            return "❌ Verification failed"
        }

        if let virtualCurrency = verifiedReward.virtualCurrency {
            return "✅ Verified: granted \(virtualCurrency.amount) \(virtualCurrency.code)"
        } else if verifiedReward == .noReward {
            return "✅ Verified: no reward granted"
        } else {
            return "✅ Verified: reward type not supported in this SDK"
        }
    }

}

// MARK: - NativeAdLoaderDelegate / AdLoaderDelegate

extension AdMobManager: NativeAdLoaderDelegate, AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        let isNativeVideo = adLoader === self.nativeVideoAdLoader
        let isNative = adLoader === self.nativeAdLoader
        guard isNativeVideo || isNative else { return }

        print("✅ \(isNativeVideo ? "Native video" : "Native") ad loaded")

        if isNativeVideo {
            self.nativeVideoAd = nativeAd
            nativeVideoAdStatus = "Ready"
        } else {
            self.nativeAd = nativeAd
            nativeAdStatus = "Ready"
        }

    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        let isNativeVideo = adLoader === self.nativeVideoAdLoader
        let isNative = adLoader === self.nativeAdLoader
        guard isNativeVideo || isNative else { return }

        print("❌ \(isNativeVideo ? "Native video" : "Native") ad failed: \(error.localizedDescription)")

        if isNativeVideo {
            nativeVideoAdStatus = "Failed"
        } else {
            nativeAdStatus = "Failed"
        }
    }
}
