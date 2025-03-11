//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewController.swift
//
//  Created by Will Taylor on 12/6/24.

import RevenueCat
import SwiftUI

#if canImport(UIKit) && os(iOS)

/// Use the Customer Center in your app to help your customers manage common support tasks.
///
/// Customer Center is a self-service UI that can be added to your app to help
/// your customers manage their subscriptions on their own. With it, you can prevent
/// churn with pre-emptive promotional offers, capture actionable customer data with
/// exit feedback prompts, and lower support volumes for common inquiries — all
/// without any help from your support team.
///
/// The `CustomerCenterViewController` can be used to integrate the Customer Center directly in your app with UIKit.
///
/// For more information, see the [Customer Center docs](https://www.revenuecat.com/docs/tools/customer-center).
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class CustomerCenterViewController: UIHostingController<CustomerCenterView> {

    // Handler for when the view controller is dismissed
    public var onDismiss: (() -> Void)?

    // Stored handlers for later updating if needed
    private var restoreStartedHandler: CustomerCenterView.RestoreStartedHandler?
    private var restoreCompletedHandler: CustomerCenterView.RestoreCompletedHandler?
    private var restoreFailedHandler: CustomerCenterView.RestoreFailedHandler?
    private var showingManageSubscriptionsHandler: CustomerCenterView.ShowingManageSubscriptionsHandler?
    private var refundRequestStartedHandler: CustomerCenterView.RefundRequestStartedHandler?
    private var refundRequestCompletedHandler: CustomerCenterView.RefundRequestCompletedHandler?
    private var feedbackSurveyCompletedHandler: CustomerCenterView.FeedbackSurveyCompletedHandler?

    // MARK: - Initialization

    /// Create a view controller to handle common customer support tasks
    /// - Parameters:
    ///   - customerCenterActionHandler: An optional `CustomerCenterActionHandler` to handle actions
    ///   from the Customer Center.
    @available(*, deprecated, message: "Use the initializer with individual action handlers instead")
    public init(
        customerCenterActionHandler: CustomerCenterActionHandler?
    ) {
        // Initialize with a basic view first
        let view = CustomerCenterView()
        super.init(rootView: view)

        // Map the legacy handler to individual handlers
        if let handler = customerCenterActionHandler {
            self.restoreStartedHandler = { handler(.restoreStarted) }
            self.restoreCompletedHandler = { handler(.restoreCompleted($0)) }
            self.restoreFailedHandler = { handler(.restoreFailed($0)) }
            self.showingManageSubscriptionsHandler = { handler(.showingManageSubscriptions) }
            self.refundRequestStartedHandler = { handler(.refundRequestStarted($0)) }
            self.refundRequestCompletedHandler = { handler(.refundRequestCompleted($0)) }
            self.feedbackSurveyCompletedHandler = { handler(.feedbackSurveyCompleted($0)) }
        }

        // Update the view after init
        updateRootView()
    }

    /// Create a view controller to handle common customer support tasks with individual action handlers
    /// - Parameters:
    ///   - restoreStarted: Handler called when a restore operation starts.
    ///   - restoreCompleted: Handler called when a restore operation completes successfully.
    ///   - restoreFailed: Handler called when a restore operation fails.
    ///   - showingManageSubscriptions: Handler called when the user navigates to manage subscriptions.
    ///   - refundRequestStarted: Handler called when a refund request starts.
    ///   - refundRequestCompleted: Handler called when a refund request completes.
    ///   - feedbackSurveyCompleted: Handler called when a feedback survey is completed.
    ///   - onDismiss: Handler called when the view controller is dismissed.
    public init(
        restoreStarted: CustomerCenterView.RestoreStartedHandler? = nil,
        restoreCompleted: CustomerCenterView.RestoreCompletedHandler? = nil,
        restoreFailed: CustomerCenterView.RestoreFailedHandler? = nil,
        showingManageSubscriptions: CustomerCenterView.ShowingManageSubscriptionsHandler? = nil,
        refundRequestStarted: CustomerCenterView.RefundRequestStartedHandler? = nil,
        refundRequestCompleted: CustomerCenterView.RefundRequestCompletedHandler? = nil,
        feedbackSurveyCompleted: CustomerCenterView.FeedbackSurveyCompletedHandler? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        // Initialize with a basic view first
        let view = CustomerCenterView()
        super.init(rootView: view)

        // Store all handlers
        self.onDismiss = onDismiss
        self.restoreStartedHandler = restoreStarted
        self.restoreCompletedHandler = restoreCompleted
        self.restoreFailedHandler = restoreFailed
        self.showingManageSubscriptionsHandler = showingManageSubscriptions
        self.refundRequestStartedHandler = refundRequestStarted
        self.refundRequestCompletedHandler = refundRequestCompleted
        self.feedbackSurveyCompletedHandler = feedbackSurveyCompleted

        // Update the view after init
        updateRootView()
    }

    @available(*, unavailable, message: "Use init with handlers instead.")
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidDisappear(_ animated: Bool) {
        if self.isBeingDismissed {
            self.onDismiss?()
        }
        super.viewDidDisappear(animated)
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension CustomerCenterViewController {

    func updateRootView() {
        let childView = CustomerCenterView()
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

        addViewAsChild(childView)
    }

    func addViewAsChild<Content: View>(_ content: Content) {
        // Create a hosting controller for the modified view
        let wrapper = UIHostingController(rootView: content)

        // Add hosting controller as child view controller
        addChild(wrapper)
        view.addSubview(wrapper.view)
        wrapper.didMove(toParent: self)

        // Make it fill the parent view
        wrapper.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapper.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wrapper.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wrapper.view.topAnchor.constraint(equalTo: view.topAnchor),
            wrapper.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

}

#endif
