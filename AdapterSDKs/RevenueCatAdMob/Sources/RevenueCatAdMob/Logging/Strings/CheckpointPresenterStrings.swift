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
        }
    }

    var category: String { return "checkpoints" }
}

#endif
