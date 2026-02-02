import Foundation
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

class AdMobManager: NSObject, ObservableObject {

    var bannerView: GADBannerView?
    var interstitialAd: GADInterstitialAd?
    var appOpenAd: GADAppOpenAd?
    
    @Published var nativeAd: GADNativeAd?
    @Published var nativeVideoAd: GADNativeAd?
    
    @Published var interstitialStatus = "Not Loaded"
    @Published var appOpenStatus = "Not Loaded"
    @Published var nativeAdStatus = "Not Loaded"
    @Published var nativeVideoAdStatus = "Not Loaded"

    private var nativeAdLoader: GADAdLoader?
    private var currentNativeAdUnitID: String?
    private var currentNativePlacement: String?

    // MARK: - Banner Ad

    func loadBannerAd() -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = Constants.AdMob.bannerAdUnitID
        banner.delegate = self

        banner.paidEventHandler = { [weak self] adValue in
            self?.trackAdRevenue(
                adFormat: .banner,
                adUnitID: Constants.AdMob.bannerAdUnitID,
                placement: "home_banner",
                responseInfo: banner.responseInfo,
                adValue: adValue
            )
        }

        banner.load(GADRequest())
        self.bannerView = banner
        return banner
    }

    // MARK: - Interstitial Ad

    func loadInterstitialAd() {
        interstitialStatus = "Loading..."

        GADInterstitialAd.load(
            withAdUnitID: Constants.AdMob.interstitialAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Interstitial failed: \(error.localizedDescription)")
                self.trackAdFailedToLoad(
                    adFormat: .interstitial,
                    adUnitID: Constants.AdMob.interstitialAdUnitID,
                    placement: "interstitial_main",
                    error: error
                )
                self.interstitialStatus = "Failed"
                return
            }

            guard let ad = ad else { return }

            print("✅ Interstitial loaded")
            self.interstitialAd = ad
            ad.fullScreenContentDelegate = self

            self.trackAdLoaded(
                adFormat: .interstitial,
                adUnitID: Constants.AdMob.interstitialAdUnitID,
                placement: "interstitial_main",
                responseInfo: ad.responseInfo
            )

            ad.paidEventHandler = { [weak self] adValue in
                self?.trackAdRevenue(
                    adFormat: .interstitial,
                    adUnitID: Constants.AdMob.interstitialAdUnitID,
                    placement: "interstitial_main",
                    responseInfo: ad.responseInfo,
                    adValue: adValue
                )
            }

            self.interstitialStatus = "Ready"
        }
    }

    func showInterstitialAd(from viewController: UIViewController) {
        guard let ad = interstitialAd else {
            print("⚠️ Interstitial not ready")
            return
        }
        ad.present(fromRootViewController: viewController)
    }

    // MARK: - App Open Ad

    func loadAppOpenAd() {
        appOpenStatus = "Loading..."

        GADAppOpenAd.load(
            withAdUnitID: Constants.AdMob.appOpenAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ App Open failed: \(error.localizedDescription)")
                self.trackAdFailedToLoad(
                    adFormat: .appOpen,
                    adUnitID: Constants.AdMob.appOpenAdUnitID,
                    placement: "app_open_main",
                    error: error
                )
                self.appOpenStatus = "Failed"
                return
            }

            guard let ad = ad else { return }

            print("✅ App Open loaded")
            self.appOpenAd = ad
            ad.fullScreenContentDelegate = self

            self.trackAdLoaded(
                adFormat: .appOpen,
                adUnitID: Constants.AdMob.appOpenAdUnitID,
                placement: "app_open_main",
                responseInfo: ad.responseInfo
            )

            ad.paidEventHandler = { [weak self] adValue in
                self?.trackAdRevenue(
                    adFormat: .appOpen,
                    adUnitID: Constants.AdMob.appOpenAdUnitID,
                    placement: "app_open_main",
                    responseInfo: ad.responseInfo,
                    adValue: adValue
                )
            }

            self.appOpenStatus = "Ready"
        }
    }

    func showAppOpenAd(from viewController: UIViewController) {
        guard let ad = appOpenAd else {
            print("⚠️ App Open not ready")
            return
        }
        ad.present(fromRootViewController: viewController)
    }

    // MARK: - Native Ad

    func loadNativeAd(adUnitID: String = Constants.AdMob.nativeAdUnitID, placement: String) {
        currentNativeAdUnitID = adUnitID
        currentNativePlacement = placement

        if adUnitID == Constants.AdMob.nativeAdUnitID {
            nativeAdStatus = "Loading..."
        } else if adUnitID == Constants.AdMob.nativeVideoAdUnitID {
            nativeVideoAdStatus = "Loading..."
        }

        nativeAdLoader = GADAdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        nativeAdLoader?.delegate = self
        nativeAdLoader?.load(GADRequest())
    }

    // MARK: - Error Testing

    func loadAdWithError() {
        print("Loading ad with invalid ID to test error tracking")

        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = Constants.AdMob.invalidAdUnitID
        banner.delegate = self
        banner.load(GADRequest())
    }

    // MARK: - Tracking

    private func trackAdLoaded(adFormat: AdFormat, adUnitID: String, placement: String, responseInfo: GADResponseInfo?) {
        let data = AdLoaded(
            networkName: responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "Google AdMob",
            mediatorName: .adMob,
            adFormat: adFormat,
            placement: placement,
            adUnitId: adUnitID,
            impressionId: responseInfo?.responseIdentifier ?? ""
        )
        Purchases.shared.adTracker.trackAdLoaded(data)
        print("✅ Tracked: Loaded (format=\(adFormat))")
    }

    func trackAdDisplayed(adFormat: AdFormat, adUnitID: String, placement: String, responseInfo: GADResponseInfo?) {
        let data = AdDisplayed(
            networkName: responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "Google AdMob",
            mediatorName: .adMob,
            adFormat: adFormat,
            placement: placement,
            adUnitId: adUnitID,
            impressionId: responseInfo?.responseIdentifier ?? ""
        )
        Purchases.shared.adTracker.trackAdDisplayed(data)
        print("✅ Tracked: Displayed (format=\(adFormat))")
    }

    func trackAdOpened(adFormat: AdFormat, adUnitID: String, placement: String, responseInfo: GADResponseInfo?) {
        let data = AdOpened(
            networkName: responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "Google AdMob",
            mediatorName: .adMob,
            adFormat: adFormat,
            placement: placement,
            adUnitId: adUnitID,
            impressionId: responseInfo?.responseIdentifier ?? ""
        )
        Purchases.shared.adTracker.trackAdOpened(data)
        print("✅ Tracked: Opened (format=\(adFormat))")
    }

    private func trackAdRevenue(adFormat: AdFormat, adUnitID: String, placement: String, responseInfo: GADResponseInfo?, adValue: GADAdValue) {
        let data = AdRevenue(
            networkName: responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "Google AdMob",
            mediatorName: .adMob,
            adFormat: adFormat,
            placement: placement,
            adUnitId: adUnitID,
            impressionId: responseInfo?.responseIdentifier ?? "",
            revenueMicros: Int(adValue.value.int64Value),
            currency: adValue.currencyCode,
            precision: mapPrecision(adValue.precision)
        )
        Purchases.shared.adTracker.trackAdRevenue(data)
        let revenue = Double(adValue.value.int64Value) / 1_000_000.0
        print("✅ Tracked: Revenue (format=\(adFormat)) - $\(revenue)")
    }

    private func trackAdFailedToLoad(adFormat: AdFormat, adUnitID: String, placement: String, error: Error) {
        let data = AdFailedToLoad(
            networkName: "Google AdMob",
            mediatorName: .adMob,
            adFormat: adFormat,
            placement: placement,
            adUnitId: adUnitID,
            mediatorErrorCode: (error as NSError).code
        )
        Purchases.shared.adTracker.trackAdFailedToLoad(data)
        print("✅ Tracked: Failed (format=\(adFormat))")
    }

    private func mapPrecision(_ precision: GADAdValuePrecision) -> AdRevenue.Precision {
        switch precision {
        case .precise: return .exact
        case .estimated: return .estimated
        case .publisherProvided: return .publisherDefined
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }
}

