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
                .sheet(item: self.$selectedOffering) { offering in
                    PaywallView(offering: offering)
                }

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
                    Button {
                        self.selectedOffering = offering
                    } label: {
                        VStack(alignment: .leading) {
                            Text(offering.serverDescription)
                            Text(verbatim: "Template: \(paywall.templateName)")
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
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
