//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowPresenter.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

/// Presents resolved checkpoint workflows using RevenueCatUI.
///
/// Purchase, restore, and error outcomes are staged as they occur and delivered
/// only after the presented UI has fully dismissed.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class CheckpointWorkflowPresenter: NSObject, CheckpointPresenter {

    typealias PresentationHandler = (CheckpointPresentation) throws -> Bool

    private let callStore: CheckpointCallStore
    private let presentationHandler: PresentationHandler?

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
    private weak var presentedViewController: UIViewController?
    #endif

    init(
        callStore: CheckpointCallStore? = nil,
        presentationHandler: PresentationHandler? = nil
    ) {
        self.callStore = callStore ?? CheckpointCallStore()
        self.presentationHandler = presentationHandler
        super.init()
    }

    func present(
        presentation: CheckpointPresentation,
        delegate: CheckpointPresentationDelegate
    ) throws {
        self.callStore.store(presentation: presentation, delegate: delegate)

        do {
            if let presentationHandler = self.presentationHandler {
                guard try presentationHandler(presentation) else {
                    throw CheckpointError.presentationFailed
                }
            } else {
                try self.presentAutomatically(presentation)
            }
        } catch {
            _ = self.callStore.remove()
            #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
            self.presentedViewController = nil
            #endif
            throw error
        }
    }

    func stage(_ update: CheckpointCallStore.OutcomeUpdate) {
        self.callStore.stage(update)
    }

    func presentationDidDismiss(reason: WorkflowDismissalReason = .close) {
        self.complete(reason: reason)
    }

    func dismiss(completion: @escaping () -> Void) {
        guard self.callStore.remove() != nil else {
            completion()
            return
        }

        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        let viewController = self.presentedViewController
        self.presentedViewController = nil
        guard let viewController, viewController.presentingViewController != nil else {
            completion()
            return
        }
        viewController.dismiss(animated: true, completion: completion)
        #else
        completion()
        #endif
    }

    private func complete(reason: WorkflowDismissalReason) {
        guard let call = self.callStore.remove() else { return }

        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        self.presentedViewController = nil
        #endif

        let execution: CheckpointExecution<CheckpointPaywallOutcome>
        switch (reason, call.stagedOutcome) {
        case (.navigatedBack, is CheckpointPaywallOutcome.Purchased),
             (.navigatedBack, is CheckpointPaywallOutcome.Restored):
            execution = .completed(call.stagedOutcome)
        case (.navigatedBack, _):
            execution = .backedOut(call.stagedOutcome)
        case (.close, _):
            execution = .completed(call.stagedOutcome)
        }
        call.delegate.checkpointPresentationFinished(execution)
    }

    private func presentAutomatically(_ presentation: CheckpointPresentation) throws {
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        guard let presentationContext = UIApplication.extensionSafeApplication?.currentPresentationViewController else {
            throw CheckpointError.noPresentationContext
        }
        let viewController = try self.makePaywallViewController(for: presentation)
        viewController.delegate = self
        self.presentedViewController = viewController
        presentationContext.present(viewController, animated: true)
        guard viewController.presentingViewController != nil else {
            throw CheckpointError.presentationFailed
        }
        #else
        throw CheckpointError.noPresentationContext
        #endif
    }

    func makePaywallViewController(
        for presentation: CheckpointPresentation
    ) throws -> PaywallViewController {
        let workflowContext = try WorkflowPreview.makeContext(
            workflow: presentation.workflow.workflow,
            offerings: presentation.workflow.offerings,
            uiConfig: presentation.workflow.uiConfig,
            workflowBlobRef: presentation.workflow.workflowBlobRef
        )
        let viewController = PaywallViewController(
            workflowContext: workflowContext,
            displayCloseButton: true,
            workflowPresentationErrorHandler: { [weak self] error in
                self?.stage(.workflowPresentationError(error))
            }
        )
        viewController.customVariables = presentation.customVariables
        return viewController
    }

}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, *)
extension CheckpointWorkflowPresenter {

    // `PaywallViewController` delivers these UI lifecycle and purchase callbacks
    // synchronously from main-actor-isolated UI paths.
    #if compiler(>=5.9)
    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFinishPurchasingWith customerInfo: CustomerInfo,
        transaction: StoreTransaction?
    ) {
        MainActor.assumeIsolated {
            self.stage(
                .outcome(CheckpointPaywallOutcome.Purchased(
                    transaction: transaction,
                    customerInfo: customerInfo
                ))
            )
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        MainActor.assumeIsolated {
            self.stage(.outcome(CheckpointPaywallOutcome.Restored(customerInfo: customerInfo)))
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        MainActor.assumeIsolated {
            self.stage(.outcome(CheckpointPaywallOutcome.Error(error: error)))
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        MainActor.assumeIsolated {
            self.stage(.outcome(CheckpointPaywallOutcome.Error(error: error)))
        }
    }

    nonisolated func paywallViewControllerDidOpenWebCheckout(_ controller: PaywallViewController) {
        MainActor.assumeIsolated {
            self.stage(.outcome(CheckpointPaywallOutcome.WebCheckoutOpened.shared))
        }
    }

    nonisolated func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        MainActor.assumeIsolated {
            self.presentationDidDismiss(reason: controller.workflowDismissalReason)
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        willPresentExitOfferController exitOfferController: PaywallViewController
    ) {
        MainActor.assumeIsolated {
            self.presentedViewController = exitOfferController
        }
    }
    #else
    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishPurchasingWith customerInfo: CustomerInfo,
        transaction: StoreTransaction?
    ) {
        self.stage(
            .outcome(CheckpointPaywallOutcome.Purchased(
                transaction: transaction,
                customerInfo: customerInfo
            ))
        )
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        self.stage(.outcome(CheckpointPaywallOutcome.Restored(customerInfo: customerInfo)))
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        self.stage(.outcome(CheckpointPaywallOutcome.Error(error: error)))
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        self.stage(.outcome(CheckpointPaywallOutcome.Error(error: error)))
    }

    func paywallViewControllerDidOpenWebCheckout(_ controller: PaywallViewController) {
        self.stage(.outcome(CheckpointPaywallOutcome.WebCheckoutOpened.shared))
    }

    func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        self.presentationDidDismiss(reason: controller.workflowDismissalReason)
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        willPresentExitOfferController exitOfferController: PaywallViewController
    ) {
        self.presentedViewController = exitOfferController
    }
    #endif

}

@available(iOS 15.0, macOS 12.0, *)
extension CheckpointWorkflowPresenter: PaywallViewControllerDelegate {}

#endif

#endif
