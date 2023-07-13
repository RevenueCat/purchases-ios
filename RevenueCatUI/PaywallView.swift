import RevenueCat
import SwiftUI

// swiftlint:disable missing_docs

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
public struct PaywallView: View {

    private let offering: Offering
    private let paywall: PaywallData

    public init(offering: Offering, paywall: PaywallData) {
        self.offering = offering
        self.paywall = paywall
    }

    public var body: some View {
        self.paywall.createView(for: self.offering)
    }

}

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct PaywallView_Previews: PreviewProvider {

    static var previews: some View {
        PaywallView(offering: TestData.offering, paywall: TestData.paywall)
    }

}

#endif
