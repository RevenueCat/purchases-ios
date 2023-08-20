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
                .navigationTitle("Custom paywall")
        }
    }

    private var content: some View {
        VStack {
            VStack {
                ForEach(Self.colors, id: \.self) { color in
                    BarChartView(
                        data: (0..<10).map { _ in Double.random(in: 0..<100)},
                        color: color
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .scrollableIfNecessary(.vertical)

            Spacer()

            PaywallView(offering: self.offering,
                        mode: self.mode,
                        fonts: DefaultPaywallFontProvider(),
                        introEligibility: self.introEligibility ?? .default(),
                        purchaseHandler: self.purchaseHandler ?? .default()
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(white: 0.8)
                .edgesIgnoringSafeArea(.all)
        )
    }

    private static let colors: [Color] = [
        .red,
        .green,
        .blue,
        .indigo,
        .mint,
        .teal
    ].shuffled()

}


#if DEBUG

struct CustomPaywall_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(Self.modes, id: \.self) { mode in
            CustomPaywall(
                offering: TestData.offeringWithMultiPackagePaywall,
                mode: mode,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: .mock()
            )
            .previewDisplayName("\(mode)")
        }

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
        .overlay,
        .condensedOverlay
    ]

}

#endif
