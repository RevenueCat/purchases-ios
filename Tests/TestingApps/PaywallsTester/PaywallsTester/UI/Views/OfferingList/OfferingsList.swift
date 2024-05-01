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

    @Environment(\.scenePhase) private var scenePhase

    @State
    private var viewModel: OfferingsPaywallsViewModel

    @State
    private var selectedItemId: String?


    @ViewBuilder
    private var content: some View {
        switch viewModel.listData {
        case let .success(data):
            self.list(with: data)
        case let .failure(error):
            Text(error.description)
        case .none:
            SwiftUI.ProgressView()
        }
    }

    @ViewBuilder
    private func list(with data: PaywallsListData) -> some View {
        List {
            Section {
                if !data.offeringsAndPaywalls.isEmpty {
                    ForEach(data.offeringsAndPaywalls, id: \.self) { offeringPaywall in
                        OfferingButton(offeringPaywall: offeringPaywall,
                                       multipleOfferings: data.offeringsAndPaywalls.count > 1,
                                       viewModel: viewModel,
                                       selectedItemID: $selectedItemId)
                    }
                } else {
                    noPaywallsListItem()
                }
            } header: {
                Text("Offerings With Paywalls")
            }
            if let appID = viewModel.singleApp?.id, !data.offeringsWithoutPaywalls.isEmpty {
                Section{
                    ForEach(data.offeringsWithoutPaywalls, id: \.self) { offeringWithoutPaywall in
                        ManagePaywallButton(kind: .new, 
                                            appID: appID,
                                            offeringID: offeringWithoutPaywall.id,
                                            buttonName: offeringWithoutPaywall.displayName)
                    }
                } header: {
                    Text("Offerings Without Paywalls")
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
                    viewModel.dismissPaywall()
                }
                .id(viewModel.presentedPaywall?.hashValue) //FIXME: This should not be required, issue is in Paywallview
        }
    }

    private func noPaywallsListItem() -> some View {
        VStack {
            ContentUnavailableView("No configured paywalls", systemImage: "exclamationmark.triangle.fill")
            Text(Self.pullToRefresh)
                .font(.footnote)
            Text("Use the RevenueCat [web dashboard](https://app.revenuecat.com/) to configure a new paywall for one of this app's offerings.")
                .font(.footnote)
                .padding()
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
