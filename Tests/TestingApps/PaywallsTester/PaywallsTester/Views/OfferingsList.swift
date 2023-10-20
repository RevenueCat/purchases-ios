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

struct OfferingsList: View {

    fileprivate struct Template: Hashable {
        var name: String?
    }

    fileprivate struct Data: Hashable {
        var sections: [Template]
        var offeringsBySection: [Template: [Offering]]
    }

    @State
    private var offerings: Result<Data, NSError>?

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
                let offerings = try await Purchases.shared.offerings()
                    .all
                    .map(\.value)
                    .sorted { $0.serverDescription > $1.serverDescription }

                let offeringsBySection = Dictionary(
                    grouping: offerings,
                    by: { Template(name: $0.paywall?.templateName) }
                )

                self.offerings = .success(
                    .init(
                        sections: Array(offeringsBySection.keys).sorted { $0.description < $1.description },
                        offeringsBySection: offeringsBySection
                    )
                )
            } catch let error as NSError {
                self.offerings = .failure(error)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.offerings {
        case let .success(data):
            VStack {
                Text(Self.modesInstructions)
                    .font(.footnote)
                self.list(with: data)
            }

        case let .failure(error):
            Text(error.description)

        case .none:
            ProgressView()
        }
    }

    @ViewBuilder
    private func list(with data: Data) -> some View {
        List {
            ForEach(data.sections, id: \.self) { template in
                Section {
                    ForEach(data.offeringsBySection[template]!, id: \.id) { offering in
                        if let paywall = offering.paywall {
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
                        } else {
                            Text(offering.serverDescription)
                        }
                    }
                } header: {
                    Text(verbatim: template.description)
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
                Text(self.offering.serverDescription)
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

private struct PaywallPresenter: View {

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

extension OfferingsList.Template: CustomStringConvertible {

    var description: String {
        if let name = self.name {
            #if DEBUG
            if let template = PaywallTemplate(rawValue: name) {
                return template.name
            } else {
                return "Unrecognized template"
            }
            #else
            return name
            #endif
        } else {
            return "No paywall"
        }
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
