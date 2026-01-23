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
@available(macOS, unavailable, message: "CustomerCenterView does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
@available(watchOS, unavailable, message: "CustomerCenterView does not support watchOS yet")
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
    @available(*, deprecated, message: "Use the version with individual action handlers instead")
    public func presentCustomerCenter(
        isPresented: Binding<Bool>,
        customerCenterActionHandler: CustomerCenterActionHandler?,
        presentationMode: CustomerCenterPresentationMode = .default,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        // Convert the legacy handler to individual handlers if one is provided
        var restoreStartedHandler: CustomerCenterView.RestoreStartedHandler?
        var restoreCompletedHandler: CustomerCenterView.RestoreCompletedHandler?
        var restoreFailedHandler: CustomerCenterView.RestoreFailedHandler?
        var showingManageSubscriptionsHandler: CustomerCenterView.ShowingManageSubscriptionsHandler?
        var refundRequestStartedHandler: CustomerCenterView.RefundRequestStartedHandler?
        var refundRequestCompletedHandler: CustomerCenterView.RefundRequestCompletedHandler?
        var feedbackSurveyCompletedHandler: CustomerCenterView.FeedbackSurveyCompletedHandler?

        if let handler = customerCenterActionHandler {
            restoreStartedHandler = { handler(.restoreStarted) }
            restoreCompletedHandler = { handler(.restoreCompleted($0)) }
            restoreFailedHandler = { handler(.restoreFailed($0)) }
            showingManageSubscriptionsHandler = { handler(.showingManageSubscriptions) }
            refundRequestStartedHandler = { handler(.refundRequestStarted($0)) }
            refundRequestCompletedHandler = { handler(.refundRequestCompleted($1)) }
            feedbackSurveyCompletedHandler = { handler(.feedbackSurveyCompleted($0)) }
        }

        return self.modifier(
            PresentingCustomerCenterModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                myAppPurchaseLogic: nil,
                presentationMode: presentationMode,
                restoreStarted: restoreStartedHandler,
                restoreCompleted: restoreCompletedHandler,
                restoreFailed: restoreFailedHandler,
                showingManageSubscriptions: showingManageSubscriptionsHandler,
                refundRequestStarted: refundRequestStartedHandler,
                refundRequestCompleted: refundRequestCompletedHandler,
                feedbackSurveyCompleted: feedbackSurveyCompletedHandler
            )
        )
    }

    /// Presents the ``CustomerCenter`` as a modal or sheet with individual action handlers.
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
    ///             isPresented: $isCustomerCenterPresented,
    ///             restoreStarted: {
    ///                 print("Restore started")
    ///             },
    ///             restoreCompleted: { customerInfo in
    ///                 print("Restore completed with customer info: \(customerInfo)")
    ///             }
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that determines whether the Customer Center is visible.
    ///   - presentationMode: Specifies how the Customer Center should be presented (e.g., as a sheet or fullscreen).
    ///   - myAppPurchaseLogic: Optional custom purchase logic for "my app" purchases.
    ///   - restoreStarted: Handler called when a restore operation starts.
    ///   - restoreCompleted: Handler called when a restore operation completes successfully.
    ///   - restoreFailed: Handler called when a restore operation fails.
    ///   - showingManageSubscriptions: Handler called when the user navigates to manage subscriptions.
    ///   - refundRequestStarted: Handler called when a refund request starts.
    ///   - refundRequestCompleted: Handler called when a refund request completes.
    ///   - feedbackSurveyCompleted: Handler called when a feedback survey is completed.
    ///   - onDismiss: A callback triggered when either the sheet / fullscreen present is dismissed.
    ///
    /// - Returns: A view modified to support presenting the Customer Center.
    public func presentCustomerCenter(
        isPresented: Binding<Bool>,
        presentationMode: CustomerCenterPresentationMode = .default,
        restoreStarted: CustomerCenterView.RestoreStartedHandler? = nil,
        restoreCompleted: CustomerCenterView.RestoreCompletedHandler? = nil,
        restoreFailed: CustomerCenterView.RestoreFailedHandler? = nil,
        showingManageSubscriptions: CustomerCenterView.ShowingManageSubscriptionsHandler? = nil,
        refundRequestStarted: CustomerCenterView.RefundRequestStartedHandler? = nil,
        refundRequestCompleted: CustomerCenterView.RefundRequestCompletedHandler? = nil,
        feedbackSurveyCompleted: CustomerCenterView.FeedbackSurveyCompletedHandler? = nil,
        managementOptionSelected: CustomerCenterView.ManagementOptionSelectedHandler? = nil,
        onCustomAction: CustomerCenterView.CustomActionHandler? = nil,
        changePlansSelected: CustomerCenterView.ChangePlansHandler? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            PresentingCustomerCenterModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                myAppPurchaseLogic: nil,
                presentationMode: presentationMode,
                restoreStarted: restoreStarted,
                restoreCompleted: restoreCompleted,
                restoreFailed: restoreFailed,
                showingManageSubscriptions: showingManageSubscriptions,
                refundRequestStarted: refundRequestStarted,
                refundRequestCompleted: refundRequestCompleted,
                feedbackSurveyCompleted: feedbackSurveyCompleted,
                managementOptionSelected: managementOptionSelected,
                onCustomAction: onCustomAction,
                changePlansSelected: changePlansSelected
            )
        )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct PresentingCustomerCenterModifier: ViewModifier {

    let presentationMode: CustomerCenterPresentationMode
    let restoreStarted: CustomerCenterView.RestoreStartedHandler?
    let restoreCompleted: CustomerCenterView.RestoreCompletedHandler?
    let restoreFailed: CustomerCenterView.RestoreFailedHandler?
    let showingManageSubscriptions: CustomerCenterView.ShowingManageSubscriptionsHandler?
    let refundRequestStarted: CustomerCenterView.RefundRequestStartedHandler?
    let refundRequestCompleted: CustomerCenterView.RefundRequestCompletedHandler?
    let feedbackSurveyCompleted: CustomerCenterView.FeedbackSurveyCompletedHandler?
    let managementOptionSelected: CustomerCenterView.ManagementOptionSelectedHandler?
    let onCustomAction: CustomerCenterView.CustomActionHandler?
    let changePlansSelected: CustomerCenterView.ChangePlansHandler?

    /// The closure to execute when dismissing the sheet / fullScreen present
    let onDismiss: (() -> Void)?

    init(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)?,
        myAppPurchaseLogic: MyAppPurchaseLogic?,
        presentationMode: CustomerCenterPresentationMode,
        restoreStarted: CustomerCenterView.RestoreStartedHandler? = nil,
        restoreCompleted: CustomerCenterView.RestoreCompletedHandler? = nil,
        restoreFailed: CustomerCenterView.RestoreFailedHandler? = nil,
        showingManageSubscriptions: CustomerCenterView.ShowingManageSubscriptionsHandler? = nil,
        refundRequestStarted: CustomerCenterView.RefundRequestStartedHandler? = nil,
        refundRequestCompleted: CustomerCenterView.RefundRequestCompletedHandler? = nil,
        feedbackSurveyCompleted: CustomerCenterView.FeedbackSurveyCompletedHandler? = nil,
        managementOptionSelected: CustomerCenterView.ManagementOptionSelectedHandler? = nil,
        onCustomAction: CustomerCenterView.CustomActionHandler? = nil,
        changePlansSelected: CustomerCenterView.ChangePlansHandler? = nil,
        purchaseHandler: PurchaseHandler? = nil
    ) {
        self._isPresented = isPresented
        self.presentationMode = presentationMode
        self.onDismiss = onDismiss
        self.restoreStarted = restoreStarted
        self.restoreCompleted = restoreCompleted
        self.restoreFailed = restoreFailed
        self.showingManageSubscriptions = showingManageSubscriptions
        self.refundRequestStarted = refundRequestStarted
        self.refundRequestCompleted = refundRequestCompleted
        self.feedbackSurveyCompleted = feedbackSurveyCompleted
        self.managementOptionSelected = managementOptionSelected
        self.onCustomAction = onCustomAction
        self.changePlansSelected = changePlansSelected
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
        // Build the view and attach environment-based handlers
        return CustomerCenterView()
            .onCustomerCenterRestoreStarted { [restoreStarted] in
                restoreStarted?()
            }
            .onCustomerCenterRestoreCompleted { [restoreCompleted] customerInfo in
                restoreCompleted?(customerInfo)
            }
            .onCustomerCenterRestoreFailed { [restoreFailed] error in
                restoreFailed?(error)
            }
            .onCustomerCenterShowingManageSubscriptions { [showingManageSubscriptions] in
                showingManageSubscriptions?()
            }
            .onCustomerCenterRefundRequestStarted { [refundRequestStarted] productId in
                refundRequestStarted?(productId)
            }
            .onCustomerCenterRefundRequestCompleted { [refundRequestCompleted] productId, status in
                refundRequestCompleted?(productId, status)
            }
            .onCustomerCenterFeedbackSurveyCompleted { [feedbackSurveyCompleted] optionId in
                feedbackSurveyCompleted?(optionId)
            }
            .onCustomerCenterManagementOptionSelected { action in
                managementOptionSelected?(action)
            }
            .onCustomerCenterCustomActionSelected { actionIdentifier, purchaseIdentifier in
                onCustomAction?(actionIdentifier, purchaseIdentifier)
            }
            .onCustomerCenterChangePlansSelected { optionId in
                changePlansSelected?(optionId)
            }
            .interactiveDismissDisabled(self.purchaseHandler.actionInProgress)
    }
}

#endif