// MARK: - GADBannerViewDelegate

extension AdMobManager: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("✅ Banner loaded")
        trackAdLoaded(
            adFormat: .banner,
            adUnitID: bannerView.adUnitID ?? "",
            placement: "home_banner",
            responseInfo: bannerView.responseInfo
        )
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("❌ Banner failed: \(error.localizedDescription)")
        trackAdFailedToLoad(
            adFormat: .banner,
            adUnitID: bannerView.adUnitID ?? "",
            placement: "home_banner",
            error: error
        )
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("👁 Banner impression")
        trackAdDisplayed(
            adFormat: .banner,
            adUnitID: bannerView.adUnitID ?? "",
            placement: "home_banner",
            responseInfo: bannerView.responseInfo
        )
    }

    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        print("👆 Banner clicked")
        trackAdOpened(
            adFormat: .banner,
            adUnitID: bannerView.adUnitID ?? "",
            placement: "home_banner",
            responseInfo: bannerView.responseInfo
        )
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdMobManager: GADFullScreenContentDelegate {
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("👁 Full screen impression")

        if let interstitial = ad as? GADInterstitialAd {
            trackAdDisplayed(
                adFormat: .interstitial,
                adUnitID: Constants.AdMob.interstitialAdUnitID,
                placement: "interstitial_main",
                responseInfo: interstitial.responseInfo
            )
        } else if let appOpen = ad as? GADAppOpenAd {
            trackAdDisplayed(
                adFormat: .appOpen,
                adUnitID: Constants.AdMob.appOpenAdUnitID,
                placement: "app_open_main",
                responseInfo: appOpen.responseInfo
            )
        }
    }

    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        print("👆 Full screen clicked")

        if let interstitial = ad as? GADInterstitialAd {
            trackAdOpened(
                adFormat: .interstitial,
                adUnitID: Constants.AdMob.interstitialAdUnitID,
                placement: "interstitial_main",
                responseInfo: interstitial.responseInfo
            )
        } else if let appOpen = ad as? GADAppOpenAd {
            trackAdOpened(
                adFormat: .appOpen,
                adUnitID: Constants.AdMob.appOpenAdUnitID,
                placement: "app_open_main",
                responseInfo: appOpen.responseInfo
            )
        }
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        if ad is GADInterstitialAd {
            interstitialAd = nil
            interstitialStatus = "Not Loaded"
        } else if ad is GADAppOpenAd {
            appOpenAd = nil
            appOpenStatus = "Not Loaded"
        }
    }
}

