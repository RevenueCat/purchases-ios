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


// TODO: Ask Barbara about how to present
struct OfferingsList: View {

    @State
    private var viewModel: OfferingsPaywallsViewModel

    @State
    private var selectedItemId: String?

    init(app: DeveloperResponse.App) {

        self._viewModel = State(initialValue: OfferingsPaywallsViewModel(apps: [app]))
    }

    var body: some View {
        self.content
            .task {
                await viewModel.updateOfferingsAndPaywalls()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.offeringsPaywalls {
        case let .success(data):
            VStack {
                if data.isEmpty {
                    Text(Self.pullToRefresh)
                        .font(.footnote)
                    ScrollView {
                        ContentUnavailableView("No paywalls configured", systemImage: "exclamationmark.triangle.fill")
                            .padding()
                        Text("Use the RevenueCat [web dashboard](https://app.revenuecat.com/) to configure a new paywall for one of this app's offerings.")
                            .font(.footnote)
                            .padding()
                    }
                    .refreshable {
                        Task { @MainActor in
                            await viewModel.updateOfferingsAndPaywalls()
                        }
                    }
                } else {
                    Text(Self.modesInstructions)
                        .font(.footnote)
                    self.list(with: data)
                }
            }

        case let .failure(error):
            Text(error.description)

        case .none:
            SwiftUI.ProgressView()
        }
    }

    @ViewBuilder
    private func list(with data: [OfferingPaywall]) -> some View {
        List {
            ForEach(data, id: \.self) { offeringPaywall in
                let responseOffering = offeringPaywall.offering
                let responsePaywall = offeringPaywall.paywall
                let rcOffering = responsePaywall.convertToRevenueCatPaywall(with: responseOffering)

                VStack(alignment: .leading) {
                    Button {
                        viewModel.presentedPaywall = .init(offering: rcOffering, mode: .default, responseOfferingID: responseOffering.id)
                        Task { @MainActor in
                            // The paywall data may have changed, reload
                            await viewModel.updateOfferingsAndPaywalls()
                            selectedItemId = offeringPaywall.offering.id
                        }
                    } label: {
                        let name = responsePaywall.data.templateName
                        let humanTemplateName = PaywallTemplate(rawValue: name)?.name ?? name
                        let decorator = data.count > 1 && self.selectedItemId == offeringPaywall.offering.id ? "▶ " : ""
                        HStack {
                            VStack(alignment:.leading) {
                                Text(decorator + responseOffering.displayName)
                                    .font(.headline)
                                Text("\(humanTemplateName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        #if !os(watchOS)
                        .contextMenu {
                            let rcOffering = responsePaywall.convertToRevenueCatPaywall(with: responseOffering)
                            self.contextMenu(for: rcOffering, responseOfferingID: offeringPaywall.offering.id)
                        }
                        #endif
                    }
                }
            }
        }
        .refreshable {
            Task { @MainActor in
                await viewModel.updateOfferingsAndPaywalls()
            }
        }
        .sheet(item: $viewModel.presentedPaywall) { paywall in
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode)
                .onRestoreCompleted { _ in
                    viewModel.presentedPaywall = nil
                }
                .id(viewModel.presentedPaywall?.hashValue) //FIXME: This should not be required, issue is in Paywallview
        }
    }

#if !os(watchOS)
    @ViewBuilder
    private func contextMenu(for offering: Offering, responseOfferingID: String) -> some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            self.button(for: mode, offering: offering, responseOfferingID: responseOfferingID)
        }
    }
#endif

    @ViewBuilder
    private func button(for selectedMode: PaywallViewMode, offering: Offering, responseOfferingID: String) -> some View {
        Button {
            viewModel.presentedPaywall = .init(offering: offering, mode: selectedMode, responseOfferingID: responseOfferingID)
            Task { @MainActor in
                await viewModel.updateOfferingsAndPaywalls()
                selectedItemId = responseOfferingID
            }
        } label: {
            Text(selectedMode.name)
            Image(systemName: selectedMode.icon)
        }
    }

#if targetEnvironment(macCatalyst)
    private static let pullToRefresh = ""
    private static let modesInstructions = "Right click or ⌘ + click to open in different modes."
#else
    private static let pullToRefresh = "Pull to refresh"
    private static let modesInstructions = "Press and hold to open in different modes."
#endif

}

extension PresentedPaywall: Identifiable {

    var id: String {
        return "\(self.offering.id)-\(self.mode.name)"
    }

}

#if DEBUG

// TODO: Mock DeveloperResponse to instantiate OfferingsList
struct OfferingsList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OfferingsList(app: MockData.developer().apps.first!)
        }
    }
}

#endif
