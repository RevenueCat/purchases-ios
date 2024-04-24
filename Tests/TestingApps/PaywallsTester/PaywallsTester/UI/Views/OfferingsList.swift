//
//  SamplePaywallsList.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/27/23.
//

import RevenueCat
#if DEBUG
@testable import RevenueCatUI
#else
import RevenueCatUI
#endif
import SwiftUI

// TODO: Ask Barbara about how to present
struct OfferingsList: View {
    
    private struct OfferingPaywall: Hashable {
        let offering: OfferingsResponse.Offering
        let paywall: PaywallsResponse.Paywall
    }

    fileprivate struct PresentedPaywall: Hashable {
        var offering: Offering
        var mode: PaywallViewMode
    }

    @State
    private var offeringsPaywalls: Result<[OfferingPaywall], NSError>?

    @State
    private var presentedPaywall: PresentedPaywall?
    
    @State
    private var displayPaywall: Bool = false
    
    private let client = HTTPClient.shared
    
    let app: DeveloperResponse.App

    fileprivate func updateOfferingsAndPaywalls() async {
        do {
            async let appOfferings = fetchOfferings(for: app).all
            async let appPaywalls = fetchPaywalls(for: app).all
            
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
    
    var body: some View {
        self.content
            .navigationTitle("Paywalls")
            .task {
                await updateOfferingsAndPaywalls()
            }
    }
    
    public func fetchOfferings(for app: DeveloperResponse.App) async throws -> OfferingsResponse {
        return try await self.client.perform(
            .init(
                method: .get,
                endpoint: .offerings(projectID: app.id)
            )
        )
    }
    
    public func fetchPaywalls(for app: DeveloperResponse.App) async throws -> PaywallsResponse {
        return try await self.client.perform(
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

    @ViewBuilder
    private var content: some View {
        switch self.offeringsPaywalls {
        case let .success(data):
            VStack {
                Text(Self.modesInstructions)
                    .font(.footnote)
                if data.isEmpty {
                    ContentUnavailableView("No paywalls configured", systemImage: "exclamationmark.triangle.fill")
                } else {
                    self.list(with: data)
                }
            }

        case let .failure(error):
            Text(error.description)

        case .none:
            SwiftUI.ProgressView()
        }
    }

    @ViewBuilder
    private func list(with data: [OfferingPaywall]) -> some View {
        List {
            ForEach(data, id: \.self) { offeringPaywall in
                let responseOffering = offeringPaywall.offering
                let responsePaywall = offeringPaywall.paywall
                let rcOffering = responsePaywall.convertToRevenueCatPaywall(with: responseOffering)
                Section {
                    Button {
                        self.presentedPaywall = .init(offering: rcOffering, mode: .default)
                        Task {
                            // The paywall data may have changed, reload
                            let currentId = offeringPaywall.offering.id
                            await updateOfferingsAndPaywalls()
                            switch self.offeringsPaywalls {
                            case let .success(data):
                                if let newData = data.first(where: { $0.offering.id == currentId }) {
                                    let newOffering = newData.offering
                                    let newPaywall = newData.paywall
                                    let newRCOffering = newPaywall.convertToRevenueCatPaywall(with: newOffering)
                                    self.presentedPaywall = .init(offering: newRCOffering, mode: .default)
                                }
                            default:
                            self.presentedPaywall = nil
                            }
                        }
                    } label: {
                        let name = responsePaywall.data.templateName
                        let humanTemplateName = PaywallTemplate(rawValue: name)?.name ?? name
                        Text("Template \(humanTemplateName)")
                    }
                    #if !os(watchOS)
                    .contextMenu {
                        let rcOffering = responsePaywall.convertToRevenueCatPaywall(with: responseOffering)
                        self.contextMenu(for: rcOffering)
                    }
                    #endif
                } header: {
                    Text(responseOffering.displayName)
                }
            }
        }
        .sheet(item: self.$presentedPaywall) { paywall in
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode)
                .onRestoreCompleted { _ in
                    self.presentedPaywall = nil
                }
                .id(presentedPaywall?.hashValue)
        }
        .refreshable {
            Task {
                await updateOfferingsAndPaywalls()
            }
        }
    }

    #if !os(watchOS)
    @ViewBuilder
    private func contextMenu(for offering: Offering) -> some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            self.button(for: mode, offering: offering)
        }
    }
    #endif

    @ViewBuilder
    private func button(for selectedMode: PaywallViewMode, offering: Offering) -> some View {
        Button {
            self.presentedPaywall = .init(offering: offering, mode: selectedMode)
        } label: {
            Text(selectedMode.name)
            Image(systemName: selectedMode.icon)
        }
    }

    #if targetEnvironment(macCatalyst)
    private static let modesInstructions = "Right click or ⌘ + click to open in different modes."
    #else
    private static let modesInstructions = "Pull to refresh\nPress and hold to open in different modes."
    #endif

}

private struct PaywallPresenter: View {

    var offering: Offering
    var mode: PaywallViewMode
    var displayCloseButton: Bool = Configuration.defaultDisplayCloseButton

    var body: some View {
        switch self.mode {
        case .fullScreen:
            PaywallView(offering: self.offering, displayCloseButton: self.displayCloseButton)

        #if !os(watchOS)
        case .footer:
            CustomPaywallContent()
                .paywallFooter(offering: self.offering)

        case .condensedFooter:
            CustomPaywallContent()
                .paywallFooter(offering: self.offering, condensed: true)
        #endif
        }
    }

}

extension OfferingsList.PresentedPaywall: Identifiable {

    var id: String {
        return "\(self.offering.id)-\(self.mode.name)"
    }

}

#if DEBUG

// TODO: Mock DeveloperResponse to instantiate OfferingsList
struct OfferingsList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OfferingsList(app: MockData.developer().apps.first!)
        }
    }
}

#endif
