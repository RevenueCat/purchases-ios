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


    /// When `SCREENSHOT_MODE=1` is set in the process environment (injected by
    /// `PaywallAccessibilityTreeTests`), web-checkout URL opens are suppressed so the
    /// paywall stays on screen long enough for a screenshot to be captured.
    private var isScreenshotMode: Bool {
        ProcessInfo.processInfo.environment["SCREENSHOT_MODE"] == "1"
    }

    /// In screenshot mode, forces intro-offer ineligibility so the paywall renders regular
    /// pricing (matching the web extractor baseline). Falls back to the SPI default outside
    /// screenshot mode.  Only available in DEBUG because `.producing(eligibility:)` is a
    /// `@testable` test helper.
    #if DEBUG
    private var screenshotEligibilityChecker: TrialOrIntroEligibilityChecker? {
        isScreenshotMode ? .producing(eligibility: .ineligible) : nil
    }
    #endif

    var body: some View {
        switch self.mode {
        case .fullScreen, .sheet:
            #if DEBUG
            PaywallView(
                offering: offering,
                useDraftPaywall: false,
                introEligibility: screenshotEligibilityChecker
            )
            #else
            PaywallView(offering: offering)
            #endif
                .applyIf(isScreenshotMode) { view in
                    view.environment(\.openURL, OpenURLAction { _ in .discarded })
                }
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
#endif

        case .presentIfNeeded:
            fatalError()

        case .presentPaywall:
            fatalError()

        case .workflow:
            PaywallView(configuration: .init(
                content: .offeringIdentifier(offering.identifier, presentedOfferingContext: nil),
                purchaseHandler: .default()
            ))

        }
    }

}
