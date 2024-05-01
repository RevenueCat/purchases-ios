//
//  PaywallPresenter.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import SwiftUI
import RevenueCat
#if DEBUG
@testable import RevenueCatUI
#else
import RevenueCatUI
#endif

struct PaywallPresenter: View {

    var offering: Offering
    var mode: PaywallViewMode
    var introEligible: IntroEligibilityStatus
    var displayCloseButton: Bool = Configuration.defaultDisplayCloseButton

    var body: some View {
        switch self.mode {
        case .fullScreen:
            let config = PaywallViewConfiguration(
                offering: offering,
                fonts: DefaultPaywallFontProvider(),
                displayCloseButton: displayCloseButton,
                introEligibility: .producing(eligibility: introEligible)
            )
            PaywallView(configuration: config)

        #if !os(watchOS)
        case .footer:
            CustomPaywallContent()
                .paywallFooter(offering: self.offering)

        case .condensedFooter:
            CustomPaywallContent()
                .paywallFooter(offering: self.offering, condensed: true)
        #endif
        }
    }

}
