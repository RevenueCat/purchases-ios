//
//  OfferingsPaywallsViewModel.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import Foundation
import RevenueCat

struct OfferingPaywall: Hashable {
    let offering: OfferingsResponse.Offering
    let paywall: PaywallsResponse.Paywall
}

struct PresentedPaywall: Hashable {
    var offering: Offering
    var mode: PaywallViewMode
    var responseOfferingID: String
}

@Observable
final class OfferingsPaywallsViewModel {

    var app: DeveloperResponse.App?

    var offeringsPaywalls: Result<[OfferingPaywall], NSError>? {
        didSet {
            Task { @MainActor in
                refreshPresentedPaywall()
            }
        }
    }

    var presentedPaywall: PresentedPaywall?

    init(app: DeveloperResponse.App? = nil) {
        self.app = app
    }

    @MainActor
    func updateOfferingsAndPaywalls() async {
        do {
            guard let appCopy = app else { return }
            async let appOfferings = Self.fetchOfferings(for: appCopy).all
            async let appPaywalls = Self.fetchPaywalls(for: appCopy).all

            let offerings = try await appOfferings
            let paywalls = try await appPaywalls

            let offeringPaywallData = OfferingPaywallData(offerings: offerings, paywalls: paywalls)

            self.offeringsPaywalls = .success(
                offeringPaywallData.paywallsByOffering()
            )

        } catch let error as NSError {
            self.offeringsPaywalls = .failure(error)
        }
    }

    @MainActor
    private func refreshPresentedPaywall() {

        guard let currentPaywall = self.presentedPaywall else { return }

        switch self.offeringsPaywalls {
        case let .success(data):
            // Find the offering that corresponds to the currently presented paywall's offering.
            if let newData = data.first(where: { $0.offering.id == currentPaywall.responseOfferingID }) {
                let newRCOffering = newData.paywall.convertToRevenueCatPaywall(with: newData.offering)
                // if the paywall has changed, update what we're showing
                if currentPaywall.offering.paywall != newRCOffering.paywall {
                    self.presentedPaywall = .init(offering: newRCOffering, mode: currentPaywall.mode, responseOfferingID: currentPaywall.responseOfferingID)
                }
            }
        default:
        self.presentedPaywall = nil
        }
    }

    @MainActor
    private static func fetchOfferings(for app: DeveloperResponse.App) async throws -> OfferingsResponse {
        return try await HTTPClient.shared.perform(
            .init(
                method: .get,
                endpoint: .offerings(projectID: app.id)
            )
        )
    }

    @MainActor
    private static func fetchPaywalls(for app: DeveloperResponse.App) async throws -> PaywallsResponse {
        return try await HTTPClient.shared.perform(
            .init(
                method: .get,
                endpoint: .paywalls(projectID: app.id)
            )
        )
    }

    private struct OfferingPaywallData {

        var offerings: [OfferingsResponse.Offering]
        var paywalls: [PaywallsResponse.Paywall]

        func paywallsByOffering() -> [OfferingPaywall] {
            let paywallsByOfferingID = Set(self.paywalls).dictionaryWithKeys { $0.offeringID }

            var offeringPaywall = [OfferingPaywall]()
            for offering in self.offerings {
                if let paywall = paywallsByOfferingID[offering.id] {
                    offeringPaywall.append(OfferingPaywall(offering: offering, paywall: paywall))
                }
            }

            return offeringPaywall
        }
    }

}
