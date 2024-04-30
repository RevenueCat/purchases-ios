//
//  OfferingButton.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-30.
//

import SwiftUI
import RevenueCat

struct OfferingButton: View {

    let responseOffering: OfferingsResponse.Offering
    let responsePaywall: PaywallsResponse.Paywall
    let rcOffering: Offering
    let multipleOfferings: Bool
    let hasMultipleTemplates: Bool
    let viewModel: OfferingsPaywallsViewModel
    @Binding var selectedItemID: String?

    init(offeringPaywall: OfferingPaywall,
         multipleOfferings: Bool,
         hasMultipleTemplates: Bool,
         viewModel: OfferingsPaywallsViewModel,
         selectedItemID: Binding<String?>) {
        self.responseOffering = offeringPaywall.offering
        self.responsePaywall = offeringPaywall.paywall
        self.rcOffering = responsePaywall.convertToRevenueCatPaywall(with: responseOffering)
        self.multipleOfferings = multipleOfferings
        self.hasMultipleTemplates = hasMultipleTemplates
        self.viewModel = viewModel
        self._selectedItemID = selectedItemID
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                Task {
                    await viewModel.getAndShowPaywallForID(id: responseOffering.id)
                    selectedItemID = responseOffering.identifier
                }
            } label: {
                let templateName = rcOffering.paywall?.templateName
                let paywallTitle = rcOffering.paywall?.localizedConfiguration.title
                let decorator = multipleOfferings && self.selectedItemID == responseOffering.identifier ? "▶ " : ""
                HStack {
                    VStack(alignment:.leading, spacing: 5) {
                        Text(decorator + responseOffering.displayName)
                            .font(.headline)
                        if let title = paywallTitle, let name = templateName {
                            let text = hasMultipleTemplates ? "Style \(name): \(title)" : title
                            Text(text)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    offeringButtonMenu(offeringID: responseOffering.id)
                    .padding(.all, 0)
                }
            }
        }
        #if !os(watchOS)
        .contextMenu {
            contextMenuItems(offeringID: responseOffering.id)
        }
        #endif
    }

    private func offeringButtonMenu(offeringID: String) -> some View {
        return Menu {
            contextMenuItems(offeringID: offeringID)
        } label: {
            Image(systemName: "ellipsis")
                .padding([.leading, .vertical])
        }
    }


    @ViewBuilder
    func contextMenuItems(offeringID: String) -> some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            self.showPaywallButton(for: mode, offeringID: offeringID)
        }
        if let appID = viewModel.singleApp?.id {
            Divider()
            ManagePaywallButton(kind: .edit, appID: appID, offeringID: offeringID)
        }
    }

    private func showPaywallButton(for selectedMode: PaywallViewMode, offeringID: String) -> some View {
        Button {
            Task { @MainActor in
                await viewModel.getAndShowPaywallForID(id: offeringID, mode: selectedMode)
                selectedItemID = offeringID
            }
        } label: {
            Text(selectedMode.name)
            Image(systemName: selectedMode.icon)
        }
    }
}

//#Preview {
//    OfferingButton()
//}
