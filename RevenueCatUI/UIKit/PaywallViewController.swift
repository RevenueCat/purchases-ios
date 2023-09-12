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

#if canImport(UIKit)

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

    // swiftlint:disable:next missing_docs
    public init(offering: Offering? = nil) {
        self.offering = offering

        super.init(nibName: nil, bundle: nil)
    }

    // swiftlint:disable:next missing_docs
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var hostingController: UIHostingController<AnyView> = {
        let paywallView = self.offering.map { PaywallView(offering: $0) } ?? PaywallView()

        let view = paywallView
            .onPurchaseCompleted { [weak self] customerInfo in
                guard let self = self else { return }
                self.delegate?.paywallViewController?(self, didFinishPurchasingWith: customerInfo)
            }
            .onRestoreCompleted { [weak self] customerInfo in
                guard let self = self else { return }
                self.delegate?.paywallViewController?(self, didFinishRestoringWith: customerInfo)
            }

        return .init(rootView: AnyView(view))
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

/// Delegate for ``PaywallViewController``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallViewControllerDelegate)
public protocol PaywallViewControllerDelegate: AnyObject {

    /// Notifies that a purchase has completed in a ``PaywallViewController``.
    @objc(paywallViewController:didFinishPurchasingWithCustomerInfo:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFinishPurchasingWith customerInfo: CustomerInfo)

    /// Notifies that the restore operation has completed in a ``PaywallViewController``.
    ///
    /// - Warning: Receiving a ``CustomerInfo``does not imply that the user has any entitlements,
    /// simply that the process was successful. You must verify the ``CustomerInfo/entitlements``
    /// to confirm that they are active.
    @objc(paywallViewController:didFinishRestoringWithCustomerInfo:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFinishRestoringWith customerInfo: CustomerInfo)

}

#endif
