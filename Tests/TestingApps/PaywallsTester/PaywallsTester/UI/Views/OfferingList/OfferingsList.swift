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

    @Environment(\.scenePhase) var scenePhase

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
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    Task {
                        await viewModel.updateOfferingsAndPaywalls()
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.listData {
        case let .success(data):
            VStack {
                if data.offeringsAndPaywalls.isEmpty {
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
    private func list(with data: PaywallsListData) -> some View {
        List {
            Section(header: Text("Configured Paywalls")) {
                let hasMultipleTemplates = Set(data.offeringsAndPaywalls.map { $0.paywall.data.templateName }).count > 1
                ForEach(data.offeringsAndPaywalls, id: \.self) { offeringPaywall in
                    let responseOffering = offeringPaywall.offering
                    let responsePaywall = offeringPaywall.paywall
                    let rcOffering = responsePaywall.convertToRevenueCatPaywall(with: responseOffering)

                    VStack(alignment: .leading) {
                        Button {
                            Task {
                                await viewModel.getAndShowPaywallForID(id: responseOffering.id)
                                selectedItemId = offeringPaywall.offering.id
                            }
                        } label: {
                            let templateName = rcOffering.paywall?.templateName
                            let paywallTitle = rcOffering.paywall?.localizedConfiguration.title

                            let decorator = data.offeringsAndPaywalls.count > 1 && self.selectedItemId == offeringPaywall.offering.id ? "▶ " : ""
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
                                Menu {
                                    ForEach(PaywallViewMode.allCases, id: \.self) { mode in
                                        self.button(for: mode, offering: rcOffering, responseOfferingID: responseOffering.id)
                                    }
                                    if let appID = viewModel.singleApp?.id {
                                        Divider()
                                        ManagePaywallButton(kind: .edit, appID: appID, offeringID: responseOffering.id)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .padding([.leading, .vertical])
                                }
                                .padding(.all, 0)
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
            if let appID = viewModel.singleApp?.id, !data.offeringsWithoutPaywalls.isEmpty {
                Section(header: Text("Offerings Without Paywalls")) {
                    ForEach(data.offeringsWithoutPaywalls, id: \.self) { offeringWithoutPaywall in
                        ManagePaywallButton(kind: .new, 
                                            appID: appID,
                                            offeringID: offeringWithoutPaywall.id,
                                            buttonName: offeringWithoutPaywall.displayName)
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
#else
    private static let pullToRefresh = "Pull to refresh"
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
