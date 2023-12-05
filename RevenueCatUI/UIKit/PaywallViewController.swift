//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallViewController.swift
//  
//  Created by Nacho Soto on 8/1/23.

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

import RevenueCat
import SwiftUI
import UIKit

/// A view controller for displaying `PaywallData` for an `Offering`.
///
/// - Seealso: ``PaywallView`` for `SwiftUI`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallViewController)
public final class PaywallViewController: UIViewController {

    /// See ``PaywallViewControllerDelegate`` for receiving purchase events.
    public weak var delegate: PaywallViewControllerDelegate?

    private let offering: Offering?
    private let displayCloseButton: Bool

    /// Initialize a `PaywallViewController` with an optional `Offering`.
    /// - Parameter offering: The `Offering` containing the desired `PaywallData` to display.
    /// `Offerings.current` will be used by default.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    @objc
    public init(
        offering: Offering? = nil,
        displayCloseButton: Bool = false
    ) {
        self.offering = offering
        self.displayCloseButton = displayCloseButton

        super.init(nibName: nil, bundle: nil)
    }

    // swiftlint:disable:next missing_docs
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var hostingController: UIHostingController<some View> = {
        let paywallView = self.offering
            .map { PaywallView(offering: $0, displayCloseButton: self.displayCloseButton) }
            ?? PaywallView(displayCloseButton: self.displayCloseButton)

        let view = paywallView
            .onPurchaseCompleted { [weak self] transaction, customerInfo in
                guard let self = self else { return }
                self.delegate?.paywallViewController?(self, didFinishPurchasingWith: customerInfo)
                self.delegate?.paywallViewController?(self,
                                                      didFinishPurchasingWith: customerInfo,
                                                      transaction: transaction)
            }
            .onRestoreCompleted { [weak self] customerInfo in
                guard let self = self else { return }
                self.delegate?.paywallViewController?(self, didFinishRestoringWith: customerInfo)
            }

        return .init(rootView: view)
    }()

    public override func loadView() {
        super.loadView()

        self.addChild(self.hostingController)
        self.view.addSubview(self.hostingController.view)
        self.hostingController.didMove(toParent: self)
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.hostingController.view.frame = self.view.bounds
    }

    public override func viewDidDisappear(_ animated: Bool) {
        if isBeingDismissed {
            self.delegate?.paywallViewControllerDismissed?(self)
        }
        super.viewDidDisappear(animated)
    }
}

/// Delegate for ``PaywallViewController``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallViewControllerDelegate)
public protocol PaywallViewControllerDelegate: AnyObject {

    /// Notifies that a purchase has completed in a ``PaywallViewController``.
    @objc(paywallViewController:didFinishPurchasingWithCustomerInfo:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFinishPurchasingWith customerInfo: CustomerInfo)

    /// Notifies that a purchase has completed in a ``PaywallViewController``.
    @objc(paywallViewController:didFinishPurchasingWithCustomerInfo:transaction:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFinishPurchasingWith customerInfo: CustomerInfo,
                                        transaction: StoreTransaction?)

    /// Notifies that the restore operation has completed in a ``PaywallViewController``.
    ///
    /// - Warning: Receiving a ``CustomerInfo``does not imply that the user has any entitlements,
    /// simply that the process was successful. You must verify the ``CustomerInfo/entitlements``
    /// to confirm that they are active.
    @objc(paywallViewController:didFinishRestoringWithCustomerInfo:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFinishRestoringWith customerInfo: CustomerInfo)

    /// Notifies that the ``PaywallViewController`` was dismissed.
    @objc(paywallViewControllerDismissed:)
    optional func paywallViewControllerDismissed(_ controller: PaywallViewController)

}

#endif
