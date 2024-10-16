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
        self.rcOffering = offeringPaywall.rcOffering
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
    
    @MainActor @ViewBuilder
    private func label() -> some View {
        let paywallTitle = rcOffering.paywall?.localizedConfiguration?.title ?? ""
        let decorator = viewModel.hasMultipleOfferingsWithPaywalls && self.selectedItemID == responseOffering.id ? "▶ " : ""
        HStack {
            VStack(alignment:.leading, spacing: 5) {
                HStack {
                    Text(decorator + responseOffering.displayName)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    if let templateName = rcOffering.paywall?.templateName {
                        paywallNamePill(name: templateName)
                    }
                }
                Text(paywallTitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            moreActionsMenu()
        }
    }

    private func paywallNamePill(name: String) -> some View {
        let tagText = {
            if let number = Int(name), let templateInfo = TemplateInfo.init(rawValue: number) {
                return "\(templateInfo.description)"
            } else {
                return "Template \(name)"
            }
        }()
        return Text(tagText)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
            )
            .foregroundColor(.accentColor)
            .font(.system(size: 10))
            .lineLimit(1)
    }

    @MainActor
    private func moreActionsMenu() -> some View {
        #if !os(watchOS)
        Menu {
            contextMenuItems()
        } label: {
            Image(systemName: "ellipsis")
                .padding([.leading, .vertical])
        }
        #else
        EmptyView()
        #endif
    }

    @MainActor @ViewBuilder
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
