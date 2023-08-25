//
//  CustomPaywall.swift
//  SimpleApp
//
//  Created by Nacho Soto on 8/9/23.
//

import RevenueCat
@testable import RevenueCatUI
import SwiftUI

struct CustomPaywall: View {

    var offering: Offering?
    var customerInfo: CustomerInfo?
    var condensed: Bool
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler?

    var body: some View {
        self.content
    }

    private var content: some View {
        CustomPaywallContent()
            .scrollableIfNecessary(.vertical)
            .background(CustomPaywallContent.backgroundColor)
            .paywallFooter(offering: self.offering,
                           customerInfo: self.customerInfo,
                           condensed: self.condensed,
                           fonts: DefaultPaywallFontProvider(),
                           introEligibility: self.introEligibility ?? .default(),
                           purchaseHandler: self.purchaseHandler ?? .default()
            )
    }

}


#if DEBUG

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
    }

    private static let condensedOptions: [Bool] = [
        true,
        false
    ]

}

#endif
