// swiftlint:disable:next blanket_disable_command
// swiftlint:disable identifier_name
import Foundation
import GoogleMobileAds
import RevenueCat
@_spi(Experimental) import RevenueCat

// MARK: - AdMobManager

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
    @Published var rewardedInterstitialStatus = "Not Loaded"
    @Published var nativeAdStatus = "Not Loaded"
    @Published var nativeVideoAdStatus = "Not Loaded"

    /// Stored metadata for full-screen ads so delegate callbacks can construct tracking data.
    private var fullScreenAdMetadata: [ObjectIdentifier: FullScreenAdMeta] = [:]

    private struct FullScreenAdMeta {
        let placement: String
        let adUnitId: String
        let adFormat: RevenueCat.AdFormat
        let responseInfo: ResponseInfo?
    }

    // MARK: - Ad Tracker

    @available(iOS 15.0, *)
    private var adTracker: AdTracker { Purchases.shared.adTracker }

    // MARK: - Helpers

    private static let microsPerUnit = NSDecimalNumber(value: 1_000_000)

    private func impressionId(from responseInfo: ResponseInfo?) -> String {
        responseInfo?.responseIdentifier ?? ""
    }

    private func networkName(from responseInfo: ResponseInfo?) -> String {
        responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? ""
    }

    private func revenueMicros(from adValue: NSDecimalNumber) -> Int {
        let micros = adValue.multiplying(by: Self.microsPerUnit)
        return Int(micros.int64Value)
    }

    private func mapPrecision(_ precision: AdValuePrecision) -> AdRevenue.Precision {
        switch precision {
        case .precise: return .exact
        case .estimated: return .estimated
        case .publisherProvided: return .publisherDefined
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }

    /// Creates a `paidEventHandler` closure that forwards revenue to RevenueCat.
    @available(iOS 15.0, *)
    private func makePaidEventHandler(
        responseInfo: ResponseInfo?,
        placement: String,
        adUnitId: String,
        adFormat: RevenueCat.AdFormat
    ) -> (AdValue) -> Void {
        return { [weak self] adValue in
            guard let self else { return }
            self.adTracker.trackAdRevenue(AdRevenue(
                networkName: self.networkName(from: responseInfo),
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: adUnitId,
                impressionId: self.impressionId(from: responseInfo),
                revenueMicros: self.revenueMicros(from: adValue.value),
                currency: adValue.currencyCode,
                precision: self.mapPrecision(adValue.precision)
            ))
        }
    }

    // MARK: - Banner Ad

    func loadBannerAd() -> BannerView {
        let bannerSize = AdSize(size: CGSize(width: 320, height: 50), flags: 0)
        let banner = BannerView(adSize: bannerSize)
        banner.adUnitID = Constants.AdMob.bannerAdUnitID
        banner.delegate = self
        banner.load(Request())
        self.bannerView = banner
        return banner
    }

    // MARK: - Interstitial Ad

    func loadInterstitialAd() {
        interstitialStatus = "Loading..."

        InterstitialAd.load(
            with: Constants.AdMob.interstitialAdUnitID,
            request: Request()
        ) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                self.handleFullScreenLoadFailure(
                    error: error, placement: "interstitial_main",
                    adUnitId: Constants.AdMob.interstitialAdUnitID,
                    adFormat: .interstitial, statusKeyPath: \.interstitialStatus
                )
                return
            }
            guard let ad else { return }
            self.interstitialAd = ad
            self.handleFullScreenLoadSuccess(
                ad: ad, responseInfo: ad.responseInfo,
                placement: "interstitial_main",
                adUnitId: Constants.AdMob.interstitialAdUnitID,
                adFormat: .interstitial, statusKeyPath: \.interstitialStatus
            ) { ad.paidEventHandler = $0 }
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

        AppOpenAd.load(
            with: Constants.AdMob.appOpenAdUnitID,
            request: Request()
        ) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                self.handleFullScreenLoadFailure(
                    error: error, placement: "app_open_main",
                    adUnitId: Constants.AdMob.appOpenAdUnitID,
                    adFormat: .appOpen, statusKeyPath: \.appOpenStatus
                )
                return
            }
            guard let ad else { return }
            self.appOpenAd = ad
            self.handleFullScreenLoadSuccess(
                ad: ad, responseInfo: ad.responseInfo,
                placement: "app_open_main",
                adUnitId: Constants.AdMob.appOpenAdUnitID,
                adFormat: .appOpen, statusKeyPath: \.appOpenStatus
            ) { ad.paidEventHandler = $0 }
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

        RewardedAd.load(
            with: Constants.AdMob.rewardedAdUnitID,
            request: Request()
        ) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                self.handleFullScreenLoadFailure(
                    error: error, placement: "rewarded_main",
                    adUnitId: Constants.AdMob.rewardedAdUnitID,
                    adFormat: .rewarded, statusKeyPath: \.rewardedStatus
                )
                return
            }
            guard let ad else { return }
            self.rewardedAd = ad
            self.handleFullScreenLoadSuccess(
                ad: ad, responseInfo: ad.responseInfo,
                placement: "rewarded_main",
                adUnitId: Constants.AdMob.rewardedAdUnitID,
                adFormat: .rewarded, statusKeyPath: \.rewardedStatus
            ) { ad.paidEventHandler = $0 }
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

    // MARK: - Rewarded Interstitial Ad

    func loadRewardedInterstitialAd() {
        rewardedInterstitialStatus = "Loading..."

        RewardedInterstitialAd.load(
            with: Constants.AdMob.rewardedInterstitialAdUnitID,
            request: Request()
        ) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                self.handleFullScreenLoadFailure(
                    error: error, placement: "rewarded_interstitial_main",
                    adUnitId: Constants.AdMob.rewardedInterstitialAdUnitID,
                    adFormat: .rewardedInterstitial, statusKeyPath: \.rewardedInterstitialStatus
                )
                return
            }
            guard let ad else { return }
            self.rewardedInterstitialAd = ad
            self.handleFullScreenLoadSuccess(
                ad: ad, responseInfo: ad.responseInfo,
                placement: "rewarded_interstitial_main",
                adUnitId: Constants.AdMob.rewardedInterstitialAdUnitID,
                adFormat: .rewardedInterstitial, statusKeyPath: \.rewardedInterstitialStatus
            ) { ad.paidEventHandler = $0 }
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
        adLoader.load(Request())

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
        banner.delegate = self
        self.errorTestBannerView = banner
        banner.load(Request())
    }

    // MARK: - Full-Screen Load Helper

    @available(iOS 15.0, *)
    private func handleFullScreenLoadSuccess(
        ad: some FullScreenPresentingAd & AnyObject,
        responseInfo: ResponseInfo?,
        placement: String,
        adUnitId: String,
        adFormat: RevenueCat.AdFormat,
        statusKeyPath: ReferenceWritableKeyPath<AdMobManager, String>,
        setPaidEventHandler: (@escaping (AdValue) -> Void) -> Void
    ) {
        print("✅ \(adFormat.rawValue) loaded")

        adTracker.trackAdLoaded(AdLoaded(
            networkName: networkName(from: responseInfo),
            mediatorName: .adMob,
            adFormat: adFormat,
            placement: placement,
            adUnitId: adUnitId,
            impressionId: impressionId(from: responseInfo)
        ))

        ad.fullScreenContentDelegate = self
        fullScreenAdMetadata[ObjectIdentifier(ad)] = FullScreenAdMeta(
            placement: placement,
            adUnitId: adUnitId,
            adFormat: adFormat,
            responseInfo: responseInfo
        )

        setPaidEventHandler(makePaidEventHandler(
            responseInfo: responseInfo,
            placement: placement,
            adUnitId: adUnitId,
            adFormat: adFormat
        ))

        self[keyPath: statusKeyPath] = "Ready"
    }

    @available(iOS 15.0, *)
    private func handleFullScreenLoadFailure(
        error: Error,
        placement: String,
        adUnitId: String,
        adFormat: RevenueCat.AdFormat,
        statusKeyPath: ReferenceWritableKeyPath<AdMobManager, String>
    ) {
        print("❌ \(adFormat.rawValue) failed: \(error.localizedDescription)")
        self[keyPath: statusKeyPath] = "Failed"
        adTracker.trackAdFailedToLoad(AdFailedToLoad(
            mediatorName: .adMob,
            adFormat: adFormat,
            placement: placement,
            adUnitId: adUnitId,
            mediatorErrorCode: (error as NSError).code
        ))
    }
}

