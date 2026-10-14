//
//  PrebidAdModule.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(PrebidMobile)
import PrebidMobile
import RevenueCat
import UIKit

/// `AdModule` backed by Prebid Mobile's rendering API, talking directly to the RevenueCat
/// auction endpoint. This is the only file that may import `PrebidMobile`.
@MainActor
final class PrebidAdModule: AdModule {

    static let authorizationHeader = "Authorization"
    // Prebid copies the account ID into the request body, so it must not be the API key.
    static let accountID = "revenuecat"

    func initialize(with configuration: ResolvedAdsConfiguration) throws {
        let prebid = Prebid.shared
        // The backend authenticates with the header and overwrites `app.publisher.id` itself,
        // but Prebid refuses to send a request without a non-empty account ID.
        prebid.prebidServerAccountId = Self.accountID
        prebid.addCustomHeader(name: Self.authorizationHeader, value: configuration.authorizationHeaderValue)
        // Prebid derives its status URL from the host only (forcing https and dropping the port),
        // and the RevenueCat backend exposes no `/status` route, so the check would only fail.
        prebid.shouldDisableStatusCheck = true

        // Referenced by full name: plain `initializeSDK(serverURL:)` also matches the GMA overloads,
        // which log errors when no Google Mobile Ads version is passed.
        let initializeSDK = Prebid.initializeSDK(serverURL:_:)
        do {
            try initializeSDK(configuration.auctionURL.absoluteString, nil)
        } catch {
            throw AdsError(
                code: .invalidConfiguration,
                message: "Ad SDK rejected the auction URL \(configuration.auctionURL).",
                underlyingError: error
            )
        }
    }

    func makeInterstitial(placementID: String) -> AdModuleInterstitial {
        return PrebidInterstitial(placementID: placementID)
    }

}

@MainActor
final class PrebidInterstitial: NSObject, AdModuleInterstitial {

    // The RevenueCat auction only configures the Equativ (`smartadserver`) bidder, and Prebid's
    // rendering API does not expose the winning seat.
    nonisolated static let networkName = "Equativ"
    // Prebid Server answers in its ad server currency, USD unless configured otherwise.
    nonisolated static let currency = "USD"

    var onEvent: ((AdModuleEvent) -> Void)?

    private let adUnit: InterstitialRenderingAdUnit
    private let eventHandler: PrebidBidCapturingEventHandler

    init(placementID: String) {
        let eventHandler = PrebidBidCapturingEventHandler()
        self.eventHandler = eventHandler
        self.adUnit = InterstitialRenderingAdUnit(configID: placementID, eventHandler: eventHandler)
        super.init()
        self.adUnit.delegate = self
    }

    var isReady: Bool { self.adUnit.isReady }

    var networkName: String { Self.networkName }

    var revenue: AdModuleRevenue? {
        guard let price = self.eventHandler.bidResponse?.winningBid?.price else { return nil }
        return Self.revenue(fromCPM: price)
    }

    func load() {
        self.adUnit.loadAd()
    }

    func show(from viewController: UIViewController) {
        self.adUnit.show(from: viewController)
    }

    nonisolated static func revenue(fromCPM cpm: Float) -> AdModuleRevenue? {
        guard cpm > 0 else { return nil }
        // CPM is per thousand impressions: one impression earns cpm / 1_000 units, i.e. cpm * 1_000 micros.
        return AdModuleRevenue(
            micros: Int((Double(cpm) * 1_000).rounded()),
            currency: Self.currency,
            precision: .exact
        )
    }

    nonisolated static func adsError(from error: Error?) -> AdsError {
        guard let error else {
            return AdsError(code: .loadFailed, message: "The ad failed to load without an error.")
        }

        let resultCode = (error as NSError).userInfo[PrebidConstants.FETCH_DEMAND_RESULT_KEY] as? Int
        if resultCode == ResultCode.prebidDemandNoBids.rawValue {
            return AdsError(code: .noFill, message: "No ad was available.", underlyingError: error)
        }
        return AdsError(code: .loadFailed, message: "The ad failed to load.", underlyingError: error)
    }

    private nonisolated func deliver(_ event: AdModuleEvent) {
        // Prebid documents main-thread delivery; hop rather than trap if that ever changes.
        if Thread.isMainThread {
            MainActor.assumeIsolated { self.onEvent?(event) }
        } else {
            Task { @MainActor in self.onEvent?(event) }
        }
    }

}

extension PrebidInterstitial: InterstitialAdUnitDelegate {

    nonisolated func interstitialDidReceiveAd(_ interstitial: InterstitialRenderingAdUnit) {
        self.deliver(.loaded)
    }

    nonisolated func interstitial(_ interstitial: InterstitialRenderingAdUnit,
                                  didFailToReceiveAdWithError error: Error?) {
        self.deliver(.failedToLoad(Self.adsError(from: error)))
    }

    nonisolated func interstitialWillPresentAd(_ interstitial: InterstitialRenderingAdUnit) {
        self.deliver(.presented)
        // Prebid Mobile 3.3.1 fires its impression trackers internally on display but never surfaces
        // an impression callback for rendering interstitials, so presentation is the closest signal.
        self.deliver(.impression)
    }

    nonisolated func interstitialDidClickAd(_ interstitial: InterstitialRenderingAdUnit) {
        self.deliver(.clicked)
    }

    nonisolated func interstitialDidDismissAd(_ interstitial: InterstitialRenderingAdUnit) {
        self.deliver(.dismissed)
    }

}

/// Behaves like Prebid's `InterstitialEventHandlerStandalone` (Prebid always renders the winning bid),
/// but keeps the bid response, which `InterstitialRenderingAdUnit` does not expose otherwise.
final class PrebidBidCapturingEventHandler: NSObject, InterstitialEventHandlerProtocol {

    weak var loadingDelegate: InterstitialEventLoadingDelegate?
    weak var interactionDelegate: InterstitialEventInteractionDelegate?

    private(set) var bidResponse: BidResponse?

    var isReady: Bool { false }

    func requestAd(with bidResponse: BidResponse?) {
        self.bidResponse = bidResponse
        self.loadingDelegate?.prebidDidWin()
    }

    func show(from viewController: UIViewController?) {}

}

#endif
