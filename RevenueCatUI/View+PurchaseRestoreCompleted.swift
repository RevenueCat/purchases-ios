//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+PurchaseRestoreCompleted.swift
//  
//  Created by Nacho Soto on 7/31/23.

import RevenueCat
import SwiftUI

/// A closure used for notifying of purchase or restore completion.
public typealias PurchaseOrRestoreCompletedHandler = @MainActor @Sendable (CustomerInfo) -> Void

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
extension View {

    /// Invokes the given closure when a purchase is completed.
    /// The closure includes the `CustomerInfo` with unlocked entitlements.
    /// Example:
    /// ```swift
    ///  @State
    ///  private var displayPaywall: Bool = true
    ///
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayPaywall) {
    ///             PaywallView()
    ///                 .onPurchaseCompleted { customerInfo in
    ///                     print("Purchase completed: \(customerInfo.entitlements)")
    ///                     self.didPurchase = false
    ///                 }
    ///         }
    ///  }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func onPurchaseCompleted(
        _ handler: @escaping PurchaseOrRestoreCompletedHandler
    ) -> some View {
        return self.modifier(OnPurchaseCompletedModifier(handler: handler))
    }

    /// Invokes the given closure when restore purchases is completed.
    /// The closure includes the `CustomerInfo` after the process is completed.
    /// Example:
    /// ```swift
    ///  @State
    ///  private var displayPaywall: Bool = true
    ///
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayPaywall) {
    ///             PaywallView()
    ///                 .onRestoreCompleted { customerInfo in
    ///                     if !customerInfo.entitlements.active.isEmpty {
    ///                         self.displayPaywall = false
    ///                     }
    ///                 }
    ///         }
    ///  }
    /// ```
    ///
    /// - Warning: Receiving a ``CustomerInfo``does not imply that the user has any entitlements,
    /// simply that the process was successful. You must verify the ``CustomerInfo/entitlements``
    /// to confirm that they are active.
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func onRestoreCompleted(
        _ handler: @escaping PurchaseOrRestoreCompletedHandler
    ) -> some View {
        return self.modifier(OnRestoreCompletedModifier(handler: handler))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct OnPurchaseCompletedModifier: ViewModifier {

    let handler: PurchaseOrRestoreCompletedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(PurchasedCustomerInfoPreferenceKey.self) { customerInfo in
                if let customerInfo {
                    self.handler(customerInfo)
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct OnRestoreCompletedModifier: ViewModifier {

    let handler: PurchaseOrRestoreCompletedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(RestoredCustomerInfoPreferenceKey.self) { customerInfo in
                if let customerInfo {
                    self.handler(customerInfo)
                }
            }
    }

}
