//
//  PaywallForID.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import SwiftUI
import RevenueCat

struct PaywallForID: View {

    @StateObject
    private var viewModel: OfferingsPaywallsViewModel
    private let id: String
    private let introEligible: IntroEligibilityStatus

    init(apps: [DeveloperResponse.App], id: String, introEligible: IntroEligibilityStatus = .unknown) {
        self.id = id
        self.introEligible = introEligible
        self._viewModel = StateObject(wrappedValue: OfferingsPaywallsViewModel(apps: apps))
    }

    var body: some View {
        if let paywall = viewModel.presentedPaywall {
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode, introEligility: introEligible)
                .id(viewModel.presentedPaywall?.hashValue) //FIXME: This should not be required, issue is in PaywallView
        } else {
            SwiftUI.ProgressView()
                .task {
                    await viewModel.getAndShowPaywallForID(id: id)
                }
        }
    }

}

#Preview {
    PaywallForID(apps: [], id: "n", introEligible: IntroEligibilityStatus.ineligible)
}
