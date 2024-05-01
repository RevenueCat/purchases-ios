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
            showPaywall()
        } label: {
            label()
        }
        #if !os(watchOS)
        .contextMenu {
            contextMenuItems()
        }
        #endif
    }

    init(offeringPaywall: OfferingPaywall,
         viewModel: OfferingsPaywallsViewModel,
         selectedItemID: Binding<String?>) {
        self.responseOffering = offeringPaywall.offering
        self.rcOffering = offeringPaywall.paywall.convertToRevenueCatPaywall(with: responseOffering)
        self.viewModel = viewModel
        self._selectedItemID = selectedItemID
    }

    private let responseOffering: OfferingsResponse.Offering
    private let rcOffering: Offering
    private let viewModel: OfferingsPaywallsViewModel
    @Binding private var selectedItemID: String?
}

private extension OfferingButton {
    private func showPaywall(mode: PaywallViewMode = .default) {
        Task { @MainActor in
            await viewModel.getAndShowPaywallForID(id: responseOffering.id, mode: mode)
            selectedItemID = responseOffering.id
        }
    }
}

private extension OfferingButton {

    @ViewBuilder
    private func label() -> some View {
        let templateName = rcOffering.paywall?.templateName
        let paywallTitle = rcOffering.paywall?.localizedConfiguration.title
        let decorator = viewModel.hasMultipleOfferingsWithPaywalls && self.selectedItemID == responseOffering.id ? "▶ " : ""
        HStack {
            VStack(alignment:.leading, spacing: 5) {
                Text(decorator + responseOffering.displayName)
                    .font(.headline)
                if let title = paywallTitle, let name = templateName {
                    let text = viewModel.hasMultipleTemplates ? "Style \(name): \(title)" : title
                    Text(text)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            moreActionsMenu()
        }
    }

    private func moreActionsMenu() -> some View {
        Menu {
            contextMenuItems()
        } label: {
            Image(systemName: "ellipsis")
                .padding([.leading, .vertical])
        }
    }

    @ViewBuilder
    private func contextMenuItems() -> some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            self.showPaywallMenuButton(for: mode)
        }
        if let appID = viewModel.singleApp?.id {
            Divider()
            ManagePaywallButton(kind: .edit, appID: appID, offeringID: responseOffering.id)
        }
    }
    
    private func showPaywallMenuButton(for selectedMode: PaywallViewMode) -> some View {
        Button {
            showPaywall(mode: selectedMode)
        } label: {
            Text(selectedMode.name)
            Image(systemName: selectedMode.icon)
        }
    }
}
