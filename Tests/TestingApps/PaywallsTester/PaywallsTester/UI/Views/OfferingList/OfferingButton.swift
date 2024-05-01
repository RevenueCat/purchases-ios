//
//  OfferingButton.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-30.
//

import SwiftUI
import RevenueCat

struct OfferingButton: View {

    var body: some View {
        Button {
            Task {
                await viewModel.getAndShowPaywallForID(id: responseOffering.id)
                selectedItemID = responseOffering.id
            }
        } label: {
            offeringButtonLabel()
        }
        #if !os(watchOS)
        .contextMenu {
            contextMenuItems(offeringID: responseOffering.id)
        }
        #endif
    }

    init(offeringPaywall: OfferingPaywall,
         multipleOfferings: Bool,
         hasMultipleTemplates: Bool,
         viewModel: OfferingsPaywallsViewModel,
         selectedItemID: Binding<String?>) {
        self.responseOffering = offeringPaywall.offering
        self.rcOffering = offeringPaywall.paywall.convertToRevenueCatPaywall(with: responseOffering)
        self.multipleOfferings = multipleOfferings
        self.hasMultipleTemplates = hasMultipleTemplates
        self.viewModel = viewModel
        self._selectedItemID = selectedItemID
    }

    private let responseOffering: OfferingsResponse.Offering
    private let rcOffering: Offering
    private let multipleOfferings: Bool
    private let hasMultipleTemplates: Bool
    private let viewModel: OfferingsPaywallsViewModel
    @Binding private var selectedItemID: String?
}


private extension OfferingButton {
    private func offeringButtonLabel() -> some View {
        let templateName = rcOffering.paywall?.templateName
        let paywallTitle = rcOffering.paywall?.localizedConfiguration.title
        let decorator = multipleOfferings && self.selectedItemID == responseOffering.id ? "▶ " : ""
        return HStack {
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
        }
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
    private func contextMenuItems(offeringID: String) -> some View {
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
