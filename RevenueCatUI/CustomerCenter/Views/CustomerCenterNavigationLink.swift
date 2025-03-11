//
//  CustomerCenterNavigationLink.swift
//  RevenueCat
//
//  Created by Facundo Menzella on 14/1/25.
//

import RevenueCat
import SwiftUI

#if os(iOS)

/// A view that provides a navigation link to ``CustomerCenterView`` with a customizable label.
///
/// This is the **preferred way** to integrate ``CustomerCenterView`` into your `NavigationView`,
/// ensuring proper navigation behavior by pre-setting navigation options.
///
/// ## Example Usage
/// ```swift
/// CustomerCenterNavigationLink {
///     HStack {
///         Image(systemName: "person.circle")
///         Text("Customer Center")
///     }
/// }
///
/// CustomerCenterNavigationLink(Text("Customer Center"))
/// ```
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CustomerCenterNavigationLink<Label: View>: View {

    @ViewBuilder private let label: () -> Label

    // Stored handlers for later updating if needed
    private var restoreStartedHandler: CustomerCenterView.RestoreStartedHandler?
    private var restoreCompletedHandler: CustomerCenterView.RestoreCompletedHandler?
    private var restoreFailedHandler: CustomerCenterView.RestoreFailedHandler?
    private var showingManageSubscriptionsHandler: CustomerCenterView.ShowingManageSubscriptionsHandler?
    private var refundRequestStartedHandler: CustomerCenterView.RefundRequestStartedHandler?
    private var refundRequestCompletedHandler: CustomerCenterView.RefundRequestCompletedHandler?
    private var feedbackSurveyCompletedHandler: CustomerCenterView.FeedbackSurveyCompletedHandler?

    /// Initializes the navigation link with a label view provided by a closure.
    ///
    /// Use this initializer when the label requires dynamic content or complex logic.
    ///
    /// Example:
    /// ```swift
    /// CustomerCenterNavigationLink {
    ///     HStack {
    ///         Image(systemName: "person.circle")
    ///         Text("Customer Center")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter label: A closure that returns the view to display as the navigation link's label.
    @available(*, deprecated, message: """
    Use the view modifiers instead.
    For example, use .onCustomerCenterRestoreStarted(), .onCustomerCenterRestoreCompleted(), etc.
    """)
    public init(
        customerCenterActionHandler: CustomerCenterActionHandler?,
        @ViewBuilder label: @escaping () -> Label) {
            self.label = label

            // Map the legacy handler to individual handlers
            if let handler = customerCenterActionHandler {
                self.restoreStartedHandler = { handler(.restoreStarted) }
                self.restoreCompletedHandler = { handler(.restoreCompleted($0)) }
                self.restoreFailedHandler = { handler(.restoreFailed($0)) }
                self.showingManageSubscriptionsHandler = { handler(.showingManageSubscriptions) }
                self.refundRequestStartedHandler = { handler(.refundRequestStarted($0)) }
                self.refundRequestCompletedHandler = { handler(.refundRequestCompleted($1)) }
                self.feedbackSurveyCompletedHandler = { handler(.feedbackSurveyCompleted($0)) }
            }
        }

    /// Initializes the navigation link with a label view provided by a closure.
    ///
    /// Use this initializer when the label requires dynamic content or complex logic.
    ///
    /// Example:
    /// ```swift
    /// CustomerCenterNavigationLink {
    ///     HStack {
    ///         Image(systemName: "person.circle")
    ///         Text("Customer Center")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter label: A closure that returns the view to display as the navigation link's label.
    public init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label
    }

    /// The content and behavior of the navigation link.
    public var body: some View {
        NavigationLink {
            CustomerCenterView(
                navigationOptions: CustomerCenterNavigationOptions(
                    usesNavigationStack: false,
                    usesExistingNavigation: true,
                    shouldShowCloseButton: false
                ))
                .applyIfLet(self.restoreStartedHandler) { view, handler in
                    view.onCustomerCenterRestoreStarted(handler)
                }
                .applyIfLet(self.restoreCompletedHandler) { view, handler in
                    view.onCustomerCenterRestoreCompleted(handler)
                }
                .applyIfLet(self.restoreFailedHandler) { view, handler in
                    view.onCustomerCenterRestoreFailed(handler)
                }
                .applyIfLet(self.showingManageSubscriptionsHandler) { view, handler in
                    view.onCustomerCenterShowingManageSubscriptions(handler)
                }
                .applyIfLet(self.refundRequestStartedHandler) { view, handler in
                    view.onCustomerCenterRefundRequestStarted(handler)
                }
                .applyIfLet(self.refundRequestCompletedHandler) { view, handler in
                    view.onCustomerCenterRefundRequestCompleted(handler)
                }
                .applyIfLet(self.feedbackSurveyCompletedHandler) { view, handler in
                    view.onCustomerCenterFeedbackSurveyCompleted(handler)
                }
        } label: {
            label()
        }
    }
}

#endif