// MARK: - BannerViewDelegate

extension AdMobManager: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        guard #available(iOS 15.0, *) else { return }
        let responseInfo = bannerView.responseInfo
        let adUnitId = bannerView.adUnitID ?? ""
        let placement = bannerView === errorTestBannerView ? "error_test" : "home_banner"

        adTracker.trackAdLoaded(AdLoaded(
            networkName: networkName(from: responseInfo),
            mediatorName: .adMob,
            adFormat: .banner,
            placement: placement,
            adUnitId: adUnitId,
            impressionId: impressionId(from: responseInfo)
        ))

        bannerView.paidEventHandler = makePaidEventHandler(
            responseInfo: responseInfo,
            placement: placement,
            adUnitId: adUnitId,
            adFormat: .banner
        )
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        guard #available(iOS 15.0, *) else { return }
        let responseInfo = bannerView.responseInfo

        adTracker.trackAdDisplayed(AdDisplayed(
            networkName: networkName(from: responseInfo),
            mediatorName: .adMob,
            adFormat: .banner,
            placement: "home_banner",
            adUnitId: bannerView.adUnitID ?? "",
            impressionId: impressionId(from: responseInfo)
        ))
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        guard #available(iOS 15.0, *) else { return }
        let responseInfo = bannerView.responseInfo

        adTracker.trackAdOpened(AdOpened(
            networkName: networkName(from: responseInfo),
            mediatorName: .adMob,
            adFormat: .banner,
            placement: "home_banner",
            adUnitId: bannerView.adUnitID ?? "",
            impressionId: impressionId(from: responseInfo)
        ))
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        guard #available(iOS 15.0, *) else { return }
        let adUnitId = bannerView.adUnitID ?? ""
        let placement = bannerView === errorTestBannerView ? "error_test" : "home_banner"

        print("❌ Banner failed: \(error.localizedDescription)")

        adTracker.trackAdFailedToLoad(AdFailedToLoad(
            mediatorName: .adMob,
            adFormat: .banner,
            placement: placement,
            adUnitId: adUnitId,
            mediatorErrorCode: (error as NSError).code
        ))
    }
}

