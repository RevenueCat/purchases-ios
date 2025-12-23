//
//  PaywallPresenter.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import SwiftUI
import RevenueCat
#if DEBUG
@_spi(Internal) @testable import RevenueCatUI
#else
@_spi(Internal) import RevenueCatUI
#endif


struct PaywallPresenter: View {

    var offering: Offering
    var mode: PaywallTesterViewMode

    /// Ignored in release builds.
    var introEligility: IntroEligibilityStatus
    var displayCloseButton: Bool = Configuration.defaultDisplayCloseButton

    #if DEBUG
    var introEligibilityChecker: TrialOrIntroEligibilityChecker {
        .producing(eligibility: introEligility)
    }
    #endif


    var body: some View {
        switch self.mode {
        case .fullScreen, .sheet:
            PaywallView(offering: offering)
                .onPurchaseStarted({ package in
                    print("Paywall Handler - onPurchaseStarted")
                })
                .onPurchaseCompleted({ customerInfo in
                    print("Paywall Handler - onPurchaseCompleted")
                })
                .onPurchaseFailure({ error in
                    print("Paywall Handler - onPurchaseFailure")
                })
                .onPurchaseCancelled({
                    print("Paywall Handler - onPurchaseCancelled")
                })
                .onRestoreStarted({
                    print("Paywall Handler - onRestoreStarted")
                })
                .onRestoreCompleted({ customerInfo in
                    print("Paywall Handler - onRestoreCompleted")
                })
                .onRestoreFailure({ error in
                    print("Paywall Handler - onRestoreFailure")
                })

#if !os(watchOS)
#if !os(macOS)
#if DEBUG
        case .footer:
            CustomPaywallContent()
                .originalTemplatePaywallFooter(offering: self.offering,
                                               customerInfo: nil,
                                               introEligibility: introEligibilityChecker,
                                               purchaseHandler: .default())

        case .condensedFooter:
            CustomPaywallContent()
                .originalTemplatePaywallFooter(offering: self.offering,
                                               customerInfo: nil,
                                               condensed: true,
                                               introEligibility: introEligibilityChecker,
                                               purchaseHandler: .default())
#else
        case .footer:
            CustomPaywallContent()
                .originalTemplatePaywallFooter(offering: self.offering)

        case .condensedFooter:
            CustomPaywallContent()
                .originalTemplatePaywallFooter(offering: self.offering,
                                               condensed: true)
#endif
#endif
        case .presentIfNeeded:
            fatalError()

        case .presentPaywall:
            fatalError()

#endif
        }
    }

}
