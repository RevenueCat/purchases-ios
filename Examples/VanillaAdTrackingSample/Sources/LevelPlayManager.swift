import Foundation
@preconcurrency import IronSource
import RevenueCat

enum LevelPlayInitializationState: Equatable {
    case initializing
    case initialized
    case failed(String)
}

@MainActor
final class LevelPlayManager: NSObject, ObservableObject {

    @Published private(set) var initializationState: LevelPlayInitializationState = .initializing
    @Published private(set) var bannerStatus = "Not loaded"
    @Published private(set) var interstitialStatus = "Not loaded"
    @Published private(set) var rewardedStatus = "Not loaded"
    @Published private(set) var errorTestStatus = "Not loaded"

    private var bannerAd: LPMBannerAdView?
    private var interstitialAd: LPMInterstitialAd?
    private var rewardedAd: LPMRewardedAd?
    private var errorTestAd: LPMInterstitialAd?

    private var interstitialDelegate: InterstitialDelegate?
    private var rewardedDelegate: RewardedDelegate?
    private var errorTestDelegate: InterstitialDelegate?

    private static let bannerPlacement = "home_banner"
    private static let interstitialPlacement = "home_interstitial"
    private static let rewardedPlacement = "home_rewarded"
    private static let errorTestPlacement = "error_test"

    private var adTracker: AdTracker { Purchases.shared.adTracker }

    override init() {
        super.init()
        self.initializeLevelPlay()
    }

    // MARK: - Initialization

