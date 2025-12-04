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

// swiftlint:disable file_length

import SwiftUI

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

import RevenueCat

import UIKit

/// A view controller for displaying the paywall for an `Offering`.
///
/// - Seealso: ``PaywallView`` for `SwiftUI`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallViewController)
public class PaywallViewController: UIViewController {

    /// See ``PaywallViewControllerDelegate`` for receiving purchase events.
    @objc public final weak var delegate: PaywallViewControllerDelegate?

    private final var shouldBlockTouchEvents: Bool
    private final var dismissRequestedHandler: ((_ controller: PaywallViewController) -> Void)?

    private var configuration: PaywallViewConfiguration {
        didSet {
            // Overriding the configuration requires re-creating the `HostingViewController`.
            // This is used by some Hybrid SDKs that require modifying the content after creation.
            self.hostingController = self.createHostingController()
        }
    }

    /// Initialize a `PaywallViewController` with an optional `Offering`.
    /// - Parameter offering: The `Offering` containing the desired paywall to display.
    /// `Offerings.current` will be used by default.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    /// - Parameter shouldBlockTouchEvents: Whether to interecept all touch events propagated through this VC
    /// - Parameter dismissRequestedHandler: If this is not set, the paywall will close itself automatically
    /// after a successful purchase. Otherwise use this handler to handle dismissals of the paywall
    @objc
    public convenience init(
        offering: Offering? = nil,
        displayCloseButton: Bool = false,
        shouldBlockTouchEvents: Bool = false,
        dismissRequestedHandler: ((_ controller: PaywallViewController) -> Void)? = nil
    ) {
        self.init(
            offering: offering,
            fonts: DefaultPaywallFontProvider(),
            displayCloseButton: displayCloseButton,
            shouldBlockTouchEvents: shouldBlockTouchEvents,
            dismissRequestedHandler: dismissRequestedHandler
        )
    }

    /// Initialize a `PaywallViewController` with an optional `Offering` and ``PaywallFontProvider``.
    /// - Parameter offering: The `Offering` containing the desired paywall to display.
    /// `Offerings.current` will be used by default.
    /// - Parameter fonts: A ``PaywallFontProvider``.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    /// - Parameter performPurchase: Closure to perform a purchase action. Only used when `Purchases`
    /// has been configured with `.with(purchasesAreCompletedBy: .myApp)`.
    /// - Parameter performRestore: Closure to perform a restore action. Only used when `Purchases`
    /// has been configured with `.with(purchasesAreCompletedBy: .myApp)`.
    /// - Parameter shouldBlockTouchEvents: Whether to interecept all touch events propagated through this VC.
    /// - Parameter dismissRequestedHandler: If this is not set, the paywall will close itself automatically
    /// after a successful purchase. Otherwise use this handler to handle dismissals of the paywall.
    public convenience init(
        offering: Offering? = nil,
        fonts: PaywallFontProvider,
        displayCloseButton: Bool = false,
        shouldBlockTouchEvents: Bool = false,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil,
        dismissRequestedHandler: ((_ controller: PaywallViewController) -> Void)? = nil
    ) {
        self.init(
            content: .optionalOffering(offering),
            fonts: fonts,
            displayCloseButton: displayCloseButton,
            shouldBlockTouchEvents: shouldBlockTouchEvents,
            performPurchase: performPurchase,
            performRestore: performRestore,
            dismissRequestedHandler: dismissRequestedHandler
        )
    }

