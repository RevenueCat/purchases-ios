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

    @State
    private var selectedMode: PaywallViewMode = .fullScreen

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
            VStack {
                Text(Self.modesInstructions)
                    .font(.footnote)
                self.list(with: offerings)
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
                    #if targetEnvironment(macCatalyst)
                    NavigationLink(
                        destination: PaywallPresenter(selectedMode: self.$selectedMode,
                                                      selectedOffering: self.$selectedOffering),
                        tag: offering,
                        selection: self.$selectedOffering
                    ) {
                        OfferButton(offering: offering, paywall: paywall) {
                            self.selectedOffering = offering
                        }
                        .contextMenu {
                            self.contextMenu(for: offering)
                        }
                    }
                    #else
                    OfferButton(offering: offering, paywall: paywall) {
                        self.selectedOffering = offering
                    }
                    .contextMenu {
                        self.contextMenu(for: offering)
                    }
                    .sheet(item: self.$selectedOffering) { offering in
                        PaywallPresenter(selectedMode: self.$selectedMode,
                                         selectedOffering: self.$selectedOffering)
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

    @ViewBuilder
    private func contextMenu(for offering: Offering) -> some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            self.button(for: mode, offering: offering)
        }
    }

    @ViewBuilder
    private func button(for selectedMode: PaywallViewMode, offering: Offering) -> some View {
        Button {
            self.selectedMode = selectedMode
            self.selectedOffering = offering
        } label: {
            Text(selectedMode.name)
            Image(systemName: selectedMode.icon)
        }
    }

    private struct OfferButton: View {
        let offering: Offering
        let paywall: PaywallData
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading) {
                    Text(self.offering.serverDescription)
                    Text(verbatim: "Template: \(self.paywall.templateName)")
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

    #if targetEnvironment(macCatalyst)
    private static let modesInstructions = "Right click or ⌘ + click to open in different modes."
    #else
    private static let modesInstructions = "Press and hold to open in different modes."
    #endif

}

struct PaywallPresenter: View {

    @Binding var selectedMode: PaywallViewMode
    @Binding var selectedOffering: Offering?

    var body: some View {
        Group {
            if let offering = self.selectedOffering {
                switch self.selectedMode {
                case .fullScreen:
                    PaywallView(offering: offering)
                    
                case .footer:
                    VStack {
                        Spacer()
                        Text("This Paywall is being presented as a Footer")
                            .paywallFooter(offering: offering)
                    }
                case .condensedFooter:
                    VStack {
                        Spacer()
                        Text("This Paywall is being presented as a Condensed Footer")
                            .paywallFooter(offering: offering, condensed: true)
                    }
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
            OfferingsList()
        }
    }
}

#endif