    private func initializeLevelPlay() {
        let request = LPMInitRequestBuilder(appKey: Constants.LevelPlay.appKey).build()
        LevelPlay.initWith(request) { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.initializationState = .failed(error.localizedDescription)
                    print("❌ LevelPlay SDK initialization failed: \(error.localizedDescription)")
                    return
                }

                self.createAds()
                self.initializationState = .initialized
                print("✅ LevelPlay SDK initialized")
            }
        }
    }

    private func createAds() {
        let interstitialMetadata = AdMetadata(
            placement: Self.interstitialPlacement,
            adUnitId: Constants.LevelPlay.interstitialAdUnitID,
            adFormat: .interstitial
        )
        let interstitialDelegate = InterstitialDelegate(manager: self, metadata: interstitialMetadata)
        let interstitialAd = LPMInterstitialAd(adUnitId: interstitialMetadata.adUnitId)
        interstitialAd.setDelegate(interstitialDelegate)
        self.interstitialDelegate = interstitialDelegate
        self.interstitialAd = interstitialAd

        let rewardedMetadata = AdMetadata(
            placement: Self.rewardedPlacement,
            adUnitId: Constants.LevelPlay.rewardedAdUnitID,
            adFormat: .rewarded
        )
        let rewardedDelegate = RewardedDelegate(manager: self, metadata: rewardedMetadata)
        let rewardedAd = LPMRewardedAd(adUnitId: rewardedMetadata.adUnitId)
        rewardedAd.setDelegate(rewardedDelegate)
        self.rewardedDelegate = rewardedDelegate
        self.rewardedAd = rewardedAd

        let errorTestMetadata = AdMetadata(
            placement: Self.errorTestPlacement,
            adUnitId: Constants.LevelPlay.invalidAdUnitID,
            adFormat: .interstitial,
            isErrorTest: true
        )
        let errorTestDelegate = InterstitialDelegate(manager: self, metadata: errorTestMetadata)
        let errorTestAd = LPMInterstitialAd(adUnitId: errorTestMetadata.adUnitId)
        errorTestAd.setDelegate(errorTestDelegate)
        self.errorTestDelegate = errorTestDelegate
        self.errorTestAd = errorTestAd
    }

    // MARK: - Banner

    func makeBannerAd(from viewController: UIViewController) -> LPMBannerAdView {
        self.bannerAd?.destroy()
        self.bannerStatus = "Loading…"

        let config = LPMBannerAdViewConfigBuilder()
            .set(adSize: .banner())
            .set(placementName: Self.bannerPlacement)
            .build()
        let bannerAd = LPMBannerAdView(adUnitId: Constants.LevelPlay.bannerAdUnitID, config: config)
        bannerAd.setDelegate(self)
        bannerAd.loadAd(with: viewController)
        self.bannerAd = bannerAd
        return bannerAd
    }

    // MARK: - Interstitial

    func loadInterstitialAd() {
        self.interstitialStatus = "Loading…"
        self.interstitialAd?.loadAd()
    }

    func showInterstitialAd(from viewController: UIViewController) {
        guard let interstitialAd, interstitialAd.isAdReady() else {
            print("⚠️ Interstitial not ready")
            return
        }

        interstitialAd.showAd(viewController: viewController, placementName: Self.interstitialPlacement)
    }

    // MARK: - Rewarded

    func trackRewardedPromptShown() {
        self.adTracker.trackRewardedAdPromptShown(AdRewardPromptShown(
            mediatorName: .levelPlay,
            placement: Self.rewardedPlacement,
            adUnitId: Constants.LevelPlay.rewardedAdUnitID
        ))
    }

    func loadRewardedAd() {
        self.rewardedStatus = "Loading…"
        self.rewardedAd?.loadAd()
    }

    func showRewardedAd(from viewController: UIViewController) {
        guard let rewardedAd, rewardedAd.isAdReady() else {
            print("⚠️ Rewarded ad not ready")
            return
        }

        self.adTracker.trackRewardedAdPromptAccepted(AdRewardPromptAccepted(
            mediatorName: .levelPlay,
            placement: Self.rewardedPlacement,
            adUnitId: Constants.LevelPlay.rewardedAdUnitID
        ))
        rewardedAd.showAd(viewController: viewController, placementName: Self.rewardedPlacement)
    }

    // MARK: - Error testing

    func loadAdWithError() {
        self.errorTestStatus = "Loading with invalid ID…"
        self.errorTestAd?.loadAd()
    }

    // MARK: - Tracking

    fileprivate func didLoad(_ adInfo: LPMAdInfo, metadata: AdMetadata) {
        guard !metadata.isErrorTest else {
            self.errorTestStatus = "Unexpectedly loaded"
            return
        }

        self.adTracker.trackAdLoaded(AdLoaded(
            networkName: self.networkName(from: adInfo),
            mediatorName: .levelPlay,
            adFormat: metadata.adFormat,
            placement: metadata.placement,
            adUnitId: metadata.adUnitId,
            impressionId: adInfo.auctionId
        ))
        self.setStatus("Loaded - ready to show", for: metadata)
    }

    fileprivate func didFailToLoad(_ error: Error, metadata: AdMetadata) {
        self.adTracker.trackAdFailedToLoad(AdFailedToLoad(
            mediatorName: .levelPlay,
            adFormat: metadata.adFormat,
            placement: metadata.placement,
            adUnitId: metadata.adUnitId,
            mediatorErrorCode: (error as NSError).code
        ))

        let status = "Failed: \(error.localizedDescription)"
        if metadata.isErrorTest {
            self.errorTestStatus = "Failed (tracked): \(error.localizedDescription)"
        } else {
            self.setStatus(status, for: metadata)
        }
    }

    fileprivate func didDisplay(_ adInfo: LPMAdInfo, metadata: AdMetadata) {
        guard !metadata.isErrorTest else { return }

        self.adTracker.trackAdDisplayed(AdDisplayed(
            networkName: self.networkName(from: adInfo),
            mediatorName: .levelPlay,
            adFormat: metadata.adFormat,
            placement: metadata.placement,
            adUnitId: metadata.adUnitId,
            impressionId: adInfo.auctionId
        ))
        self.adTracker.trackAdRevenue(AdRevenue(
            networkName: self.networkName(from: adInfo),
            mediatorName: .levelPlay,
            adFormat: metadata.adFormat,
            placement: metadata.placement,
            adUnitId: metadata.adUnitId,
            impressionId: adInfo.auctionId,
            revenueMicros: Int((adInfo.revenue.doubleValue * 1_000_000).rounded()),
            currency: "USD",
            precision: self.mapPrecision(adInfo.precision)
        ))
        self.setStatus("Displayed", for: metadata)
    }

    fileprivate func didClick(_ adInfo: LPMAdInfo, metadata: AdMetadata) {
        guard !metadata.isErrorTest else { return }

        self.adTracker.trackAdOpened(AdOpened(
            networkName: self.networkName(from: adInfo),
            mediatorName: .levelPlay,
            adFormat: metadata.adFormat,
            placement: metadata.placement,
            adUnitId: metadata.adUnitId,
            impressionId: adInfo.auctionId
        ))
    }

    fileprivate func didFailToDisplay(_ error: Error, metadata: AdMetadata) {
        self.setStatus("Display failed: \(error.localizedDescription)", for: metadata)
    }

    fileprivate func didClose(metadata: AdMetadata) {
        self.setStatus("Closed - load again", for: metadata)
    }

    private func networkName(from adInfo: LPMAdInfo) -> String? {
        return adInfo.adNetwork.isEmpty ? nil : adInfo.adNetwork
    }

    private func mapPrecision(_ precision: String) -> AdRevenue.Precision {
        switch precision.uppercased() {
        case "BID": return .exact
        case "RATE": return .publisherDefined
        case "CPM": return .estimated
        default: return .unknown
        }
    }

    private func setStatus(_ status: String, for metadata: AdMetadata) {
        if metadata.adFormat == .banner {
            self.bannerStatus = status
        } else if metadata.adFormat == .rewarded {
            self.rewardedStatus = status
        } else {
            self.interstitialStatus = status
        }
    }

}

