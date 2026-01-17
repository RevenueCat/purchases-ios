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

import Combine
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
@objc(RCCustomerCenterViewController)
public class CustomerCenterViewController: UIViewController {

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Initialization
    /// See ``CustomerCenterViewControllerDelegate`` for receiving Customer Center events.
    @objc private final weak var delegate: CustomerCenterViewControllerDelegate?

    /// The action wrapper for the current view, used for Swift closure-based handlers
    private var actionWrapper: CustomerCenterActionWrapper?

    /// Create a view controller with a delegate for receiving callbacks.
    ///
    /// This initializer is designed for Objective-C compatibility.
    /// Swift users may prefer using the closure-based initializer instead.
    ///
    /// - Parameter delegate: The delegate to receive Customer Center callbacks.
    @objc
    public init(delegate: CustomerCenterViewControllerDelegate?) {
        super.init(nibName: nil, bundle: nil)

        self.delegate = delegate

        let actionWrapper = CustomerCenterActionWrapper()
        setupDelegateBindings(actionWrapper: actionWrapper)
        self.actionWrapper = actionWrapper
    }

    /// Create a view controller to handle common customer support tasks
    /// - Parameters:
    ///   - customerCenterActionHandler: An optional `CustomerCenterActionHandler` to handle actions
    ///   from the Customer Center.
    @available(*, deprecated, message: "Use the initializer with individual action handlers instead")
    public init(
        customerCenterActionHandler: CustomerCenterActionHandler?
    ) {
        super.init(nibName: nil, bundle: nil)

        let actionWrapper = CustomerCenterActionWrapper()

        if let handler = customerCenterActionHandler {
            actionWrapper.restoreStartedPublisher
                .sink { handler(.restoreStarted) }
                .store(in: &cancellables)
            actionWrapper.restoreCompletedPublisher
                .sink { handler(.restoreCompleted($0)) }
                .store(in: &cancellables)
            actionWrapper.restoreFailedPublisher
                .sink { handler(.restoreFailed($0)) }
                .store(in: &cancellables)
            actionWrapper.showingManageSubscriptionsPublisher
                .sink { handler(.showingManageSubscriptions) }
                .store(in: &cancellables)
            actionWrapper.refundRequestStartedPublisher
                .sink { handler(.refundRequestStarted($0)) }
                .store(in: &cancellables)
            actionWrapper.refundRequestCompletedPublisher
                .sink { handler(.refundRequestCompleted($0.1)) }
                .store(in: &cancellables)
            actionWrapper.feedbackSurveyCompletedPublisher
                .sink { handler(.feedbackSurveyCompleted($0)) }
                .store(in: &cancellables)
        }

        self.actionWrapper = actionWrapper
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    /// Create a view controller to handle common customer support tasks with individual action handlers
    /// - Parameters:
    ///   - restoreStarted: Handler called when a restore operation starts.
    ///   - restoreCompleted: Handler called when a restore operation completes successfully.
    ///   - restoreFailed: Handler called when a restore operation fails.
    ///   - showingManageSubscriptions: Handler called when the user navigates to manage subscriptions.
    ///   - refundRequestStarted: Handler called when a refund request starts.
    ///   - refundRequestCompleted: Handler called when a refund request completes.
    ///   - feedbackSurveyCompleted: Handler called when a feedback survey is completed.
    public init(
        restoreStarted: CustomerCenterView.RestoreStartedHandler? = nil,
        restoreCompleted: CustomerCenterView.RestoreCompletedHandler? = nil,
        restoreFailed: CustomerCenterView.RestoreFailedHandler? = nil,
        showingManageSubscriptions: CustomerCenterView.ShowingManageSubscriptionsHandler? = nil,
        refundRequestStarted: CustomerCenterView.RefundRequestStartedHandler? = nil,
        refundRequestCompleted: CustomerCenterView.RefundRequestCompletedHandler? = nil,
        feedbackSurveyCompleted: CustomerCenterView.FeedbackSurveyCompletedHandler? = nil,
        managementOptionSelected: CustomerCenterView.ManagementOptionSelectedHandler? = nil,
        changePlansSelected: CustomerCenterView.ChangePlansHandler? = nil,
        onCustomAction: CustomerCenterView.CustomActionHandler? = nil,
        promotionalOfferSuccess: CustomerCenterView.PromotionalOfferSuccessHandler? = nil
    ) {
        super.init(nibName: nil, bundle: nil)

        let actionWrapper = CustomerCenterActionWrapper()

        // Set up Combine subscriptions to emit handler calls
        if let restoreStarted {
            actionWrapper.restoreStartedPublisher
                .sink(receiveValue: restoreStarted)
                .store(in: &cancellables)
        }

        if let restoreCompleted {
            actionWrapper.restoreCompletedPublisher
                .sink(receiveValue: restoreCompleted)
                .store(in: &cancellables)
        }

        if let restoreFailed {
            actionWrapper.restoreFailedPublisher
                .sink(receiveValue: restoreFailed)
                .store(in: &cancellables)
        }

        if let showingManageSubscriptions {
            actionWrapper.showingManageSubscriptionsPublisher
                .sink(receiveValue: showingManageSubscriptions)
                .store(in: &cancellables)
        }

        if let refundRequestStarted {
            actionWrapper.refundRequestStartedPublisher
                .sink(receiveValue: refundRequestStarted)
                .store(in: &cancellables)
        }

        if let refundRequestCompleted {
            actionWrapper.refundRequestCompletedPublisher
                .sink(receiveValue: { refundRequestCompleted($0.0, $0.1) })
                .store(in: &cancellables)
        }

        if let feedbackSurveyCompleted {
            actionWrapper.feedbackSurveyCompletedPublisher
                .sink(receiveValue: feedbackSurveyCompleted)
                .store(in: &cancellables)
        }

        if let managementOptionSelected {
            actionWrapper.managementOptionSelectedPublisher
                .sink(receiveValue: managementOptionSelected)
                .store(in: &cancellables)
        }

        if let changePlansSelected {
            actionWrapper.showingChangePlansPublisher
                .compactMap { $0 }
                .sink(receiveValue: changePlansSelected)
                .store(in: &cancellables)
        }

        if let onCustomAction {
            actionWrapper.customActionSelectedPublisher
                .sink(receiveValue: { onCustomAction($0.0, $0.1) })
                .store(in: &cancellables)
        }

        if let promotionalOfferSuccess {
            actionWrapper.promotionalOfferSuccessPublisher
                .sink(receiveValue: promotionalOfferSuccess)
                .store(in: &cancellables)
        }

        self.actionWrapper = actionWrapper
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    @available(*, unavailable, message: "Use init with handlers instead.")
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

   public override func viewDidLoad() {
        super.viewDidLoad()

        if self.hostingController == nil {
            self.hostingController = self.createHostingController()
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        if self.isBeingDismissed {
            self.delegate?.customerCenterViewControllerWasDismissed?(self)
        }
        super.viewDidDisappear(animated)
    }

    // MARK: - Private

    /// The hosting controller that contains the SwiftUI CustomerCenterView
    private var hostingController: UIHostingController<CustomerCenterView>? {
        willSet {
            guard let oldController = self.hostingController else { return }

            oldController.willMove(toParent: nil)
            oldController.view.removeFromSuperview()
            oldController.removeFromParent()
        }

        didSet {
            guard let newController = self.hostingController else { return }

            self.addChild(newController)

            self.view.subviews.forEach { $0.removeFromSuperview() }

            self.view.addSubview(newController.view)
            newController.didMove(toParent: self)

            newController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                newController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                newController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                newController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                newController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        }
    }

    // swiftlint:disable:next function_body_length
    private func setupDelegateBindings(actionWrapper: CustomerCenterActionWrapper) {
        actionWrapper.restoreStartedPublisher
            .sink { [weak self] in
                guard let self else { return }
                self.delegate?.customerCenterViewControllerDidStartRestore?(self)
            }
            .store(in: &cancellables)

        actionWrapper.restoreCompletedPublisher
            .sink { [weak self] customerInfo in
                guard let self else { return }
                self.delegate?.customerCenterViewController?(self, didFinishRestoringWith: customerInfo)
            }
            .store(in: &cancellables)

        actionWrapper.restoreFailedPublisher
            .sink { [weak self] error in
                guard let self else { return }
                self.delegate?.customerCenterViewController?(self, didFailRestoringWith: error)
            }
            .store(in: &cancellables)

        actionWrapper.showingManageSubscriptionsPublisher
            .sink { [weak self] in
                guard let self else { return }
                self.delegate?.customerCenterViewControllerDidShowManageSubscriptions?(self)
            }
            .store(in: &cancellables)

        actionWrapper.refundRequestStartedPublisher
            .sink { [weak self] productId in
                guard let self else { return }
                self.delegate?.customerCenterViewController?(self, didStartRefundRequestFor: productId)
            }
            .store(in: &cancellables)

        actionWrapper.refundRequestCompletedPublisher
            .sink { [weak self] productId, status in
                guard let self else { return }
                self.delegate?.customerCenterViewController?(
                    self,
                    didCompleteRefundRequestFor: productId,
                    with: status
                )
            }
            .store(in: &cancellables)

        actionWrapper.feedbackSurveyCompletedPublisher
            .sink { [weak self] optionId in
                guard let self else { return }
                self.delegate?.customerCenterViewController?(
                    self,
                    didCompleteFeedbackSurveyWith: optionId
                )
            }
            .store(in: &cancellables)

        actionWrapper.showingChangePlansPublisher
            .compactMap { $0 }
            .sink { [weak self] optionId in
                guard let self else { return }
                self.delegate?.customerCenterViewController?(
                    self,
                    didSelectChangePlansWith: optionId
                )
            }
            .store(in: &cancellables)

        actionWrapper.customActionSelectedPublisher
            .sink { [weak self] actionId, purchaseId in
                guard let self else { return }
                self.delegate?.customerCenterViewController?(
                    self,
                    didSelectCustomActionWith: actionId,
                    purchaseIdentifier: purchaseId
                )
            }
            .store(in: &cancellables)

        actionWrapper.promotionalOfferSuccessPublisher
            .sink { [weak self] in
                guard let self else { return }
                self.delegate?.customerCenterViewControllerDidSucceedWithPromotionalOffer?(self)
            }
            .store(in: &cancellables)
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension CustomerCenterViewController {
    func createHostingController() -> UIHostingController<CustomerCenterView> {
        let navigationOptions = CustomerCenterNavigationOptions(
            onCloseHandler: { [weak self] in
                guard let self else { return }
                if let delegate = self.delegate,
                   delegate.responds(to: #selector(
                    CustomerCenterViewControllerDelegate.customerCenterViewControllerWasDismissed(_:)
                   )) {
                    delegate.customerCenterViewControllerWasDismissed?(self)
                } else {
                    self.dismiss(animated: true)
                }
            }
        )

        let view: CustomerCenterView
        if let wrapper = self.actionWrapper {
            view = CustomerCenterView(
                actionWrapper: wrapper,
                mode: .default,
                navigationOptions: navigationOptions
            )
        } else {
            view = CustomerCenterView(navigationOptions: navigationOptions)
        }

        let controller = UIHostingController(rootView: view)

        // make the background of the container clear so that if there are cutouts, they don't get
        // overridden by the hostingController's view's background.
        controller.view.backgroundColor = .clear

        return controller
    }
}

#endif
