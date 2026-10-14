//
//  InterstitialEventTracker.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(PrebidMobile)
@_spi(Internal) import RevenueCat

/// Maps an interstitial's ``AdModuleEvent``s to RevenueCat ad events.
///
/// Tracking is fire-and-forget and never affects the ad flow; it is skipped while `Purchases` is not configured.
@MainActor
struct InterstitialEventTracker {

    let placementID: String
    let tracking: AdTracking

    func track(_ event: AdModuleEvent, unit: AdModuleInterstitial, impressionID: String) {
        guard self.tracking.isConfigured else {
            Logger.debug(AdsTrackingStrings.purchases_not_configured(event: event.trackingName))
            return
        }

        switch event {
        case .loaded:
            self.tracking.trackAdLoaded(AdLoaded(
                networkName: unit.networkName,
                mediatorName: .revenueCat,
                adFormat: .interstitial,
                placement: self.placementID,
                adUnitId: self.placementID,
                impressionId: impressionID
            ))
        case let .failedToLoad(error):
            self.tracking.trackAdFailedToLoad(AdFailedToLoad(
                mediatorName: .revenueCat,
                adFormat: .interstitial,
                placement: self.placementID,
                adUnitId: self.placementID,
                mediatorErrorCode: (error.underlyingError as NSError?)?.code
            ))
        case .presented:
            self.tracking.trackAdDisplayed(AdDisplayed(
                networkName: unit.networkName,
                mediatorName: .revenueCat,
                adFormat: .interstitial,
                placement: self.placementID,
                adUnitId: self.placementID,
                impressionId: impressionID
            ))
        case .clicked:
            self.tracking.trackAdOpened(AdOpened(
                networkName: unit.networkName,
                mediatorName: .revenueCat,
                adFormat: .interstitial,
                placement: self.placementID,
                adUnitId: self.placementID,
                impressionId: impressionID
            ))
        case .impression:
            self.trackRevenue(unit: unit, impressionID: impressionID)
        case .dismissed:
            break
        }
    }

    private func trackRevenue(unit: AdModuleInterstitial, impressionID: String) {
        guard let revenue = unit.revenue else {
            Logger.debug(AdsTrackingStrings.revenue_unavailable(placementID: self.placementID))
            return
        }

        self.tracking.trackAdRevenue(AdRevenue(
            networkName: unit.networkName,
            mediatorName: .revenueCat,
            adFormat: .interstitial,
            placement: self.placementID,
            adUnitId: self.placementID,
            impressionId: impressionID,
            revenueMicros: revenue.micros,
            currency: revenue.currency,
            precision: revenue.precision
        ))
    }

}

private extension AdModuleEvent {

    var trackingName: String {
        switch self {
        case .loaded: return "loaded"
        case .failedToLoad: return "failed_to_load"
        case .presented: return "displayed"
        case .impression: return "revenue"
        case .clicked: return "opened"
        case .dismissed: return "dismissed"
        }
    }

}

// swiftlint:disable identifier_name
enum AdsTrackingStrings {

    case purchases_not_configured(event: String)
    case revenue_unavailable(placementID: String)

}
// swiftlint:enable identifier_name

extension AdsTrackingStrings: LogMessage {

    var description: String {
        switch self {
        case let .purchases_not_configured(event):
            return "Purchases is not configured. Skipping ad \(event) tracking."
        case let .revenue_unavailable(placementID):
            return "No bid price for the ad in placement \(placementID). Skipping ad revenue tracking."
        }
    }

    var category: String { return "ads" }

}

#endif
