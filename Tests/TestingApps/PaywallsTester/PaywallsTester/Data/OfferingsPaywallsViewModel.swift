//
//  OfferingsPaywallsViewModel.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import Foundation
import RevenueCat

struct PaywallsData: Hashable {
    let offeringsAndPaywalls: [OfferingPaywall]
    let offeringsWithoutPaywalls: [OfferingsResponse.Offering]
}

struct OfferingPaywall: Hashable {
    let offering: OfferingsResponse.Offering
    let paywall: PaywallsResponse.Paywall
    let rcOffering: Offering
}

struct PresentedPaywall: Hashable {
    var offering: Offering
    var mode: PaywallViewMode
    var responseOfferingID: String
}

@Observable
final class OfferingsPaywallsViewModel {

    enum State {
        case notloaded
        case success
        case error(NSError)
    }

    private(set) var state: State
    private(set) var hasMultipleTemplates = false
    private(set) var hasMultipleOfferingsWithPaywalls = false
    var presentedPaywall: PresentedPaywall?

    var listData: PaywallsData? {
        didSet {
            Task { @MainActor in
                refreshPresentedPaywall()
            }
        }
    }

    var singleApp: DeveloperResponse.App? {
        guard apps.count == 1 else { return nil }
        return apps.first
    }

    init(apps: [DeveloperResponse.App]) {
        self.apps = apps
        state = .notloaded
    }

    @MainActor
    func updateOfferingsAndPaywalls() async {
        do {
            let appCopy = apps
            async let appOfferings = Self.fetchOfferings(for: appCopy).all
            async let appPaywalls = Self.fetchPaywalls(for: appCopy).all

            let offerings = try await appOfferings
            let paywalls = try await appPaywalls

            let offeringPaywallData = OfferingPaywallData(offerings: offerings, paywalls: paywalls)
            let listData = PaywallsData(offeringsAndPaywalls: offeringPaywallData.paywallsByOffering(), offeringsWithoutPaywalls: offeringPaywallData.offeringsWithoutPaywalls())
            self.hasMultipleTemplates = Set(listData.offeringsAndPaywalls.map { $0.paywall.data.templateName }).count > 1
            self.hasMultipleOfferingsWithPaywalls = listData.offeringsAndPaywalls.count > 1
            self.listData = listData
            self.state = .success
        } catch let error as NSError {
            Self.logger.log(level: .error, "Could not fetch offerings/paywalls: \(error)")
            self.state = .error(error)
        }
    }
    
    @MainActor
    func getAndShowPaywallForID(id: String, mode: PaywallViewMode = .default) async {

        showPaywallForID(id, mode: mode)

        // in case data has changed since last fetch
        await updateOfferingsAndPaywalls()

        showPaywallForID(id, mode: mode)
    }

    @MainActor
    func dismissPaywall() {
        self.presentedPaywall = nil
    }

    private static var logger = Logging.shared.logger(category: "Paywalls Tester")

    private var apps: [DeveloperResponse.App]

}

// Private helpers
extension OfferingsPaywallsViewModel {

    private struct OfferingPaywallData {

        var offerings: [OfferingsResponse.Offering]
        var paywalls: [PaywallsResponse.Paywall]

        func paywallsByOffering() -> [OfferingPaywall] {
            let paywallsByOfferingID = self.paywalls.dictionaryWithKeys { $0.offeringID }

            var offeringPaywall = [OfferingPaywall]()
            for offering in self.offerings {
                if let paywall = paywallsByOfferingID[offering.id] {
                    let rcOffering = paywall.convertToRevenueCatPaywall(with: offering)
                    offeringPaywall.append(OfferingPaywall(offering: offering, paywall: paywall, rcOffering: rcOffering))
                }
            }

            return offeringPaywall
        }

        func offeringsWithoutPaywalls() -> [OfferingsResponse.Offering] {
            let paywallsByOfferingID = self.paywalls.dictionaryWithKeys { $0.offeringID }

            return self.offerings.filter { paywallsByOfferingID[$0.id] == nil }
        }

    }

    @MainActor
    private func showPaywallForID(_ id: String, mode: PaywallViewMode = .default) {
        switch self.state {
        case .notloaded:
            Self.logger.log(level: .info, "Could not show paywall for id \(id), data not loaded.")
            self.presentedPaywall = nil
        case .success:
            if let newRCOffering = listData?.offeringsAndPaywalls.first(where: { $0.offering.id == id })?.rcOffering {
                if self.presentedPaywall == nil || self.presentedPaywall?.offering.paywall != newRCOffering.paywall {
                    self.presentedPaywall = .init(offering: newRCOffering, mode: mode, responseOfferingID: id)
                }
            }
        case .error(let error):
            Self.logger.log(level: .error, "Could not find a paywall for id \(id), error: \(error)")
            self.presentedPaywall = nil
        }
    }

    @MainActor
    private func refreshPresentedPaywall() {
        guard let currentPaywall = self.presentedPaywall else { return }

        showPaywallForID(currentPaywall.responseOfferingID)
    }

    // MARK: - Network
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
    private static func fetchOfferings(for apps: [DeveloperResponse.App]) async throws -> OfferingsResponse {
        var combinedOfferings: OfferingsResponse = OfferingsResponse()

        try await withThrowingTaskGroup(of: OfferingsResponse.self) { group in
            for app in apps {
                group.addTask {
                    return try await fetchOfferings(for: app)
                }
            }

            for try await offerings in group {
                combinedOfferings.all.append(contentsOf: offerings.all)
            }
        }
        return combinedOfferings
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

    @MainActor
    private static func fetchPaywalls(for apps: [DeveloperResponse.App]) async throws -> PaywallsResponse {
        var combinedPaywalls: PaywallsResponse = PaywallsResponse()

        try await withThrowingTaskGroup(of: PaywallsResponse.self) { group in
            for app in apps {
                group.addTask {
                    return try await fetchPaywalls(for: app)
                }
            }

            // Collect results
            for try await paywalls in group {
                combinedPaywalls.all.append(contentsOf: paywalls.all)
            }
        }
        return combinedPaywalls
    }

}
