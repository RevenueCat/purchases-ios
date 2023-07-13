import RevenueCat
import SwiftUI

/// A full-screen SwiftUI view for displaying a `PaywallData` for an `Offering`.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
public struct PaywallView: View {

    private let offering: Offering
    private let paywall: PaywallData
    private let introEligibility: TrialOrIntroEligibilityChecker?

    /// Create a view for the given offering and paywal.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    public init(offering: Offering, paywall: PaywallData) {
        self.init(
            offering: offering,
            paywall: paywall,
            introEligibility: Purchases.isConfigured ? .init() : nil
        )
    }

    init(offering: Offering, paywall: PaywallData, introEligibility: TrialOrIntroEligibilityChecker?) {
        self.offering = offering
        self.paywall = paywall
        self.introEligibility = introEligibility
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        if let checker = self.introEligibility {
            self.paywall
                .createView(for: self.offering)
                .environmentObject(checker)
        } else {
            DebugErrorView("Purchases has not been configured.",
                           releaseBehavior: .fatalError)
        }
    }

}

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct PaywallView_Previews: PreviewProvider {

    static var previews: some View {
        let offering = TestData.offeringWithNoIntroOffer

        if let paywall = offering.paywall {
            PaywallView(
                offering: offering,
                paywall: paywall,
                introEligibility: TrialOrIntroEligibilityChecker
                    .producing(eligibility: .eligible)
                    .with(delay: .seconds(1))
            )
        } else {
            Text("Preview not correctly setup, offering has no paywall!")
        }
    }

}

#endif
