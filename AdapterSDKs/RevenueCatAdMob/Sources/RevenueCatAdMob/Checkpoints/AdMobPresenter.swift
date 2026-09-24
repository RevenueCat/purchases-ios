//
//  AdMobPresenter.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import UIKit

/// Errors produced by ``AdMobPresenter`` before any format-specific presenter is involved.
@available(iOS 15.0, *)
internal enum AdMobPresentationError: Error, CustomNSError {

    case unsupportedFormat(String)

    static let errorDomain = "RevenueCatAdMob.AdMobPresentationError"

    var errorCode: Int {
        switch self {
        case .unsupportedFormat: return 1
        }
    }

    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    var localizedDescription: String {
        switch self {
        case let .unsupportedFormat(adFormat):
            return "AdMobPresenter cannot present checkpoint ad steps with ad format '\(adFormat)'. " +
                "Supported formats: interstitial, rewarded, rewarded_interstitial."
        }
    }

}

/// Presents AdMob ads for checkpoint ad steps by delegating each step to the presenter for its ad format.
///
/// Register one instance on `Purchases.shared.adPresenter` to handle every AdMob format the adapter
/// supports; register ``AdMobInterstitialPresenter``, ``AdMobRewardedPresenter`` or
/// ``AdMobRewardedInterstitialPresenter`` directly instead if the app only ever configures one format.
///
/// AdMob ad units are format-locked, so an ad step whose format has no presenter here fails immediately
/// with an error in the `RevenueCatAdMob.AdMobPresentationError` domain rather than being loaded through
/// a presenter that would only report a no-fill.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@MainActor
public final class AdMobPresenter: AdPresenter {

    private let interstitialPresenter: AdPresenter
    private let rewardedPresenter: AdPresenter
    private let rewardedInterstitialPresenter: AdPresenter

    /// Creates a presenter that delegates to the adapter's format-specific AdMob presenters.
    public convenience init() {
        self.init(
            interstitialPresenter: AdMobInterstitialPresenter(),
            rewardedPresenter: AdMobRewardedPresenter(),
            rewardedInterstitialPresenter: AdMobRewardedInterstitialPresenter()
        )
    }

    init(
        interstitialPresenter: AdPresenter,
        rewardedPresenter: AdPresenter,
        rewardedInterstitialPresenter: AdPresenter
    ) {
        self.interstitialPresenter = interstitialPresenter
        self.rewardedPresenter = rewardedPresenter
        self.rewardedInterstitialPresenter = rewardedInterstitialPresenter
    }

    /// Forwards the ad step to the presenter for `params.adFormat`.
    public func present(
        params: AdPresentationParams,
        completion: @escaping AdPresentationCompletion
    ) {
        switch params.adFormat {
        case .interstitial:
            self.interstitialPresenter.present(params: params, completion: completion)
        case .rewarded:
            self.rewardedPresenter.present(params: params, completion: completion)
        case .rewardedInterstitial:
            self.rewardedInterstitialPresenter.present(params: params, completion: completion)
        default:
            Logger.warn(CheckpointPresenterStrings.unsupported_format(adFormat: params.adFormat.rawValue))
            completion(.failed(error: AdMobPresentationError.unsupportedFormat(params.adFormat.rawValue) as NSError))
        }
    }

}

#endif
