//
//  PaywallForID.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import SwiftUI


struct PaywallForID: View {

    @State
    private var paywallsVM = OfferingsPaywallsViewModel()

    let id: String

    init(apps: [DeveloperResponse.App], id: String) {
        self.id = id
        paywallsVM.apps = apps
    }

    var body: some View {
        if let paywall = paywallsVM.presentedPaywall {
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode)
        } else {
            SwiftUI.ProgressView()
                .task {
                    await paywallsVM.updateOfferingsAndPaywalls()
                    await paywallsVM.showPaywallForID(id: id)
                }
        }

    }
}

#Preview {
    PaywallForID(apps: [], id: "n")
}
