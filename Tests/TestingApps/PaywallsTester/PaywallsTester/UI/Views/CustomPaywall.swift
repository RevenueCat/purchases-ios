//
//  CustomPaywall.swift
//  PaywallsPreview
//
//  Created by Nacho Soto on 8/9/23.
//


#if DEBUG && !os(watchOS)

import RevenueCat


// this @testable access should used for the SwiftUI previews only
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI

struct CustomPaywall: View {

    var offering: Offering?
    var customerInfo: CustomerInfo?
    var condensed: Bool
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler?

    @State
    private var currentTierName: String?

    var body: some View {
        self.content
    }

    private var content: some View {
        CustomPaywallContent(selectedTierName: self.currentTierName)
            .originalTemplatePaywallFooter(
                offering: self.offering,
                customerInfo: self.customerInfo,
                condensed: self.condensed,
                fonts: DefaultPaywallFontProvider(),
                introEligibility: self.introEligibility ?? .default(),
                purchaseHandler: self.purchaseHandler ?? .default()
            )
            .onPaywallTierChange { _, name in
                self.currentTierName = name
            }
    }

}

struct CustomPaywall_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(Self.condensedOptions, id: \.self) { mode in
            CustomPaywall(
                offering: TestData.offeringWithMultiPackagePaywall,
                customerInfo: TestData.customerInfo,
                condensed: mode,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: .mock()
            )
            .previewDisplayName("Template2\(mode ? " condensed" : "")")
        }

        ForEach(Self.condensedOptions, id: \.self) { mode in
            CustomPaywall(
                offering: TestData.offeringWithMultiPackageHorizontalPaywall,
                customerInfo: TestData.customerInfo,
                condensed: mode,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: .mock()
            )
            .previewDisplayName("Template4\(mode ? " condensed" : "")")
        }

        ForEach(Self.condensedOptions, id: \.self) { mode in
            CustomPaywall(
                offering: TestData.offeringWithTemplate5Paywall,
                customerInfo: TestData.customerInfo,
                condensed: mode,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: .mock()
            )
            .previewDisplayName("Template5\(mode ? " condensed" : "")")
        }
    }

    private static let condensedOptions: [Bool] = [
        true,
        false
    ]

}

#endif
