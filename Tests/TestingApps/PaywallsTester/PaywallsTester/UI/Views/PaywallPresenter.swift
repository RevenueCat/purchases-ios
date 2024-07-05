//
//  PaywallPresenter.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import SwiftUI
import RevenueCat
@testable import RevenueCatUI

enum PaywallPresnterError: Error, CustomStringConvertible {
    case cancelled

    var description: String {
        "An error occured yo yo YO"
    }
}

struct PaywallPresenter: View {

    var offering: Offering
    var mode: PaywallViewMode
    var introEligility: IntroEligibilityStatus
    var displayCloseButton: Bool = Configuration.defaultDisplayCloseButton

    var body: some View {
        switch self.mode {
        case .fullScreen:

            let handler = PurchaseHandler.default()

            let configuration = PaywallViewConfiguration(
                offering: offering,
                fonts: DefaultPaywallFontProvider(),
                displayCloseButton: displayCloseButton,
                introEligibility: .producing(eligibility: introEligility).with(delay: 30),
                purchaseHandler: handler
            )

            PaywallView(configuration: configuration)



#if !os(watchOS)
        case .footer:
            CustomPaywallContent()
                .paywallFooter(offering: self.offering)

        case .condensedFooter:
            CustomPaywallContent()
                .paywallFooter(offering: self.offering,
                               customerInfo: nil,
                               condensed: true,
                               introEligibility: .producing(eligibility: introEligility), 
                               purchaseHandler: PurchaseHandler.default())
#endif
        }
    }

}
