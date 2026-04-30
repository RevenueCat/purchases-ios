// swiftlint:disable:next blanket_disable_command
// swiftlint:disable identifier_name
import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCatAdMob

class AdMobManager: NSObject, ObservableObject {

    var bannerView: BannerView?
    var errorTestBannerView: BannerView?
    var interstitialAd: InterstitialAd?
    var appOpenAd: AppOpenAd?
    var rewardedAd: RewardedAd?
    var rewardedSSVAd: RewardedInterstitialAd?
    var rewardedInterstitialAd: RewardedInterstitialAd?
    var nativeAdLoader: AdLoader?
    var nativeVideoAdLoader: AdLoader?

    @Published var nativeAd: NativeAd?
    @Published var nativeVideoAd: NativeAd?

    @Published var interstitialStatus = "Not Loaded"
    @Published var appOpenStatus = "Not Loaded"
    @Published var rewardedStatus = "Not Loaded"
    @Published var rewardedSSVStatus = "Not Loaded"
    @Published var rewardedSSVResult: String? = nil
    @Published var rewardedInterstitialStatus = "Not Loaded"
    @Published var nativeAdStatus = "Not Loaded"
    @Published var nativeVideoAdStatus = "Not Loaded"

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

    func loadRewardedAd() {
        rewardedStatus = "Loading..."

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
                return
            }

            guard let ad = ad else { return }

            print("✅ Rewarded loaded")
            self.rewardedAd = ad
            self.rewardedStatus = "Ready"
        }
    }

    func showRewardedAd(from viewController: UIViewController, userDidEarnRewardHandler: @escaping () -> Void) {
        guard let ad = rewardedAd else {
            print("⚠️ Rewarded not ready")
            return
        }
        ad.present(from: viewController, userDidEarnRewardHandler: {
            print("✅ User earned reward")
            userDidEarnRewardHandler()
        })
    }

    // MARK: - Rewarded Ad (SSV)

    func loadRewardedSSVAd() {
        rewardedSSVStatus = "Loading..."
        rewardedSSVResult = nil

        RewardedInterstitialAd.loadAndTrack(
            withAdUnitID: Constants.AdMob.rewardedSSVAdUnitID,
            request: Request(),
            placement: "rewarded_ssv",
            fullScreenContentDelegate: self
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Rewarded SSV failed: \(error.localizedDescription)")
                self.rewardedSSVStatus = "Failed"
                return
            }

            guard let ad = ad else { return }

            print("✅ Rewarded SSV loaded")
            ad.enableRewardVerification()
            self.rewardedSSVAd = ad
            self.rewardedSSVStatus = "Ready"
        }
    }

    @MainActor
    func showRewardedSSVAd(from viewController: UIViewController) {
        guard let ad = rewardedSSVAd else {
            print("⚠️ Rewarded SSV not ready")
            return
        }
        rewardedSSVResult = "Verifying..."
        ad.present(
            from: viewController,
            rewardVerificationStarted: {
                print("🔄 SSV polling started")
            },
            rewardVerificationResult: { [weak self] result in
                guard let self = self else { return }
                if result.isVerified {
                    print("✅ SSV verified: \(String(describing: result.verifiedReward))")
                    self.rewardedSSVResult = "✅ Verified: \(String(describing: result.verifiedReward))"
                } else {
                    print("❌ SSV failed")
                    self.rewardedSSVResult = "❌ Failed"
                }
            }
        )
    }

    // MARK: - Rewarded Interstitial Ad

    func loadRewardedInterstitialAd() {
        rewardedInterstitialStatus = "Loading..."

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
                return
            }

            guard let ad = ad else { return }

            print("✅ Rewarded Interstitial loaded")
            self.rewardedInterstitialAd = ad
            self.rewardedInterstitialStatus = "Ready"
        }
    }

    // swiftlint:disable:next line_length
    func showRewardedInterstitialAd(from viewController: UIViewController, userDidEarnRewardHandler: @escaping () -> Void) {
        guard let ad = rewardedInterstitialAd else {
            print("⚠️ Rewarded Interstitial not ready")
            return
        }
        ad.present(from: viewController, userDidEarnRewardHandler: {
            print("✅ User earned reward (rewarded interstitial)")
            userDidEarnRewardHandler()
        })
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
        } else if ad === rewardedAd {
            rewardedAd = nil
            rewardedStatus = "Not Loaded"
        } else if ad === rewardedSSVAd {
            rewardedSSVAd = nil
            rewardedSSVStatus = "Not Loaded"
        } else if ad is RewardedInterstitialAd {
            rewardedInterstitialAd = nil
            rewardedInterstitialStatus = "Not Loaded"
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
