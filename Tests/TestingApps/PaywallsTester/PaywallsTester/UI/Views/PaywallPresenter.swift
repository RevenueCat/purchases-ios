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
    var mode: PaywallViewMode
    var introEligility: IntroEligibilityStatus
    var displayCloseButton: Bool = Configuration.defaultDisplayCloseButton

    var body: some View {
        switch self.mode {
        case .fullScreen:
            let config = PaywallViewConfiguration(
                offering: offering,
                fonts: DefaultPaywallFontProvider(),
                displayCloseButton: displayCloseButton,
                introEligibility: .producing(eligibility: introEligility)
            )
            PaywallView(configuration: config) { storeProduct, purchaseResultReporter in
                print("purchase callback")
            } performRestore: { restoreResultReporter in
                print("restore callback")
            }


#if !os(watchOS)
        case .footer:
            CustomPaywallContent()
                .paywallFooter(offering: self.offering,
                               customerInfo: nil,
                               introEligibility: .producing(eligibility: introEligility))

        case .condensedFooter:
            CustomPaywallContent()
                .paywallFooter(offering: self.offering,
                               customerInfo: nil,
                               condensed: true,
                               introEligibility: .producing(eligibility: introEligility))
#endif
        }
    }

}
