//
//  PaywallViewAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 7/14/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct App: View {

    private var offering: Offering
    private var completed: PurchaseCompletedHandler = { (_: CustomerInfo) in }

    var body: some View {
        self.content
    }

    // Note: `body` is implicitly `MainActor`, but this is not on purpose
    // to ensure that these constructors can be called outside of `@MainActor`.
    @ViewBuilder
    var content: some View {
        PaywallView()
        PaywallView(mode: .fullScreen)
        PaywallView(offering: self.offering)
        PaywallView(offering: self.offering, mode: .fullScreen)
    }

    @ViewBuilder
    var checkPresentPaywallIfNeeded: some View {
        Text("")
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "")
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", purchaseCompleted: completed)
            .presentPaywallIfNeeded { (_: CustomerInfo) in false }
            .presentPaywallIfNeeded { (_: CustomerInfo) in false } purchaseCompleted: { completed($0) }
    }

    @ViewBuilder
    var checkOnPurchaseCompleted: some View {
        Text("")
            .onPurchaseCompleted(self.completed)
    }

    private func modes(_ mode: PaywallViewMode) {
        switch mode {
        case .fullScreen:
            break
        case .card:
            break
        case .banner:
            break
        }
    }

}
