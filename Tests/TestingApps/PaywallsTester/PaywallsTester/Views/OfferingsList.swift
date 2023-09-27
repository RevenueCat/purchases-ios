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
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private var content: some View {
        switch self.offerings {
        case let .success(offerings):
            VStack {
                Text("Press and hold to open in different modes.")
                    .font(.footnote)
                self.list(with: offerings)
                    .sheet(item: self.$selectedOffering) { offering in
                        PaywallPresenter(selectedMode: self.$selectedMode,
                                         selectedOffering: self.$selectedOffering)
                    }
            }
            Text("Press and hold to open in different modes.")
                .font(.footnote)
            self.list(with: offerings)
            #if !targetEnvironment(macCatalyst)
                .sheet(item: self.$selectedOffering) { offering in
                    NavigationView {
                        switch self.$selectedMode.wrappedValue {
                        case .fullScreen:
                        PaywallView(offering: offering)
                            #if targetEnvironment(macCatalyst)
                            .toolbar {
                                ToolbarItem(placement: .destructiveAction) {
                                    Button {
                                        self.selectedOffering = nil
                                    } label: {
                                        Image(systemName: "xmark")
                                    }
                                }
                            }
                            #endif
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
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .contextMenu {
                        self.button(for: PaywallViewMode.fullScreen, offering: offering)
                        self.button(for: PaywallViewMode.condensedFooter, offering: offering)
                        self.button(for: PaywallViewMode.footer, offering: offering)
                    }

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
    
    @ViewBuilder
    private func button(for selectedMode: PaywallViewMode, offering: Offering) -> some View {
        Button(action: {
            self.selectedMode = selectedMode
            self.selectedOffering = offering
        }) {
            switch selectedMode {
            case .fullScreen:
                Text("Full Screen")
                Image(systemName: PaywallViewMode.fullScreen.icon)
            case .condensedFooter:
                Text("Condensed Footer")
                Image(systemName: PaywallViewMode.condensedFooter.icon)
            case .footer:
                Text("footer")
                Image(systemName: PaywallViewMode.footer.icon)
            }
        }
    }

}

struct PaywallPresenter: View {
    @Binding var selectedMode: PaywallViewMode
    @Binding var selectedOffering: Offering?

    var body: some View {
        NavigationView {
            switch selectedMode {
            case .fullScreen:
                PaywallView(offering: selectedOffering!)
                #if targetEnvironment(macCatalyst)
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            Button {
                                self.selectedOffering = nil
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
            #endif
            case .footer:
                VStack {
                    Spacer()
                    Text("This Paywall is being presented as a Footer")
                        .paywallFooter(offering: selectedOffering!)
                }
            case .condensedFooter:
                VStack {
                    Spacer()
                    Text("This Paywall is being presented as a Condensed Footer")
                        .paywallFooter(offering: selectedOffering!, condensed: true)
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
