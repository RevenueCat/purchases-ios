//
//  SamplePaywallsList.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/27/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct OfferingsList: View {

    @State
    private var offerings: Result<[Offering], NSError>?

    @State
    private var selectedOffering: Offering?

    var body: some View {
        NavigationView {
            self.content
                .navigationTitle("Live Paywalls")
        }
            .task {
                do {
                    self.offerings = .success(
                        try await Purchases.shared.offerings()
                            .all
                            .map(\.value)
                            .sorted { $0.serverDescription > $1.serverDescription }
                    )
                } catch let error as NSError {
                    self.offerings = .failure(error)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch self.offerings {
        case let .success(offerings):
            self.list(with: offerings)
            #if !targetEnvironment(macCatalyst)
                .sheet(item: self.$selectedOffering) { offering in
                    NavigationView {
                        PaywallView(offering: offering)
                    }
                }
            #endif
        case let .failure(error):
            Text(error.description)

        case .none:
            ProgressView()
        }
    }

    @ViewBuilder
    private func list(with offerings: some Collection<Offering>) -> some View {
        List {
            let offeringsWithPaywall = Self.offeringsWithPaywall(from: offerings)

            Section {
                ForEach(offeringsWithPaywall, id: \.offering.id) { offering, paywall in
                    #if targetEnvironment(macCatalyst)
                    NavigationLink(
                        destination: PaywallView(offering: offering),
                        tag: offering,
                        selection: self.$selectedOffering
                    ) {
                        OfferButton(offering: offering, paywall: paywall) {
                            self.selectedOffering = offering
                        }
                    }
                    #else
                    OfferButton(offering: offering, paywall: paywall) {
                        self.selectedOffering = offering
                    }
                    #endif
                }
            } header: {
                Text(verbatim: "With paywall")
            } footer: {
                if offeringsWithPaywall.isEmpty {
                    Text(verbatim: "No offerings with paywall")
                }
            }

            Section("Without paywall") {
                ForEach(Self.offeringsWithNoPaywall(from: offerings), id: \.id) { offering in
                    Text(offering.serverDescription)
                }
            }
        }
    }

    private struct OfferButton: View {
        let offering: Offering
        let paywall: PaywallData
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading) {
                    Text(offering.serverDescription)
                    Text(verbatim: "Template: \(paywall.templateName)")
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

}

private extension OfferingsList {

    static func offeringsWithPaywall(
        from offerings: some Collection<Offering>
    ) -> [(offering: Offering, paywall: PaywallData)] {
        return offerings
            .compactMap { offering in
                if let paywall = offering.paywall {
                    return (offering, paywall)
                } else {
                    return nil
                }
            }
    }

    static func offeringsWithNoPaywall(from offerings: some Collection<Offering>) -> [Offering] {
        return offerings.filter { $0.paywall == nil }
    }

}

#if DEBUG

struct OfferingsList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SamplePaywallsList()
        }
    }
}

#endif
