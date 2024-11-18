//
//  APIKeyDashboardList.swift
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

struct APIKeyDashboardList: View {

    fileprivate struct Template: Hashable {
        var name: String?
    }

    fileprivate struct Data: Hashable {
        var sections: [Template]
        var offeringsBySection: [Template: [Offering]]
    }

    fileprivate struct PresentedPaywall: Hashable {
        var offering: Offering
        var mode: PaywallViewMode
    }

    @State
    private var offerings: Result<Data, NSError>?

    @State
    private var presentedPaywall: PresentedPaywall?

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
                    by: { Template(name: templateGroupName(offering: $0)) }
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

    private func templateGroupName(offering: Offering) -> String? {
        #if PAYWALL_COMPONENTS
        offering.paywall?.templateName ?? offering.paywallComponentsData?.templateName
        #else
        offering.paywall?.templateName
        #endif
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
            SwiftUI.ProgressView()
        }
    }

    private func offeringHasComponents(_ offering: Offering) -> Bool {
        #if PAYWALL_COMPONENTS
        offering.paywallComponentsData != nil
        #else
        false
        #endif
    }

    @ViewBuilder
    private func list(with data: Data) -> some View {
        List {
            ForEach(data.sections, id: \.self) { template in
                Section {
                    ForEach(data.offeringsBySection[template]!, id: \.id) { offering in
                        if offering.paywall != nil || offeringHasComponents(offering) {
                            #if targetEnvironment(macCatalyst)
                            NavigationLink(
                                destination: PaywallPresenter(offering: offering,
                                                              mode: .default,
                                                              introEligility: .eligible,
                                                              displayCloseButton: false),
                                tag: PresentedPaywall(offering: offering, mode: .default),
                                selection: self.$presentedPaywall
                            ) {
                                OfferButton(offering: offering) {}
                                .contextMenu {
                                    self.contextMenu(for: offering)
                                }
                            }
                            #else
                            OfferButton(offering: offering) {
                                self.presentedPaywall = .init(offering: offering, mode: .default)
                            }
                                #if !os(watchOS)
                                .contextMenu {
                                    self.contextMenu(for: offering)
                                }
                                #endif
                            #endif
                        }
                        else {
                            Text(offering.serverDescription)
                        }
                    }
                } header: {
                    Text(verbatim: template.description)
                }
            }
        }
        .sheet(item: self.$presentedPaywall) { paywall in
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode, introEligility: .eligible)
                .onRestoreCompleted { _ in
                    self.presentedPaywall = nil
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

    private struct OfferButton: View {
        let offering: Offering
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Text(self.offering.serverDescription)
                    Spacer()
                    #if PAYWALL_COMPONENTS
                    if let errorInfo = self.offering.paywallComponentsData?.errorInfo, !errorInfo.isEmpty {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.red)
                    }
                    #endif
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

extension APIKeyDashboardList.Template: CustomStringConvertible {

    var description: String {
        if let name = self.name {
            if name == "components" {
                return "V2"
            } else if let template = PaywallTemplate(rawValue: name) {
                return template.name
            } else {
                return "Unrecognized template"
            }
        } else {
            return "No paywall"
        }
    }

}

extension APIKeyDashboardList.PresentedPaywall: Identifiable {

    var id: String {
        return "\(self.offering.id)-\(self.mode.name)"
    }

}
