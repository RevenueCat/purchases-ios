//
//  CheckpointPresenterStrings.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat

// swiftlint:disable identifier_name
enum CheckpointPresenterStrings {

    case interstitial_unsupported_mediator(mediator: String)
    case interstitial_load_failed(adUnitID: String, error: Error)
    case interstitial_no_presentation_context
    case interstitial_present_failed(error: Error)
    case rewarded_unsupported_mediator(adFormat: AdFormat, mediator: String)
    case rewarded_load_failed(adFormat: AdFormat, adUnitID: String, error: Error)
    case rewarded_no_presentation_context(adFormat: AdFormat)
    case rewarded_present_failed(adFormat: AdFormat, error: Error)
    case rewarded_verification_failed(adFormat: AdFormat, adUnitID: String)
}

extension CheckpointPresenterStrings: LogMessage {

    var description: String {
        switch self {
        case let .interstitial_unsupported_mediator(mediator):
            return "Checkpoint ad step is configured for mediator '\(mediator)'; " +
                "AdMobInterstitialPresenter only presents AdMob ad units."
        case let .interstitial_load_failed(adUnitID, error):
            return "Checkpoint interstitial failed to load for ad unit '\(adUnitID)': \(error.localizedDescription)"
        case .interstitial_no_presentation_context:
            return "Checkpoint interstitial loaded but no view controller is available to present it from."
        case let .interstitial_present_failed(error):
            return "Checkpoint interstitial failed to present: \(error.localizedDescription)"
        case let .rewarded_unsupported_mediator(adFormat, mediator):
            return "Checkpoint \(adFormat.rawValue) ad step is configured for mediator '\(mediator)'; " +
                "only AdMob ad units can be presented."
        case let .rewarded_load_failed(adFormat, adUnitID, error):
            return "Checkpoint \(adFormat.rawValue) ad failed to load for ad unit '\(adUnitID)': " +
                "\(error.localizedDescription)"
        case let .rewarded_no_presentation_context(adFormat):
            return "Checkpoint \(adFormat.rawValue) ad loaded but no view controller is available to present it from."
        case let .rewarded_present_failed(adFormat, error):
            return "Checkpoint \(adFormat.rawValue) ad failed to present: \(error.localizedDescription)"
        case let .rewarded_verification_failed(adFormat, adUnitID):
            return "Checkpoint \(adFormat.rawValue) ad for ad unit '\(adUnitID)' was watched but reward verification " +
                "failed; no reward was granted."
        }
    }

    var category: String { return "checkpoints" }
}

#endif
