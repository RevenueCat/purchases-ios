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

    private var configuration: PaywallViewConfiguration {
        didSet {
            // Overriding the configuration requires re-creating the `HostingViewController`.
            // This is used by some Hybrid SDKs that require modifying the content after creation.
            self.hostingController = self.createHostingController()
        }
    }

    /// Initialize a `PaywallViewController` with an optional `Offering`.
    /// - Parameter offering: The `Offering` containing the desired `PaywallData` to display.
    /// `Offerings.current` will be used by default.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    @objc
    public convenience init(
        offering: Offering? = nil,
        displayCloseButton: Bool = false
    ) {
        self.init(
            offering: offering,
            fonts: DefaultPaywallFontProvider(),
            displayCloseButton: displayCloseButton
        )
    }

    /// Initialize a `PaywallViewController` with an optional `Offering` and ``PaywallFontProvider``.
    /// - Parameter offering: The `Offering` containing the desired `PaywallData` to display.
    /// `Offerings.current` will be used by default.
    /// - Parameter fonts: A ``PaywallFontProvider``.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    public convenience init(
        offering: Offering? = nil,
        fonts: PaywallFontProvider,
        displayCloseButton: Bool = false
    ) {
        self.init(
            content: .optionalOffering(offering),
            fonts: fonts,
            displayCloseButton: displayCloseButton
        )
    }

    /// Initialize a `PaywallViewController` with an offering identifier.
    /// - Parameter offeringIdentifier: The identifier for the offering with `PaywallData` to display.
    /// - Parameter fonts: A ``PaywallFontProvider``.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    public convenience init(
        offeringIdentifier: String,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false
    ) {
        self.init(
            content: .offeringIdentifier(offeringIdentifier),
            fonts: fonts,
            displayCloseButton: displayCloseButton
        )
    }

    init(
        content: PaywallViewConfiguration.Content,
        fonts: PaywallFontProvider,
        displayCloseButton: Bool
    ) {
        self.configuration = .init(
            content: content,
            mode: Self.mode,
            fonts: fonts,
            displayCloseButton: displayCloseButton
        )

        super.init(nibName: nil, bundle: nil)
    }

    // swiftlint:disable:next missing_docs
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        super.loadView()

        self.hostingController = self.createHostingController()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        if self.isBeingDismissed {
            self.delegate?.paywallViewControllerWasDismissed?(self)
        }
        super.viewDidDisappear(animated)
    }

    /// - Warning: For internal use only
    @objc(updateWithOffering:)
    public func update(with offering: Offering) {
        self.configuration.content = .offering(offering)
    }

    /// - Warning: For internal use only
    @objc(updateWithOfferingIdentifier:)
    public func update(with offeringIdentifier: String) {
        self.configuration.content = .offeringIdentifier(offeringIdentifier)
    }

    /// - Warning: For internal use only
    @objc(updateFontWithFontName:)
    public func updateFont(with fontName: String) {
        self.configuration.fonts = CustomPaywallFontProvider(fontName: fontName)
    }

    // MARK: - Internal

    class var mode: PaywallViewMode {
        return .fullScreen
    }

    // MARK: - Private

    private var hostingController: UIHostingController<PaywallContainerView>? {
        willSet {
            guard let oldValue = self.hostingController else { return }

            oldValue.willMove(toParent: nil)
            oldValue.view.removeFromSuperview()
            oldValue.removeFromParent()
        }

        didSet {
            guard let newController = self.hostingController else { return }

            self.addChild(newController)
            self.view.addSubview(newController.view)
            newController.didMove(toParent: self)

            NSLayoutConstraint.activate([
                newController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                newController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                newController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                newController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        }
    }

}

// MARK: - PaywallViewControllerDelegate

/// Delegate for ``PaywallViewController``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallViewControllerDelegate)
public protocol PaywallViewControllerDelegate: AnyObject {

    /// Notifies that a purchase has started in a ``PaywallViewController``.
    @objc(paywallViewControllerDidStartPurchase:)
    optional func paywallViewControllerDidStartPurchase(_ controller: PaywallViewController)

    /// Notifies that a purchase has completed in a ``PaywallViewController``.
    @objc(paywallViewController:didFinishPurchasingWithCustomerInfo:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFinishPurchasingWith customerInfo: CustomerInfo)

    /// Notifies that a purchase has completed in a ``PaywallViewController``.
    @objc(paywallViewController:didFinishPurchasingWithCustomerInfo:transaction:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFinishPurchasingWith customerInfo: CustomerInfo,
                                        transaction: StoreTransaction?)

    /// Notifies that a purchase has been cancelled in a ``PaywallViewController``.
    @objc(paywallViewControllerDidCancelPurchase:)
    optional func paywallViewControllerDidCancelPurchase(_ controller: PaywallViewController)

    /// Notifies that the purchase operation has failed in a ``PaywallViewController``.
    @objc(paywallViewController:didFailPurchasingWithError:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFailPurchasingWith error: NSError)

    /// Notifies that the restore operation has completed in a ``PaywallViewController``.
    ///
    /// - Warning: Receiving a ``CustomerInfo``does not imply that the user has any entitlements,
    /// simply that the process was successful. You must verify the ``CustomerInfo/entitlements``
    /// to confirm that they are active.
    @objc(paywallViewController:didFinishRestoringWithCustomerInfo:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFinishRestoringWith customerInfo: CustomerInfo)

    /// Notifies that the restore operation has failed in a ``PaywallViewController``.
    @objc(paywallViewController:didFailRestoringWithError:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didFailRestoringWith error: NSError)

    /// Notifies that the ``PaywallViewController`` was dismissed.
    @objc(paywallViewControllerWasDismissed:)
    optional func paywallViewControllerWasDismissed(_ controller: PaywallViewController)

    /// For internal use only.
    @objc(paywallViewController:didChangeSizeTo:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didChangeSizeTo size: CGSize)

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewController {

    func createHostingController() -> UIHostingController<PaywallContainerView> {
        let container = PaywallContainerView(
            configuration: self.configuration,
            purchaseStarted: { [weak self] in
                guard let self else { return }
                self.delegate?.paywallViewControllerDidStartPurchase?(self)
            },
            purchaseCompleted: { [weak self] transaction, customerInfo in
                guard let self else { return }
                self.delegate?.paywallViewController?(self, didFinishPurchasingWith: customerInfo)
                self.delegate?.paywallViewController?(self,
                                                      didFinishPurchasingWith: customerInfo,
                                                      transaction: transaction)
            },
            purchaseCancelled: { [weak self] in
                guard let self else { return }
                self.delegate?.paywallViewControllerDidCancelPurchase?(self)
            },
            restoreCompleted: { [weak self] customerInfo in
                guard let self else { return }
                self.delegate?.paywallViewController?(self, didFinishRestoringWith: customerInfo)
            },
            purchaseFailure: { [weak self] error in
                guard let self else { return }
                self.delegate?.paywallViewController?(self, didFailPurchasingWith: error)
            },
            restoreFailure: { [weak self] error in
                guard let self else { return }
                self.delegate?.paywallViewController?(self, didFailRestoringWith: error)
            },
            onSizeChange: { [weak self] in
                guard let self else { return }
                self.delegate?.paywallViewController?(self, didChangeSizeTo: $0)
            }
        )

        let controller = UIHostingController(rootView: container)

        // make the background of the container clear so that if there are cutouts, they don't get
        // overridden by the hostingController's view's background.
        controller.view.backgroundColor = .clear
        controller.view.translatesAutoresizingMaskIntoConstraints = false

        return controller
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct PaywallContainerView: View {

    var configuration: PaywallViewConfiguration

    let purchaseStarted: PurchaseStartedHandler
    let purchaseCompleted: PurchaseCompletedHandler
    let purchaseCancelled: PurchaseCancelledHandler
    let restoreCompleted: PurchaseOrRestoreCompletedHandler
    let purchaseFailure: PurchaseFailureHandler
    let restoreFailure: PurchaseFailureHandler
    let onSizeChange: (CGSize) -> Void

    var body: some View {
        PaywallView(configuration: self.configuration)
            .onPurchaseStarted(self.purchaseStarted)
            .onPurchaseCompleted(self.purchaseCompleted)
            .onPurchaseCancelled(self.purchaseCancelled)
            .onRestoreCompleted(self.restoreCompleted)
            .onPurchaseFailure(self.purchaseFailure)
            .onRestoreFailure(self.restoreFailure)
            .onSizeChange(self.onSizeChange)

    }

}

#endif
