//
//  PaywallPresenter.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallPresenter: View {

    var offering: Offering
    var mode: PaywallTesterViewMode
    var introEligility: IntroEligibilityStatus
    var displayCloseButton: Bool = Configuration.defaultDisplayCloseButton

    var body: some View {
        switch self.mode {
        case .fullScreen, .sheet:

            let handler = PurchaseHandler.default()

            let configuration = PaywallViewConfiguration(
                offering: offering,
                fonts: DefaultPaywallFontProvider(),
                displayCloseButton: displayCloseButton,
                introEligibility: .producing(eligibility: introEligility),
                purchaseHandler: handler
            )

            PaywallView(configuration: configuration)

#if !os(watchOS)
        case .footer:
            CustomPaywallContent()
                .originalTemplatePaywallFooter(offering: self.offering,
                               customerInfo: nil,
                               introEligibility: .producing(eligibility: introEligility),
                               purchaseHandler: .default())

        case .condensedFooter:
            CustomPaywallContent()
                .originalTemplatePaywallFooter(offering: self.offering,
                               customerInfo: nil,
                               condensed: true,
                               introEligibility: .producing(eligibility: introEligility),
                                                            purchaseHandler: .default())
#endif
        }
    }

}