// MARK: - GADAdLoaderDelegate & GADNativeAdLoaderDelegate

extension AdMobManager: GADAdLoaderDelegate, GADNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        guard let adUnitID = currentNativeAdUnitID, let placement = currentNativePlacement else { return }

        let isNativeVideo = adUnitID == Constants.AdMob.nativeVideoAdUnitID

        print("✅ \(isNativeVideo ? "Native video" : "Native") ad loaded")

        if isNativeVideo {
            self.nativeVideoAd = nativeAd
            nativeVideoAdStatus = "Ready"
        } else {
            self.nativeAd = nativeAd
            nativeAdStatus = "Ready"
        }

        nativeAd.delegate = self

        trackAdLoaded(
            adFormat: .native,
            adUnitID: adUnitID,
            placement: placement,
            responseInfo: nativeAd.responseInfo
        )

        nativeAd.paidEventHandler = { [weak self] adValue in
            self?.trackAdRevenue(
                adFormat: .native,
                adUnitID: adUnitID,
                placement: placement,
                responseInfo: nativeAd.responseInfo,
                adValue: adValue
            )
        }
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        guard let adUnitID = currentNativeAdUnitID, let placement = currentNativePlacement else { return }

        let isNativeVideo = adUnitID == Constants.AdMob.nativeVideoAdUnitID

        print("❌ \(isNativeVideo ? "Native video" : "Native") ad failed: \(error.localizedDescription)")

        if isNativeVideo {
            nativeVideoAdStatus = "Failed"
        } else {
            nativeAdStatus = "Failed"
        }

        trackAdFailedToLoad(
            adFormat: .native,
            adUnitID: adUnitID,
            placement: placement,
            error: error
        )
    }
}

// MARK: - GADNativeAdDelegate

extension AdMobManager: GADNativeAdDelegate {
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        let adUnitID: String
        let placement: String

        if nativeAd === self.nativeVideoAd {
            adUnitID = Constants.AdMob.nativeVideoAdUnitID
            placement = "native_video_main"
            print("👁 Native video ad impression")
        } else {
            adUnitID = Constants.AdMob.nativeAdUnitID
            placement = "native_main"
            print("👁 Native ad impression")
        }

        trackAdDisplayed(
            adFormat: .native,
            adUnitID: adUnitID,
            placement: placement,
            responseInfo: nativeAd.responseInfo
        )
    }

    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        let adUnitID: String
        let placement: String

        if nativeAd === self.nativeVideoAd {
            adUnitID = Constants.AdMob.nativeVideoAdUnitID
            placement = "native_video_main"
            print("👆 Native video ad clicked")
        } else {
            adUnitID = Constants.AdMob.nativeAdUnitID
            placement = "native_main"
            print("👆 Native ad clicked")
        }

        trackAdOpened(
            adFormat: .native,
            adUnitID: adUnitID,
            placement: placement,
            responseInfo: nativeAd.responseInfo
        )
    }
}