// MARK: - FullScreenContentDelegate

extension AdMobManager: FullScreenContentDelegate {
    func adDidRecordImpression(_ ad: any FullScreenPresentingAd) {
        guard #available(iOS 15.0, *) else { return }
        guard let meta = fullScreenAdMetadata[ObjectIdentifier(ad as AnyObject)] else { return }

        adTracker.trackAdDisplayed(AdDisplayed(
            networkName: networkName(from: meta.responseInfo),
            mediatorName: .adMob,
            adFormat: meta.adFormat,
            placement: meta.placement,
            adUnitId: meta.adUnitId,
            impressionId: impressionId(from: meta.responseInfo)
        ))
    }

    func adDidRecordClick(_ ad: any FullScreenPresentingAd) {
        guard #available(iOS 15.0, *) else { return }
        guard let meta = fullScreenAdMetadata[ObjectIdentifier(ad as AnyObject)] else { return }

        adTracker.trackAdOpened(AdOpened(
            networkName: networkName(from: meta.responseInfo),
            mediatorName: .adMob,
            adFormat: meta.adFormat,
            placement: meta.placement,
            adUnitId: meta.adUnitId,
            impressionId: impressionId(from: meta.responseInfo)
        ))
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        let key = ObjectIdentifier(ad as AnyObject)
        fullScreenAdMetadata.removeValue(forKey: key)

        if ad is InterstitialAd {
            interstitialAd = nil
            interstitialStatus = "Not Loaded"
        } else if ad is AppOpenAd {
            appOpenAd = nil
            appOpenStatus = "Not Loaded"
        } else if ad is RewardedAd {
            rewardedAd = nil
            rewardedStatus = "Not Loaded"
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

        guard #available(iOS 15.0, *) else { return }
        let responseInfo = nativeAd.responseInfo
        let adUnitId = adLoader.adUnitID
        let placement = isNativeVideo ? "native_video_main" : "native_main"

        adTracker.trackAdLoaded(AdLoaded(
            networkName: networkName(from: responseInfo),
            mediatorName: .adMob,
            adFormat: .native,
            placement: placement,
            adUnitId: adUnitId,
            impressionId: impressionId(from: responseInfo)
        ))

        nativeAd.delegate = self

        nativeAd.paidEventHandler = makePaidEventHandler(
            responseInfo: responseInfo,
            placement: placement,
            adUnitId: adUnitId,
            adFormat: .native
        )
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

        guard #available(iOS 15.0, *) else { return }
        let placement = isNativeVideo ? "native_video_main" : "native_main"

        adTracker.trackAdFailedToLoad(AdFailedToLoad(
            mediatorName: .adMob,
            adFormat: .native,
            placement: placement,
            adUnitId: adLoader.adUnitID,
            mediatorErrorCode: (error as NSError).code
        ))
    }
}

// MARK: - NativeAdDelegate

extension AdMobManager: NativeAdDelegate {
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        guard #available(iOS 15.0, *) else { return }
        let responseInfo = nativeAd.responseInfo
        let isVideo = self.nativeVideoAd === nativeAd
        let placement = isVideo ? "native_video_main" : "native_main"
        let adUnitId = (isVideo ? nativeVideoAdLoader : nativeAdLoader)?.adUnitID ?? ""

        adTracker.trackAdDisplayed(AdDisplayed(
            networkName: networkName(from: responseInfo),
            mediatorName: .adMob,
            adFormat: .native,
            placement: placement,
            adUnitId: adUnitId,
            impressionId: impressionId(from: responseInfo)
        ))
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        guard #available(iOS 15.0, *) else { return }
        let responseInfo = nativeAd.responseInfo
        let isVideo = self.nativeVideoAd === nativeAd
        let placement = isVideo ? "native_video_main" : "native_main"
        let adUnitId = (isVideo ? nativeVideoAdLoader : nativeAdLoader)?.adUnitID ?? ""

        adTracker.trackAdOpened(AdOpened(
            networkName: networkName(from: responseInfo),
            mediatorName: .adMob,
            adFormat: .native,
            placement: placement,
            adUnitId: adUnitId,
            impressionId: impressionId(from: responseInfo)
        ))
    }
}
