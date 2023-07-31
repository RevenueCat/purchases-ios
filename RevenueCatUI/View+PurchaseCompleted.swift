//
//  View+PurchaseCompleted.swift
//  
//
//  Created by Nacho Soto on 7/31/23.
//

import RevenueCat
import SwiftUI

/// A closure used for notifying of purchase completion.
public typealias PurchaseCompletedHandler = @MainActor @Sendable (CustomerInfo) -> Void

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
extension View {

    /// Invokes the given closure when a purchase is completed.
    /// The closure includes the `CustomerInfo` with unlocked entitlements.
    /// Example:
    /// ```swift
    ///  @State
    ///  private var didPurchase: Bool
    ///
    ///  var body: some View {
    ///     VStack {
    ///         YourViews()
    ///
    ///         if !self.didPurchase {
    ///             PaywallView()
    ///         }
    ///     }
    ///     .onPurchaseCompleted { customerInfo in
    ///         print("Purchase completed: \(customerInfo.entitlements)")
    ///         self.didPurchase = true
    ///     }
    ///  }
    /// ```
    public func onPurchaseCompleted(
        _ handler: @escaping PurchaseCompletedHandler
    ) -> some View {
        return self.modifier(OnPurchaseCompletedModifier(handler: handler))
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct OnPurchaseCompletedModifier: ViewModifier {

    let handler: PurchaseCompletedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(PurchasedCustomerInfoPreferenceKey.self) { customerInfo in
                if let customerInfo {
                    self.handler(customerInfo)
                }
            }
    }

}
