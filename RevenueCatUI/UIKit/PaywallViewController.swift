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
public class PaywallViewController: UIViewController {

    /// See ``PaywallViewControllerDelegate`` for receiving purchase events.
    @objc public final weak var delegate: PaywallViewControllerDelegate?

    var mode: PaywallViewMode {
        return .fullScreen
    }

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
        let view = PaywallView(offering: self.offering,
                               customerInfo: nil,
                               mode: self.mode,
                               displayCloseButton: self.displayCloseButton,
                               introEligibility: nil,
                               purchaseHandler: nil)
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
        self.hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // for footers we only want to tie to the sides and the bottom.
        if self.mode == .fullScreen {
            NSLayoutConstraint.activate([
                self.hostingController.view.topAnchor.constraint(equalTo: view.topAnchor)
            ])
        }

        // make the background of the container clear so that if there are cutouts, they don't get
        // overridden by the hostingController's view's background.
        self.hostingController.view.backgroundColor = .clear
    }

    public override func viewDidDisappear(_ animated: Bool) {
        if self.isBeingDismissed {
            self.delegate?.paywallViewControllerWasDismissed?(self)
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
    @objc(paywallViewControllerWasDismissed:)
    optional func paywallViewControllerWasDismissed(_ controller: PaywallViewController)

}

#endif
