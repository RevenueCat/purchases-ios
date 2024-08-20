//
//  SamplePaywallsList.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/27/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct OfferingsList: View {

    @Binding 
    private var introEligility: IntroEligibilityStatus

    var body: some View {
        self.content
            .toolbar {
                #if !os(watchOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Options", selection: $introEligility) {
                            Text("Show Intro Offer").tag(IntroEligibilityStatus.eligible)
                            Text("No Intro Offer").tag(IntroEligibilityStatus.ineligible)
                         }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #endif
            }
            .task {
                await viewModel.updateOfferingsAndPaywalls()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    Task {
                        await viewModel.updateOfferingsAndPaywalls()
                    }
                }
            }
            .displayError($viewModel.error)
    }

    init(app: DeveloperResponse.App, introEligility: Binding<IntroEligibilityStatus>) {
        self._viewModel = StateObject(wrappedValue: OfferingsPaywallsViewModel(apps: [app]))
        self._introEligility = introEligility
    }

    @Environment(\.scenePhase) private var scenePhase

    @StateObject
    private var viewModel: OfferingsPaywallsViewModel

    @State
    private var selectedItemId: String?

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .notloaded:
            SwiftUI.ProgressView()
        case .success:
            if let listData = viewModel.listData {
                self.offeringsList(with:listData)
            } else {
                Text("No data available.")
            }
        case .error(let error):
            CompatibilityContentUnavailableView("Error loading paywalls", systemImage: "exclamationmark.triangle.fill", description: Text(error.localizedDescription))
        }
    }
    
    @ViewBuilder
    private func offeringsList(with data: PaywallsData) -> some View {
        List {
            Section {
                offeringsWithPaywallsListItems(with: data)
            } header: {
                Text("Offerings With Paywalls")
            }
            if let appID = viewModel.singleApp?.id, !data.offeringsWithoutPaywalls.isEmpty {
                Section{
                    offeringsWithoutPaywallsListItems(with: data, appID: appID)
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
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode, introEligility: introEligility)
                .onRestoreCompleted { _ in
                    viewModel.dismissPaywall()
                }
                .id(viewModel.presentedPaywall?.hashValue) //FIXME: This should not be required, issue is in Paywallview
        }
    }

    @ViewBuilder
    private func offeringsWithPaywallsListItems(with data: PaywallsData) -> some View {
        if !data.offeringsAndPaywalls.isEmpty {
            ForEach(data.offeringsAndPaywalls, id: \.self) { offeringWithPaywall in
                OfferingButton(offeringPaywall: offeringWithPaywall,
                               viewModel: viewModel,
                               selectedItemID: $selectedItemId)
            }
        } else {
            noPaywallsListItem()
        }
    }

    @ViewBuilder
    private func offeringsWithoutPaywallsListItems(with data: PaywallsData, appID: String) -> some View {
        ForEach(data.offeringsWithoutPaywalls, id: \.self) { offeringWithoutPaywall in
            ManagePaywallButton(kind: .new,
                                appID: appID,
                                offeringID: offeringWithoutPaywall.id,
                                buttonName: offeringWithoutPaywall.displayName)
        }
    }

    private func noPaywallsListItem() -> some View {
        VStack {
            CompatibilityContentUnavailableView("No configured paywalls",
                                                         systemImage: "exclamationmark.triangle.fill")
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
            OfferingsList(app: MockData.developer().apps.first!, introEligility: .constant(.eligible))
        }
    }
}

#endif