    /// Initialize a `PaywallViewController` with an offering identifier.
    /// - Parameter offeringIdentifier: The identifier for the offering with paywall to display.
    /// - Parameter fonts: A ``PaywallFontProvider``.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    /// - Parameter shouldBlockTouchEvents: Whether to interecept all touch events propagated through this VC
    /// - Parameter dismissRequestedHandler: If this is not set, the paywall will close itself automatically
    /// after a successful purchase. Otherwise use this handler to handle dismissals of the paywall
    @available(*, deprecated, message: "use init with Offering instead")
    public convenience init(
        offeringIdentifier: String,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        shouldBlockTouchEvents: Bool = false,
        dismissRequestedHandler: ((_ controller: PaywallViewController) -> Void)? = nil
    ) {
        self.init(
            content: .offeringIdentifier(offeringIdentifier, presentedOfferingContext: nil),
            fonts: fonts,
            displayCloseButton: displayCloseButton,
            shouldBlockTouchEvents: shouldBlockTouchEvents,
            performPurchase: nil,
            performRestore: nil,
            dismissRequestedHandler: dismissRequestedHandler
        )
    }

    /// Initialize a `PaywallViewController` with an offering identifier.
    /// - Parameter offeringIdentifier: The identifier for the offering with paywall to display.
    /// - Parameter presentedOfferingContext: Information about how the offering is presented.
    /// - Parameter fonts: A ``PaywallFontProvider``.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    /// - Parameter shouldBlockTouchEvents: Whether to interecept all touch events propagated through this VC
    /// - Parameter performPurchase: Closure to perform a purchase action. Only used when `Purchases`
    /// has been configured with `.with(purchasesAreCompletedBy: .myApp)`.
    /// - Parameter performRestore: Closure to perform a restore action only used when `Purchases`
    /// has been configured with `.with(purchasesAreCompletedBy: .myApp)`.
    /// - Parameter dismissRequestedHandler: If this is not set, the paywall will close itself automatically
    /// after a successful purchase. Otherwise use this handler to handle dismissals of the paywall
    @_spi(Internal)
    public convenience init(
        offeringIdentifier: String,
        presentedOfferingContext: PresentedOfferingContext,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        shouldBlockTouchEvents: Bool = false,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil,
        dismissRequestedHandler: ((_ controller: PaywallViewController) -> Void)? = nil
    ) {
        self.init(
            content: .offeringIdentifier(offeringIdentifier, presentedOfferingContext: presentedOfferingContext),
            fonts: fonts,
            displayCloseButton: displayCloseButton,
            shouldBlockTouchEvents: shouldBlockTouchEvents,
            performPurchase: performPurchase,
            performRestore: performRestore,
            dismissRequestedHandler: dismissRequestedHandler
        )
    }

    init(
        content: PaywallViewConfiguration.Content,
        fonts: PaywallFontProvider,
        displayCloseButton: Bool,
        shouldBlockTouchEvents: Bool,
        performPurchase: PerformPurchase?,
        performRestore: PerformRestore?,
        dismissRequestedHandler: ((_ controller: PaywallViewController) -> Void)?
    ) {
        self.shouldBlockTouchEvents = shouldBlockTouchEvents
        self.dismissRequestedHandler = dismissRequestedHandler
        let handler = PurchaseHandler.default(performPurchase: performPurchase, performRestore: performRestore)

        self.configuration = .init(
            content: content,
            mode: Self.mode,
            fonts: fonts,
            displayCloseButton: displayCloseButton,
            purchaseHandler: handler
        )

        super.init(nibName: nil, bundle: nil)
    }