// MARK: - Banner delegate

extension LevelPlayManager: @preconcurrency LPMBannerAdViewDelegate {

    func didLoadAd(with adInfo: LPMAdInfo) {
        let metadata = AdMetadata(
            placement: Self.bannerPlacement,
            adUnitId: Constants.LevelPlay.bannerAdUnitID,
            adFormat: .banner
        )
        self.didLoad(adInfo, metadata: metadata)
    }

    func didFailToLoadAd(withAdUnitId adUnitId: String, error: Error) {
        self.didFailToLoad(error, metadata: AdMetadata(
            placement: Self.bannerPlacement,
            adUnitId: adUnitId,
            adFormat: .banner
        ))
        self.bannerStatus = "Failed: \(error.localizedDescription)"
    }

    func didDisplayAd(with adInfo: LPMAdInfo) {
        self.didDisplay(adInfo, metadata: AdMetadata(
            placement: Self.bannerPlacement,
            adUnitId: Constants.LevelPlay.bannerAdUnitID,
            adFormat: .banner
        ))
    }

    func didFailToDisplayAd(with adInfo: LPMAdInfo, error: Error) {
        self.bannerStatus = "Display failed: \(error.localizedDescription)"
    }

    func didClickAd(with adInfo: LPMAdInfo) {
        self.didClick(adInfo, metadata: AdMetadata(
            placement: Self.bannerPlacement,
            adUnitId: Constants.LevelPlay.bannerAdUnitID,
            adFormat: .banner
        ))
    }

    func didLeaveApp(with adInfo: LPMAdInfo) {}
    func didExpandAd(with adInfo: LPMAdInfo) {}
    func didCollapseAd(with adInfo: LPMAdInfo) {}

}

// MARK: - Full-screen delegates

@MainActor
private final class InterstitialDelegate: NSObject, @preconcurrency LPMInterstitialAdDelegate {

    private weak var manager: LevelPlayManager?
    private let metadata: AdMetadata

    init(manager: LevelPlayManager, metadata: AdMetadata) {
        self.manager = manager
        self.metadata = metadata
    }

    func didLoadAd(with adInfo: LPMAdInfo) {
        self.manager?.didLoad(adInfo, metadata: self.metadata)
    }

    func didFailToLoadAd(withAdUnitId adUnitId: String, error: Error) {
        self.manager?.didFailToLoad(error, metadata: self.metadata)
    }

    func didDisplayAd(with adInfo: LPMAdInfo) {
        self.manager?.didDisplay(adInfo, metadata: self.metadata)
    }

    func didFailToDisplayAd(with adInfo: LPMAdInfo, error: Error) {
        self.manager?.didFailToDisplay(error, metadata: self.metadata)
    }

    func didClickAd(with adInfo: LPMAdInfo) {
        self.manager?.didClick(adInfo, metadata: self.metadata)
    }

    func didCloseAd(with adInfo: LPMAdInfo) {
        self.manager?.didClose(metadata: self.metadata)
    }

    func didChangeAdInfo(_ adInfo: LPMAdInfo) {}

}

@MainActor
private final class RewardedDelegate: NSObject, @preconcurrency LPMRewardedAdDelegate {

    private weak var manager: LevelPlayManager?
    private let metadata: AdMetadata

    init(manager: LevelPlayManager, metadata: AdMetadata) {
        self.manager = manager
        self.metadata = metadata
    }

    func didLoadAd(with adInfo: LPMAdInfo) {
        self.manager?.didLoad(adInfo, metadata: self.metadata)
    }

    func didFailToLoadAd(withAdUnitId adUnitId: String, error: Error) {
        self.manager?.didFailToLoad(error, metadata: self.metadata)
    }

    func didDisplayAd(with adInfo: LPMAdInfo) {
        self.manager?.didDisplay(adInfo, metadata: self.metadata)
    }

    func didFailToDisplayAd(with adInfo: LPMAdInfo, error: Error) {
        self.manager?.didFailToDisplay(error, metadata: self.metadata)
    }

    func didClickAd(with adInfo: LPMAdInfo) {
        self.manager?.didClick(adInfo, metadata: self.metadata)
    }

    func didCloseAd(with adInfo: LPMAdInfo) {
        self.manager?.didClose(metadata: self.metadata)
    }

    func didRewardAd(with adInfo: LPMAdInfo, reward: LPMReward) {
        print("✅ User earned reward: \(reward.amount) \(reward.name)")
    }

    func didChangeAdInfo(_ adInfo: LPMAdInfo) {}

}

private struct AdMetadata {
    let placement: String
    let adUnitId: String
    let adFormat: RevenueCat.AdFormat
    var isErrorTest = false
}
