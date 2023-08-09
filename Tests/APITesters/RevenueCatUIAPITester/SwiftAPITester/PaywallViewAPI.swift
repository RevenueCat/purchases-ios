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
    private var fonts: PaywallFontProvider
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
        PaywallView(fonts: self.fonts)
        PaywallView(mode: .fullScreen, fonts: self.fonts)
        PaywallView(offering: self.offering)
        PaywallView(offering: self.offering, mode: .fullScreen)
        PaywallView(offering: self.offering, fonts: self.fonts)
        PaywallView(offering: self.offering, mode: .fullScreen, fonts: self.fonts)
    }

    @ViewBuilder
    var checkPresentPaywallIfNeeded: some View {
        Text("")
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "")
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", fonts: self.fonts)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", purchaseCompleted: completed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", fonts: self.fonts, purchaseCompleted: completed)
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in false }
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseCompleted: {
                completed($0)
            }
    }

    @ViewBuilder
    var checkOnPurchaseCompleted: some View {
        Text("")
            .onPurchaseCompleted(self.completed)
    }

    private func fontProviders() {
        let _: PaywallFontProvider = DefaultPaywallFontProvider()
        let _: PaywallFontProvider = CustomPaywallFontProvider(fontName: "Papyrus")
    }

}

private struct CustomFontProvider: PaywallFontProvider {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    func font(for textStyle: Font.TextStyle) -> Font {
        return Font.body
    }

}
