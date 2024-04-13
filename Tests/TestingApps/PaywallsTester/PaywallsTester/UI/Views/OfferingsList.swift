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
    
    typealias Data2 = [OfferingsResponse.Offering: [PaywallsResponse.Paywall]]

    fileprivate struct PresentedPaywall: Hashable {
        var offering: Offering
        var mode: PaywallViewMode
    }

    @State
    private var offerings: Result<Data, NSError>?
    
    @State
    private var offerings2: Result<Data2, NSError>?

    @State
    private var presentedPaywall: PresentedPaywall?
    
    private let client = HTTPClient.shared
    
    let developer: DeveloperResponse
    
    @State
    private var displayPaywall: Bool = false

    var body: some View {
        NavigationView {
            self.content
                .navigationTitle("Live Paywalls")
        }
        .task {
            do {
//                let offerings = try await Purchases.shared.offerings()
//                    .all
//                    .map(\.value)
//                    .sorted { $0.serverDescription > $1.serverDescription }
//
//                let offeringsBySection = Dictionary(
//                    grouping: offerings,
//                    by: { Template(name: $0.paywall?.templateName) }
//                )
                
                // TODO: Collect ALL offerings, paywalls
                let offerings2 = try await fetchOfferings(for: developer.apps.first!).all
                let paywalls2 = try await fetchPaywalls(for: developer.apps.first!).all
                
                let offeringPaywallData = OfferingPaywallData(offerings: offerings2, paywalls: paywalls2)
                
                
                self.offerings2 = .success(
                    offeringPaywallData.paywallsByOffering()
                )

//                self.offerings = .success(
//                    .init(
//                        sections: Array(offeringsBySection.keys).sorted { $0.description < $1.description },
//                        offeringsBySection: offeringsBySection
//                    )
//                )
            } catch let error as NSError {
                self.offerings = .failure(error)
            }
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
    
    struct OfferingPaywallData {

        var offerings: [OfferingsResponse.Offering]
        var paywalls: [PaywallsResponse.Paywall]
        
        
        func paywallsByOffering() -> [OfferingsResponse.Offering: [PaywallsResponse.Paywall]] {
            let paywallsByOfferingID = Set(self.paywalls).dictionaryWithKeys { $0.offeringID }

            var dictionary: [OfferingsResponse.Offering: [PaywallsResponse.Paywall]] = [:]
            for offering in self.offerings {
                if let paywall = paywallsByOfferingID[offering.id] {
                    dictionary[offering, default: [PaywallsResponse.Paywall]()].append(paywall)
                }
            }

            return dictionary
        }

    }

    @ViewBuilder
    private var content: some View {
        switch self.offerings2 {
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

    @ViewBuilder
    private func list(with data: [OfferingsResponse.Offering: [PaywallsResponse.Paywall]]) -> some View {
        List {
            ForEach(Array(data.keys), id: \.self) { offering in
                Section {
                    ForEach(data[offering]!, id: \.self) { paywall in
//                        if let paywall = offering.paywall {
                            #if targetEnvironment(macCatalyst)
                            NavigationLink(
                                destination: PaywallPresenter(offering: offering, 
                                                              mode: .default,
                                                              displayCloseButton: false),
                                tag: PresentedPaywall(offering: offering, mode: .default),
                                selection: self.$presentedPaywall
                            ) {
                                OfferButton(offering: offering, paywall: paywall) {}
                                .contextMenu {
                                    self.contextMenu(for: offering)
                                }
                            }
                            #else
                            Button {
                                self.displayPaywall = true
                            } label: {
                                Text("Template \(paywall.data.templateName)")
                                
                            }
                            .sheet(isPresented: self.$displayPaywall) {
                                PaywallView(offering: paywall.convertToRevenueCatPaywall(with: offering))
                            }

                                #if !os(watchOS)
//                                .contextMenu {
//                                    self.contextMenu(for: offering)
//                                }
                                #endif
                            #endif
//                        } else {
//                            Text(offering.serverDescription)
//                        }
                    }
                } header: {
                    Text(offering.displayName)
                }
            }
        }
        .sheet(item: self.$presentedPaywall) { paywall in
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode)
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

extension OfferingsList.PresentedPaywall: Identifiable {

    var id: String {
        return "\(self.offering.id)-\(self.mode.name)"
    }

}

#if DEBUG

// TODO: Mock DeveloperResponse to instantiate OfferingsList
//struct OfferingsList_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            OfferingsList()
//        }
//    }
//}

#endif
