//
//  PaywallForID.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import SwiftUI


struct PaywallForID: View {

    @State
    private var viewModel: OfferingsPaywallsViewModel

    let id: String

    init(apps: [DeveloperResponse.App], id: String) {
        self.id = id
        self._viewModel = State(initialValue: OfferingsPaywallsViewModel(apps: apps))
    }

    var body: some View {
        if let paywall = viewModel.presentedPaywall {
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode)
                .id(viewModel.presentedPaywall?.hashValue) //FIXME: This should not be required, issue is in Paywallview
        } else {
            SwiftUI.ProgressView()
                .task {
                    await viewModel.showPaywallForID(id: id)
                }
        }

    }
}

#Preview {
    PaywallForID(apps: [], id: "n")
}