    // swiftlint:disable:next missing_docs
    public required init?(coder: NSCoder) {
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
    @available(*, deprecated, message: "use init with Offering instead")
    @objc(updateWithOfferingIdentifier:)
    public func update(with offeringIdentifier: String) {
        self.configuration.content = .offeringIdentifier(offeringIdentifier, presentedOfferingContext: nil)
    }

    /// - Warning: For internal use only
    @_spi(Internal)
    @objc(updateWithOfferingIdentifier:presentedOfferingContext:)
    public func update(with offeringIdentifier: String, presentedOfferingContext: PresentedOfferingContext?) {
        self.configuration.content = .offeringIdentifier(offeringIdentifier,
                                                         presentedOfferingContext: presentedOfferingContext)
    }

    /// - Warning: For internal use only
    @objc(updateWithDisplayCloseButton:)
    public func update(with displayCloseButton: Bool) {
        self.configuration.displayCloseButton = displayCloseButton
    }

    /// - Warning: For internal use only
    @objc(updateFontWithFontName:)
    public func updateFont(with fontName: String) {
        self.configuration.fonts = CustomPaywallFontProvider(fontName: fontName)
    }

    // Overriding touches conditionally to deal with https://github.com/RevenueCat/purchases-flutter/issues/1023
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !shouldBlockTouchEvents {
            super.touchesBegan(touches, with: event)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !shouldBlockTouchEvents {
            super.touchesMoved(touches, with: event)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !shouldBlockTouchEvents {
            super.touchesEnded(touches, with: event)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !shouldBlockTouchEvents {
            super.touchesCancelled(touches, with: event)
        }
    }

    // MARK: - Internal

    class var mode: PaywallViewMode {
        return .fullScreen
    }

    // MARK: - Private

    private var hostingController: UIHostingController<PaywallContainerView>? {
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

    /// Notifies that a purchase has started in a ``PaywallViewController``.
    @objc(paywallViewController:didStartPurchaseWithPackage:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        didStartPurchaseWith package: Package)

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

    /// Notifies that a restore has started in a ``PaywallViewController``.
    @objc(paywallViewControllerDidStartRestore:)
    optional func paywallViewControllerDidStartRestore(_ controller: PaywallViewController)

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

    // swiftlint:disable:next function_body_length
    func createHostingController() -> UIHostingController<PaywallContainerView> {
        var onRequestedDismissal: (() -> Void)?
        if let dismissRequestedHandler = self.dismissRequestedHandler {
            onRequestedDismissal = { [weak self] in
                guard let self = self else { return }
                dismissRequestedHandler(self)
            }
        }

        let container = PaywallContainerView(
            configuration: self.configuration,
            purchaseStarted: { [weak self] package in
                guard let self else { return }
                self.delegate?.paywallViewControllerDidStartPurchase?(self)
                self.delegate?.paywallViewController?(self, didStartPurchaseWith: package)
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
            restoreStarted: { [weak self] in
                guard let self else { return }
                self.delegate?.paywallViewControllerDidStartRestore?(self)
            },
            restoreFailure: { [weak self] error in
                guard let self else { return }
                self.delegate?.paywallViewController?(self, didFailRestoringWith: error)
            },
            requestedDismissal: onRequestedDismissal,
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

    let purchaseStarted: PurchaseOfPackageStartedHandler
    let purchaseCompleted: PurchaseCompletedHandler
    let purchaseCancelled: PurchaseCancelledHandler
    let restoreCompleted: PurchaseOrRestoreCompletedHandler
    let purchaseFailure: PurchaseFailureHandler
    let restoreStarted: RestoreStartedHandler
    let restoreFailure: PurchaseFailureHandler
    let requestedDismissal: (() -> Void)?

    let onSizeChange: (CGSize) -> Void

    var body: some View {
        PaywallView(configuration: self.configuration)
            .onPurchaseStarted(self.purchaseStarted)
            .onPurchaseCompleted(self.purchaseCompleted)
            .onPurchaseCancelled(self.purchaseCancelled)
            .onPurchaseFailure(self.purchaseFailure)
            .onRestoreStarted(self.restoreStarted)
            .onRestoreCompleted(self.restoreCompleted)
            .onRestoreFailure(self.restoreFailure)
            .onSizeChange(self.onSizeChange)
            .applyIfLet(self.requestedDismissal, apply: { view, requestedDismissal in
                view.onRequestedDismissal(requestedDismissal)
            })
    }

}

#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    @ViewBuilder func applyIf<Content: View>(_ condition: Bool, apply: (Self) -> Content) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    @ViewBuilder func applyIfLet<T, Content: View>(_ value: T?, apply: (Self, T) -> Content) -> some View {
        if let value = value {
            apply(self, value)
        } else {
            self
        }
    }
}

// swiftlint:enable file_length
