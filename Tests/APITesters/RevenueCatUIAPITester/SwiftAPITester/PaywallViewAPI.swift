//
//  PaywallViewAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 7/14/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct App: View {

    private var offering: Offering
    private var fonts: PaywallFontProvider
    private var purchaseOrRestoreCompleted: PurchaseOrRestoreCompletedHandler = { (_: CustomerInfo) in }
    private var purchaseCompleted: PurchaseCompletedHandler = { (_: StoreTransaction?, _: CustomerInfo) in }
    private var paywallDismissed: () -> Void = {}

    var body: some View {
        self.content
    }

    // Note: `body` is implicitly `MainActor`, but this is not on purpose
    // to ensure that these constructors can be called outside of `@MainActor`.
    @ViewBuilder
    var content: some View {
        PaywallView()
        PaywallView(fonts: self.fonts)
        PaywallView(offering: self.offering)
        PaywallView(offering: self.offering, fonts: self.fonts)
    }

    @ViewBuilder
    var checkPresentPaywallIfNeeded: some View {
        Text("")
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "")
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", fonts: self.fonts)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    purchaseCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    restoreCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", fonts: self.fonts,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", fonts: self.fonts,
                                    restoreCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", fonts: self.fonts,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    restoreCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", fonts: self.fonts,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    restoreCompleted: self.purchaseOrRestoreCompleted,
                                    onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in false }
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            }
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } restoreCompleted: {
                self.purchaseOrRestoreCompleted($0)
            }
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } restoreCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } onDismiss: {
                self.paywallDismissed()
            }
    }

    @ViewBuilder
    var checkPaywallFooter: some View {
        Text("")
            .paywallFooter()
            .paywallFooter(fonts: self.fonts)
            .paywallFooter(purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(fonts: self.fonts, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true)
            .paywallFooter(condensed: true, fonts: self.fonts)
            .paywallFooter(condensed: true, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true, fonts: self.fonts, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true, fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)

            .paywallFooter(offering: offering)
            .paywallFooter(offering: offering, condensed: true)
            .paywallFooter(offering: offering, condensed: true, fonts: self.fonts)
            .paywallFooter(offering: offering, condensed: true, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering, condensed: true, restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering, condensed: true, fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering, condensed: true, fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering)
            .paywallFooter(offering: offering, fonts: self.fonts)
            .paywallFooter(offering: offering, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering, restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering, fonts: self.fonts, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering, fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
    }

    @ViewBuilder
    var checkOnPurchaseAndRestoreCompleted: some View {
        Text("")
            .onPurchaseCompleted(self.purchaseOrRestoreCompleted)
            .onPurchaseCompleted(self.purchaseCompleted)
            .onRestoreCompleted(self.purchaseOrRestoreCompleted)
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
