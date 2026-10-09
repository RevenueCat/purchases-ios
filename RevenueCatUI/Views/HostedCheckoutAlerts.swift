//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutAlerts.swift
//
//  Created by Antonio Pallares on 6/10/26.

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS) && canImport(WebKit)

@available(iOS 15.0, *)
extension View {

    /// Tells the customer how a hosted checkout settled, or why it did not open, as `purchaseHandler` asks.
    ///
    /// - Parameter isEnabled: Whether this view is the one telling the customer, for paywalls that share
    /// `purchaseHandler`.
    func hostedCheckoutAlerts(purchaseHandler: PurchaseHandler,
                              localizedBundle: Bundle,
                              isEnabled: Bool) -> some View {
        self.modifier(HostedCheckoutAlertsModifier(purchaseHandler: purchaseHandler,
                                                   localizedBundle: localizedBundle,
                                                   isEnabled: isEnabled))
    }

}

@available(iOS 15.0, *)
private struct HostedCheckoutAlertsModifier: ViewModifier {

    @ObservedObject
    var purchaseHandler: PurchaseHandler

    let localizedBundle: Bundle
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .alert(
                Text(verbatim: ""),
                isPresented: self.isPresented(self.error != nil),
                presenting: self.error
            ) { _ in
                self.okButton
            } message: { error in
                error.message(bundle: self.localizedBundle)
            }
            .alert(
                Text("You've already purchased this", bundle: self.localizedBundle),
                isPresented: self.isPresented(self.resolution == .tellCustomerTheyAlreadyOwnIt)
            ) {
                self.okButton
            }
            .alert(
                Text(verbatim: ""),
                isPresented: self.isPresented(self.purchaseCustomerInfo != nil),
                presenting: self.purchaseCustomerInfo
            ) { _ in
                self.okButton
            } message: { _ in
                Text("Your purchase was successful.", bundle: self.localizedBundle)
            }
    }

    private var resolution: HostedCheckout.Resolution? {
        return self.isEnabled ? self.purchaseHandler.hostedCheckoutResolutionToShow : nil
    }

    private var error: HostedCheckoutError? {
        guard case let .failed(error) = self.resolution else { return nil }
        return error
    }

    private var purchaseCustomerInfo: CustomerInfo? {
        guard case let .purchased(customerInfo) = self.resolution else { return nil }
        return customerInfo
    }

    private var okButton: some View {
        Button {
            self.purchaseHandler.acknowledgeHostedCheckoutResolution()
        } label: {
            Text("OK", bundle: self.localizedBundle)
        }
    }

    private func isPresented(_ isShowing: Bool) -> Binding<Bool> {
        let purchaseHandler = self.purchaseHandler
        return Binding {
            isShowing
        } set: { isPresented in
            if !isPresented {
                purchaseHandler.acknowledgeHostedCheckoutResolution()
            }
        }
    }

}

#endif
