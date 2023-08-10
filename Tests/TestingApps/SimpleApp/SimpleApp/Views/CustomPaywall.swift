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
    var mode: PaywallViewMode
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler?

    var body: some View {
        NavigationView {
            self.content
                .overlay(alignment: .bottom) {
                    PaywallView(offering: self.offering,
                                mode: self.mode,
                                fonts: DefaultPaywallFontProvider(),
                                introEligibility: self.introEligibility ?? .default(),
                                purchaseHandler: self.purchaseHandler ?? .default()
                    )
                }
                .navigationTitle("Custom paywall")
        }
    }

    private var content: some View {
        VStack {
            BarChartView(data: (0..<10).map { _ in Double.random(in: 0..<100)})
                .frame(maxWidth: .infinity)
            BarChartView(data: (0..<10).map { _ in Double.random(in: 0..<100)})
                .frame(maxWidth: .infinity)
            BarChartView(data: (0..<10).map { _ in Double.random(in: 0..<100)})
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(white: 0.8)
                .edgesIgnoringSafeArea(.all)
        )
    }

}


#if DEBUG

struct CustomPaywall_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(Self.modes, id: \.self) { mode in
            CustomPaywall(
                offering: TestData.offeringWithMultiPackageHorizontalPaywall,
                mode: mode,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: .mock()
            )
            .previewDisplayName("\(mode)")
        }
    }

    private static let modes: [PaywallViewMode] = [
        .card,
        .condensedCard
    ]

}

#endif
