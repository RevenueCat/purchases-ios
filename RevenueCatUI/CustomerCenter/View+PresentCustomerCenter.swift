//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+PresentCustomerCenter.swift
//
//  Created by Toni Rico Diez on 2024-07-15.

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
@available(watchOS, unavailable, message: "CustomerCenterView does not support watchOS yet")
#if swift(>=5.9)
@available(visionOS, unavailable, message: "CustomerCenterView does not support visionOS yet")
#endif
extension View {

    /// Presents the ``CustomerCenter`` as a modal or sheet.
    ///
    /// This modifier allows you to display the Customer Center, which provides support and account-related actions.
    ///
    /// ## Example Usage:
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var isCustomerCenterPresented = false
    ///
    ///     var body: some View {
    ///         Button("Open Customer Center") {
    ///             isCustomerCenterPresented = true
    ///         }
    ///         .presentCustomerCenter(
    ///             isPresented: $isCustomerCenterPresented
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that determines whether the Customer Center is visible.
    ///   - customerCenterActionHandler: An optional handler for responding to events within the Customer Center.
    ///   - presentationMode: Specifies how the Customer Center should be presented (e.g., as a sheet or fullscreen).
    ///   Defaults to `.default`.
    ///   - onDismiss: A callback triggered when either the sheet / fullscreen present is dismissed
    ///     Ensure you set `isPresented = false` when this is called.
    ///
    /// - Returns: A view modified to support presenting the Customer Center.
    public func presentCustomerCenter(
        isPresented: Binding<Bool>,
        customerCenterActionHandler: CustomerCenterActionHandler? = nil,
        presentationMode: CustomerCenterPresentationMode = .default,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            PresentingCustomerCenterModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                myAppPurchaseLogic: nil,
                customerCenterActionHandler: customerCenterActionHandler,
                presentationMode: presentationMode
            )
        )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct PresentingCustomerCenterModifier: ViewModifier {

    let customerCenterActionHandler: CustomerCenterActionHandler?
    let presentationMode: CustomerCenterPresentationMode

    /// The closure to execute when dismissing the sheet / fullScreen present
    let onDismiss: (() -> Void)?

    init(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)?,
        myAppPurchaseLogic: MyAppPurchaseLogic?,
        customerCenterActionHandler: CustomerCenterActionHandler?,
        presentationMode: CustomerCenterPresentationMode,
        purchaseHandler: PurchaseHandler? = nil
    ) {
        self._isPresented = isPresented
        self.presentationMode = presentationMode
        self.onDismiss = onDismiss
        self.customerCenterActionHandler = customerCenterActionHandler
        self._purchaseHandler = .init(wrappedValue: purchaseHandler ??
                                      PurchaseHandler.default(performPurchase: myAppPurchaseLogic?.performPurchase,
                                                              performRestore: myAppPurchaseLogic?.performRestore))
    }

    @StateObject
    private var purchaseHandler: PurchaseHandler

    @Binding
    var isPresented: Bool

    func body(content: Content) -> some View {
        Group {
            switch presentationMode {
            case .sheet:
                content
                    .sheet(isPresented: self.$isPresented, onDismiss: onDismiss) {
                        self.customerCenterView()
                    }

            case .fullScreen:
                content
                    .fullScreenCover(isPresented: self.$isPresented, onDismiss: onDismiss) {
                        self.customerCenterView()
                    }

            @unknown default:
                content
            }
        }
    }

    private func customerCenterView() -> some View {
        CustomerCenterView(
            customerCenterActionHandler: self.customerCenterActionHandler
        )
            .interactiveDismissDisabled(self.purchaseHandler.actionInProgress)
    }

}

#endif
