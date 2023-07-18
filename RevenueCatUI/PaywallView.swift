import RevenueCat
import SwiftUI

/// A full-screen SwiftUI view for displaying a `PaywallData` for an `Offering`.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable, message: "RevenueCatUI does not support watchOS yet")
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(macCatalyst, unavailable, message: "RevenueCatUI does not support Catalyst yet")
public struct PaywallView: View {

    private let mode: PaywallViewMode
    private let offering: Offering
    private let paywall: PaywallData
    private let introEligibility: TrialOrIntroEligibilityChecker?
    private let purchaseHandler: PurchaseHandler?

    /// Create a view for the given offering and paywal.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    public init(mode: PaywallViewMode, offering: Offering, paywall: PaywallData) {
        self.init(
            mode: mode,
            offering: offering,
            paywall: paywall,
            introEligibility: Purchases.isConfigured ? .init() : nil,
            purchaseHandler: Purchases.isConfigured ? .init() : nil
        )
    }

    init(
        mode: PaywallViewMode = .fullScreen,
        offering: Offering,
        paywall: PaywallData,
        introEligibility: TrialOrIntroEligibilityChecker?,
        purchaseHandler: PurchaseHandler?
    ) {
        self.mode = mode
        self.offering = offering
        self.paywall = paywall
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        if let checker = self.introEligibility, let purchaseHandler = self.purchaseHandler {
            self.paywall
                .createView(for: self.offering, mode: self.mode)
                .environmentObject(checker)
                .environmentObject(purchaseHandler)
        } else {
            DebugErrorView("Purchases has not been configured.",
                           releaseBehavior: .fatalError)
        }
    }

}

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
struct PaywallView_Previews: PreviewProvider {

    static var previews: some View {
        let offering = TestData.offeringWithNoIntroOffer

        if let paywall = offering.paywall {
            PaywallView(
                mode: .fullScreen,
                offering: offering,
                paywall: paywall,
                introEligibility: TrialOrIntroEligibilityChecker
                    .producing(eligibility: .eligible)
                    .with(delay: .seconds(1)),
                purchaseHandler: .mock()
                    .with(delay: .seconds(1))
            )
        } else {
            Text("Preview not correctly setup, offering has no paywall!")
        }
    }

}

#endif
