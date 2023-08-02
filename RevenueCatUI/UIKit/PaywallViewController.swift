//
//  PaywallViewController.swift
//  
//
//  Created by Nacho Soto on 8/1/23.
//

import RevenueCat
import SwiftUI
import UIKit

/// A view controller for displaying `PaywallData` for an `Offering`.
///
/// - Seealso: ``PaywallView`` for `SwiftUI`.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@objc(RCPaywallViewController)
public final class PaywallViewController: UIViewController {

    /// See ``PaywallViewControllerDelegate`` for receiving purchase events.
    public weak var delegate: PaywallViewControllerDelegate?

    // swiftlint:disable:next missing_docs
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    // swiftlint:disable:next missing_docs
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var hostingController: UIHostingController<AnyView> = {
        let view = PaywallView()
            .onPurchaseCompleted { [weak self] customerInfo in
                guard let self = self else { return }
                self.delegate?.paywallViewController(self, didFinishPurchasing: customerInfo)
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
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@objc(RCPaywallViewControllerDelegate)
public protocol PaywallViewControllerDelegate: AnyObject {

    /// Notifies that a purchase has completed in a ``PaywallViewController``.
    @objc(paywallViewController:didFinishPurchasingWithCustomerInfo:)
    func paywallViewController(_ controller: PaywallViewController,
                               didFinishPurchasing with: CustomerInfo)

}
