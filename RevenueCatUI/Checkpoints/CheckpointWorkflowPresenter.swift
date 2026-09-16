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
final class CheckpointWorkflowPresenter: NSObject, CheckpointWorkflowPresenterProtocol {

    typealias PresentationHandler = (CheckpointPresentation) throws -> Bool
    typealias DismissalHandler = (@escaping () -> Void) -> Void
    private typealias Continuation = CheckedContinuation<CheckpointExecution, Error>

    private let callStore: CheckpointCallStore
    private let presentationHandler: PresentationHandler?
    private let dismissalHandler: DismissalHandler?
    private var pendingContinuation: Continuation?

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
    private weak var presentedViewController: UIViewController?
    #endif

    init(
        callStore: CheckpointCallStore? = nil,
        dismissalHandler: DismissalHandler? = nil,
        presentationHandler: PresentationHandler? = nil
    ) {
        self.callStore = callStore ?? CheckpointCallStore()
        self.presentationHandler = presentationHandler
        self.dismissalHandler = dismissalHandler
        super.init()
    }

    convenience init(
        callStore: CheckpointCallStore? = nil,
        presentationHandler: @escaping PresentationHandler
    ) {
        self.init(
            callStore: callStore,
            dismissalHandler: nil,
            presentationHandler: presentationHandler
        )
    }

    func present(_ presentation: CheckpointPresentation) async throws -> CheckpointExecution {
        guard self.pendingContinuation == nil else {
            throw CheckpointError.operationAlreadyInProgress
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                self.pendingContinuation = continuation
                do {
                    try self.startPresentation(presentation)
                } catch {
                    Logger.error(error.localizedDescription)
                    self.finish(.failed)
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancel()
            }
        }
    }

    func startPresentation(_ presentation: CheckpointPresentation) throws {
        guard self.callStore.call == nil else {
            throw CheckpointError.operationAlreadyInProgress
        }
        self.callStore.store(presentation: presentation)

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
            self.presentedViewController = nil
            throw error
        }
    }

    func stage(_ update: CheckpointCallStore.CallUpdate) {
        self.callStore.stage(update)
    }

    @discardableResult
    func presentationDidDismiss(reason: WorkflowDismissalReason? = nil) -> CheckpointExecution? {
        if let reason {
            self.stage(.dismissalReason(reason))
        }
        return self.complete()
    }

    func cancel() {
        guard self.pendingContinuation != nil else { return }
        self.dismiss { [weak self] in
            self?.finishCancellation()
        }
    }

    func dismiss(completion: @escaping () -> Void) {
        _ = self.callStore.remove()

        if let dismissalHandler = self.dismissalHandler {
            dismissalHandler(completion)
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

    private func complete() -> CheckpointExecution? {
        guard let call = self.callStore.remove() else { return nil }

        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        self.presentedViewController = nil
        #endif

        let execution: CheckpointExecution = if call.dismissalReason == .navigatedBack,
                                                !call.stagedOutcome.hasCustomerInfo {
            .backedOut
        } else {
            call.stagedOutcome
        }
        self.finish(execution)
        return execution
    }

    private func finish(_ execution: CheckpointExecution) {
        guard let continuation = self.takePendingContinuation() else { return }
        continuation.resume(returning: execution)
    }

    private func finishCancellation() {
        guard let continuation = self.takePendingContinuation() else { return }
        continuation.resume(throwing: CancellationError())
    }

    private func takePendingContinuation() -> Continuation? {
        defer { self.pendingContinuation = nil }
        return self.pendingContinuation
    }

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
    private func handleDismissal(of controller: PaywallViewController) {
        self.stageDismissalReasonIfNeeded(controller.workflowDismissalReason)
        _ = self.presentationDidDismiss()
    }

    private func handleExitOfferPresentation(
        from controller: PaywallViewController,
        exitOfferController: PaywallViewController
    ) {
        self.stageDismissalReasonIfNeeded(controller.workflowDismissalReason)
        self.presentedViewController = exitOfferController
    }

    private func stageDismissalReasonIfNeeded(_ reason: WorkflowDismissalReason) {
        guard reason == .navigatedBack else { return }
        self.stage(.dismissalReason(reason))
    }
    #endif

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
            self.stage(.outcome(.completed(customerInfo: customerInfo)))
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        MainActor.assumeIsolated {
            self.stage(.outcome(.completed(customerInfo: customerInfo)))
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        MainActor.assumeIsolated {
            Logger.error(error.localizedDescription)
            self.stage(.outcome(.failed))
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        MainActor.assumeIsolated {
            Logger.error(error.localizedDescription)
            self.stage(.outcome(.failed))
        }
    }

    nonisolated func paywallViewControllerDidOpenWebCheckout(_ controller: PaywallViewController) {
        MainActor.assumeIsolated {
            self.stage(.outcome(.completed(customerInfo: nil)))
        }
    }

    nonisolated func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        MainActor.assumeIsolated {
            self.handleDismissal(of: controller)
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        willPresentExitOfferController exitOfferController: PaywallViewController
    ) {
        MainActor.assumeIsolated {
            self.handleExitOfferPresentation(from: controller, exitOfferController: exitOfferController)
        }
    }
    #else
    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishPurchasingWith customerInfo: CustomerInfo,
        transaction: StoreTransaction?
    ) {
        self.stage(.outcome(.completed(customerInfo: customerInfo)))
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        self.stage(.outcome(.completed(customerInfo: customerInfo)))
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        Logger.error(error.localizedDescription)
        self.stage(.outcome(.failed))
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        Logger.error(error.localizedDescription)
        self.stage(.outcome(.failed))
    }

    func paywallViewControllerDidOpenWebCheckout(_ controller: PaywallViewController) {
        self.stage(.outcome(.completed(customerInfo: nil)))
    }

    func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        self.handleDismissal(of: controller)
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        willPresentExitOfferController exitOfferController: PaywallViewController
    ) {
        self.handleExitOfferPresentation(from: controller, exitOfferController: exitOfferController)
    }
    #endif

}

@available(iOS 15.0, macOS 12.0, *)
extension CheckpointWorkflowPresenter: PaywallViewControllerDelegate {}

#endif

#else

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointWorkflowPresenter: CheckpointWorkflowPresenterProtocol {

    func present(_ presentation: CheckpointPresentation) async throws -> CheckpointExecution {
        return .failed
    }

}

#endif
