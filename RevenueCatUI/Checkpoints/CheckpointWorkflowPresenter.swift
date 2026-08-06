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
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class CheckpointWorkflowPresenter: NSObject, CheckpointPresenter {

    typealias PresentationHandler = (PresentedWorkflow) throws -> Bool

    struct PresentedWorkflow: Identifiable {
        let id: String
        let workflow: ResolvedCheckpointWorkflow
        let delegate: CheckpointPresentationDelegate
    }

    private var activeCallID: String?
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
        callID: String,
        workflow: ResolvedCheckpointWorkflow,
        delegate: CheckpointPresentationDelegate
    ) {
        self.callStore.store(callID: callID, workflow: workflow, delegate: delegate)
        self.activeCallID = callID

        do {
            let presentedWorkflow = PresentedWorkflow(
                id: callID,
                workflow: workflow,
                delegate: delegate
            )

            let didBeginPresentation = try self.presentationHandler?(presentedWorkflow)
                ?? self.presentAutomatically(presentedWorkflow)
            guard didBeginPresentation else {
                throw CheckpointError.noPresentationContext
            }
        } catch {
            self.stage(
                outcome: CheckpointPaywallErrorOutcome(error: error as NSError),
                callID: callID
            )
            self.complete(callID: callID)
        }
    }

    func stage(outcome: CheckpointPaywallOutcome, callID: String? = nil) {
        guard let callID = callID ?? self.activeCallID else { return }
        self.callStore.stage(outcome: outcome, for: callID)
    }

    func presentationDidDismiss(callID: String? = nil) {
        guard let callID = callID ?? self.activeCallID else { return }
        self.complete(callID: callID)
    }

    private func complete(callID: String) {
        guard let call = self.callStore.remove(callID: callID) else { return }

        if self.activeCallID == callID {
            self.activeCallID = nil
            #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
            self.presentedViewController = nil
            #endif
        }

        call.delegate.checkpointPresentationFinished(
            callID: callID,
            outcome: call.stagedOutcome
        )
    }

    private func presentAutomatically(_ presentedWorkflow: PresentedWorkflow) throws -> Bool {
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        guard let presentationContext = UIApplication.extensionSafeApplication?.currentPresentationViewController else {
            return false
        }
        let offering = presentedWorkflow.workflow.offering

        let workflowContext = try WorkflowPreview.makeContext(
            workflow: presentedWorkflow.workflow.workflow,
            offerings: [offering],
            uiConfig: presentedWorkflow.workflow.uiConfig
        )
        let viewController = PaywallViewController(
            workflowContext: workflowContext,
            displayCloseButton: true
        )
        viewController.delegate = self
        self.presentedViewController = viewController
        presentationContext.present(viewController, animated: true)
        return true
        #else
        return false
        #endif
    }

}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, *)
extension CheckpointWorkflowPresenter: @preconcurrency PaywallViewControllerDelegate {

    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishPurchasingWith customerInfo: CustomerInfo
    ) {
        self.stage(outcome: CheckpointPaywallPurchasedOutcome(customerInfo: customerInfo))
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        self.stage(outcome: CheckpointPaywallRestoredOutcome(customerInfo: customerInfo))
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        self.stage(outcome: CheckpointPaywallErrorOutcome(error: error))
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        self.stage(outcome: CheckpointPaywallErrorOutcome(error: error))
    }

    func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        self.presentationDidDismiss()
    }

}

#endif
