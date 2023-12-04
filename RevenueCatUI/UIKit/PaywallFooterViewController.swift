//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallFooterViewController.swift
//
//  Created by Antonio Rico Diez on 4/12/23.
//

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

import RevenueCat
import SwiftUI
import UIKit

/// A view controller for displaying `PaywallData` for an `Offering`.
///
/// - Seealso: ``PaywallView`` for `SwiftUI`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallFooterViewController)
public final class PaywallFooterViewController: UIViewController {

    /// See ``PaywallFooterViewControllerDelegate`` for receiving purchase events.
    public weak var delegate: PaywallFooterViewControllerDelegate?

    private let offering: Offering?

    /// Initialize a `PaywallFooterViewController` with an optional `Offering`.
    /// - Parameter offering: The `Offering` containing the desired `PaywallData` to display.
    /// `Offerings.current` will be used by default.
    @objc
    public init(
        offering: Offering? = nil
    ) {
        self.offering = offering

        super.init(nibName: nil, bundle: nil)
    }

    // swiftlint:disable:next missing_docs
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var hostingController: UIHostingController<some View> = {
        let paywallView = PaywallView(offering: self.offering,
                                      customerInfo: nil,
                                      mode: .footer,
                                      displayCloseButton: false,
                                      introEligibility: nil,
                                      purchaseHandler: nil)

        let view = paywallView
            .onPurchaseCompleted { [weak self] transaction, customerInfo in
                guard let self = self else { return }
                self.delegate?.paywallFooterViewController?(self, didFinishPurchasingWith: customerInfo)
                self.delegate?.paywallFooterViewController?(self,
                                                            didFinishPurchasingWith: customerInfo,
                                                            transaction: transaction)
            }
            .onRestoreCompleted { [weak self] customerInfo in
                guard let self = self else { return }
                self.delegate?.paywallFooterViewController?(self, didFinishRestoringWith: customerInfo)
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

}

/// Delegate for ``PaywallFooterViewController``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallFooterViewControllerDelegate)
public protocol PaywallFooterViewControllerDelegate: AnyObject {

    /// Notifies that a purchase has completed in a ``PaywallFooterViewController``.
    @objc(paywallFooterViewController:didFinishPurchasingWithCustomerInfo:)
    optional func paywallFooterViewController(_ controller: PaywallFooterViewController,
                                              didFinishPurchasingWith customerInfo: CustomerInfo)

    /// Notifies that a purchase has completed in a ``PaywallFooterViewController``.
    @objc(paywallFooterViewController:didFinishPurchasingWithCustomerInfo:transaction:)
    optional func paywallFooterViewController(_ controller: PaywallFooterViewController,
                                              didFinishPurchasingWith customerInfo: CustomerInfo,
                                              transaction: StoreTransaction?)

    /// Notifies that the restore operation has completed in a ``PaywallFooterViewController``.
    ///
    /// - Warning: Receiving a ``CustomerInfo``does not imply that the user has any entitlements,
    /// simply that the process was successful. You must verify the ``CustomerInfo/entitlements``
    /// to confirm that they are active.
    @objc(paywallFooterViewController:didFinishRestoringWithCustomerInfo:)
    optional func paywallFooterViewController(_ controller: PaywallFooterViewController,
                                              didFinishRestoringWith customerInfo: CustomerInfo)

}

#endif
