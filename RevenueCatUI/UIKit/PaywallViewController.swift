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
/// ## Exit Offer Support
///
/// This view controller sets itself as the `presentationController?.delegate` to intercept
/// swipe-to-dismiss gestures for exit offer support. When an exit offer is available and the user
/// attempts to dismiss without purchasing, the exit offer paywall will be presented instead.
///
/// Exit offers take priority over any existing presentation controller delegate. If you have an
/// existing delegate, it will be preserved and delegate methods will be forwarded to it only when
/// exit offers are not being handled.
///
/// - Important: If you need to set a custom `presentationController?.delegate` in a subclass,
///   do so **before** calling `super.viewWillAppear(_:)`. This ensures your delegate is captured
///   and forwarded. Setting it afterwards will override the exit offer handling, potentially
///   breaking exit offer support.
///
/// - Seealso: ``PaywallView`` for `SwiftUI`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallViewController)
// swiftlint:disable:next type_body_length
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

    // MARK: - Exit Offer State

    /// The prefetched exit offer, loaded while the main paywall is showing.
    private var exitOfferOffering: Offering?

    /// Whether we're currently showing an exit offer (to prevent multiple presentations).
    private var isShowingExitOffer: Bool = false

    /// Whether we're dismissing to show an exit offer (skip dismissal notification).
    private var isDismissingForExitOffer: Bool = false

    /// The original presentation controller delegate, if one was set before we took over.
    /// We forward all delegate calls to this after handling our exit offer logic.
    private weak var originalPresentationControllerDelegate: UIAdaptivePresentationControllerDelegate?

    private var purchaseHandler: PurchaseHandler {
        return configuration.purchaseHandler
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

        // Prefetch exit offer
        Task { @MainActor in
            await self.prefetchExitOffer()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set ourselves as the presentation controller delegate to intercept swipe-to-dismiss
        // for exit offer support. We store any existing delegate to forward calls to it.
        self.originalPresentationControllerDelegate = self.presentationController?.delegate
        self.presentationController?.delegate = self
    }

    public override func viewDidDisappear(_ animated: Bool) {
        if self.isBeingDismissed && !self.isDismissingForExitOffer {
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

    // MARK: - Exit Offer Handling

    /// Prefetches the exit offer for the current offering.
    @MainActor
    private func prefetchExitOffer() async {
        guard let offering = await self.configuration.content.resolveOffering() else {
            return
        }
        self.exitOfferOffering = await ExitOfferHelper.fetchValidExitOffer(for: offering)
    }

    /// Handles dismissal requests, checking for exit offers before calling the original handler.
    private func handleDismissalRequest() {
        // If purchased, dismiss immediately without showing exit offer
        guard !self.purchaseHandler.hasPurchasedInSession else {
            self.purchaseHandler.resetForNewSession()
            self.dismissPaywall()
            return
        }

        // Show exit offer if available
        if let exitOffering = self.exitOfferOffering, !self.isShowingExitOffer {
            self.presentExitOffer(for: exitOffering)
        } else {
            self.purchaseHandler.resetForNewSession()
            self.dismissPaywall()
        }
    }

    /// Dismisses the paywall, either via the handler or directly.
    private func dismissPaywall() {
        if let handler = self.dismissRequestedHandler {
            handler(self)
        } else {
            self.dismiss(animated: true)
        }
    }

    /// Presents the exit offer paywall as a sheet.
    private func presentExitOffer(for offering: Offering) {
        Logger.debug(Strings.presentingExitOffer(offering.identifier))

        self.isShowingExitOffer = true

        // Capture the presenting view controller and other needed state before dismissing
        guard let presenter = self.presentingViewController else {
            // No presenter, just dismiss normally
            self.purchaseHandler.resetForNewSession()
            self.dismissPaywall()
            return
        }

        // Capture state we need after self is dismissed
        let originalDelegate = self.delegate
        let originalDismissHandler = self.dismissRequestedHandler
        let fonts = self.configuration.fonts
        let shouldBlock = self.shouldBlockTouchEvents

        // Mark that we're dismissing to show exit offer (skip dismissal notification)
        self.isDismissingForExitOffer = true

        // Dismiss the main paywall first
        self.dismiss(animated: true) { [weak self, weak presenter] in
            guard let self = self, let presenter = presenter else { return }

            let exitOfferVC = PaywallViewController(
                offering: offering,
                fonts: fonts,
                displayCloseButton: true,
                shouldBlockTouchEvents: shouldBlock,
                dismissRequestedHandler: { controller in
                    // When exit offer is dismissed, call the original handler
                    if let handler = originalDismissHandler {
                        handler(controller)
                    } else {
                        controller.dismiss(animated: true)
                    }
                }
            )

            // Set delegate directly - exit offer is now standalone
            exitOfferVC.delegate = originalDelegate

            // Notify delegate about exit offer so it can associate result tracking
            originalDelegate?.paywallViewController?(self, willPresentExitOfferController: exitOfferVC)

            presenter.present(exitOfferVC, animated: true)
        }
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

// MARK: - UIAdaptivePresentationControllerDelegate
//
// PaywallViewController sets itself as the presentationController's delegate in viewWillAppear
// to intercept swipe-to-dismiss gestures for exit offer support. Any existing delegate is stored
// and calls are forwarded to it when we're not handling exit offers.
//
// Note on `presentationControllerShouldDismiss`:
// - Exit offers have priority. If an exit offer is available (and no purchase happened), we
//   return `false` to block the swipe dismiss. This triggers `presentationControllerDidAttemptToDismiss`,
//   where we present the exit offer paywall.
// - If no exit offer, we check if the original delegate wants to block dismiss and respect that.

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension PaywallViewController: UIAdaptivePresentationControllerDelegate {

    // swiftlint:disable:next missing_docs
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Exit offer has priority - block dismiss to show exit offer if available and no purchase happened.
        // This will trigger `presentationControllerDidAttemptToDismiss` where we present the exit offer.
        if self.exitOfferOffering != nil && !self.purchaseHandler.hasPurchasedInSession {
            return false
        }

        // Check if original delegate wants to block dismiss - if so, respect that
        let originalDelegateShouldDismiss = self.originalPresentationControllerDelegate?
            .presentationControllerShouldDismiss?(presentationController)
        if originalDelegateShouldDismiss == false {
            return false
        }

        return true
    }

    // swiftlint:disable:next missing_docs
    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        // Exit offer has priority - if we blocked for exit offer, handle it ourselves
        if self.exitOfferOffering != nil && !self.purchaseHandler.hasPurchasedInSession {
            self.handleDismissalRequest()
        } else {
            // Original delegate blocked - let them handle it
            self.originalPresentationControllerDelegate?
                .presentationControllerDidAttemptToDismiss?(presentationController)
        }
    }

    // swiftlint:disable:next missing_docs
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        // Dismissal is happening (we allowed it) - clean up
        self.purchaseHandler.resetForNewSession()

        // Forward to original delegate
        self.originalPresentationControllerDelegate?.presentationControllerWillDismiss?(presentationController)
    }

    // swiftlint:disable:next missing_docs
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Forward to original delegate
        self.originalPresentationControllerDelegate?.presentationControllerDidDismiss?(presentationController)
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

    /// Notifies that an exit offer paywall is about to be presented.
    /// - Parameters:
    ///   - controller: The original ``PaywallViewController`` that was dismissed.
    ///   - exitOfferController: The new ``PaywallViewController`` that will present the exit offer.
    /// - Note: This is called after the original controller is dismissed and before the exit offer is presented.
    ///         Use this to associate the exit offer controller with the original controller for result tracking.
    @objc(paywallViewController:willPresentExitOfferController:)
    optional func paywallViewController(_ controller: PaywallViewController,
                                        willPresentExitOfferController exitOfferController: PaywallViewController)

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewController {

    func createHostingController() -> UIHostingController<PaywallContainerView> {
        // Always route close button through exit offer handling
        let onRequestedDismissal: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.handleDismissalRequest()
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
    let requestedDismissal: () -> Void

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
            .onRequestedDismissal(self.requestedDismissal)
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
