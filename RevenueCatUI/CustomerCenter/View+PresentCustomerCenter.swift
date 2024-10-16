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

/// Warning: This is currently in beta and subject to change.
///
/// Presentation options to use with the [presentCustomerCenter](x-source-tag://presentCustomerCenter) View modifiers.
public enum CustomerCenterPresentationMode {

    /// Customer center presented using SwiftUI's `.sheet`.
    case sheet

    /// Customer center presented using SwiftUI's `.fullScreenCover`.
    case fullScreen

}

extension CustomerCenterPresentationMode {

    // swiftlint:disable:next missing_docs
    public static let `default`: Self = .sheet

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
@available(watchOS, unavailable, message: "CustomerCenterView does not support watchOS yet")
#if swift(>=5.9)
@available(visionOS, unavailable, message: "CustomerCenterView does not support visionOS yet")
#endif
extension View {

    /// Warning: This is currently in beta and subject to change.
    ///
    /// Presents the ``CustomerCenter``.
    /// Example:
    /// ```swift
    /// var body: some View {
    ///    YourApp()
    ///      .presentCustomerCenter()
    /// }
    /// ```
    /// - Parameter isPresented: Binding indicating whether the customer center should be displayed
    /// - Parameter onDismiss: Callback executed when the customer center wants to be dismissed.
    /// Make sure you stop presenting the customer center when this is called
    /// - Parameter customerCenterActionHandler: Allows to listen to certain events during the customer center flow.
    /// - Parameter presentationMode: The desired presentation mode of the customer center. Defaults to `.sheet`.
    public func presentCustomerCenter(
        isPresented: Binding<Bool>,
        customerCenterActionHandler: CustomerCenterActionHandler? = nil,
        presentationMode: CustomerCenterPresentationMode = .default,
        onDismiss: @escaping () -> Void
    ) -> some View {
        return self.modifier(PresentingCustomerCenterModifier(
            isPresented: isPresented,
            onDismiss: onDismiss,
            myAppPurchaseLogic: nil,
            customerCenterActionHandler: customerCenterActionHandler,
            presentationMode: presentationMode
        ))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct PresentingCustomerCenterModifier: ViewModifier {

    let customerCenterActionHandler: CustomerCenterActionHandler?
    let presentationMode: CustomerCenterPresentationMode
    let onDismiss: (() -> Void)

    init(
        isPresented: Binding<Bool>,
        onDismiss: @escaping () -> Void,
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
                    .sheet(isPresented: self.$isPresented, onDismiss: self.onDismiss) {
                        self.customerCenterView()
                    }
            case .fullScreen:
                content
                    .fullScreenCover(isPresented: self.$isPresented, onDismiss: self.onDismiss) {
                        self.customerCenterView()
                    }
            }
        }
    }

    private func customerCenterView() -> some View {
        CustomerCenterView(customerCenterActionHandler: self.customerCenterActionHandler)
            .interactiveDismissDisabled(self.purchaseHandler.actionInProgress)
    }

}

#endif
