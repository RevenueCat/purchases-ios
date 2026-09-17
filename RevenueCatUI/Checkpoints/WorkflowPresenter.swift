//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPresenter.swift
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
final class WorkflowPresenter: NSObject, WorkflowPresenterType {

    typealias PresentationStarter = (WorkflowPresentationRequest) throws -> Bool
    typealias DismissalPerformer = (@escaping () -> Void) -> Void
    private typealias Continuation = CheckedContinuation<CheckpointPresentationOutcome, Error>

    enum PresentationUpdate {
        case outcome(CheckpointPresentationOutcome)
        case workflowPresentationError(NSError)
        case dismissalReason(WorkflowDismissalReason)
    }

    private struct PresentationState {
        var outcome: CheckpointPresentationOutcome = .completed(customerInfo: nil)
        var hasReportedOutcome = false
        var dismissalReason: WorkflowDismissalReason = .close

        mutating func record(_ update: PresentationUpdate) {
            switch update {
            case let .outcome(outcome):
                guard !self.outcome.hasCustomerInfo || outcome.hasCustomerInfo else { return }
                self.outcome = outcome
                self.hasReportedOutcome = true
            case let .workflowPresentationError(error):
                guard !self.hasReportedOutcome else { return }
                Logger.error(error.localizedDescription)
                self.outcome = .failed
                self.hasReportedOutcome = true
            case let .dismissalReason(reason):
                self.dismissalReason = reason
            }
        }
    }

    private let presentationStarter: PresentationStarter?
    private let dismissalPerformer: DismissalPerformer?
    private var presentationState: PresentationState?
    private var pendingContinuation: Continuation?

    private weak var presentedViewController: UIViewController?

    init(
        dismissalPerformer: DismissalPerformer? = nil,
        presentationStarter: PresentationStarter? = nil
    ) {
        self.presentationStarter = presentationStarter
        self.dismissalPerformer = dismissalPerformer
        super.init()
    }

    convenience init(
        presentationStarter: @escaping PresentationStarter
    ) {
        self.init(
            dismissalPerformer: nil,
            presentationStarter: presentationStarter
        )
    }

    func present(_ presentation: WorkflowPresentationRequest) async throws -> CheckpointPresentationOutcome {
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

    func startPresentation(_ presentation: WorkflowPresentationRequest) throws {
        guard self.presentationState == nil else {
            throw CheckpointError.operationAlreadyInProgress
        }
        self.presentationState = PresentationState()

        do {
            if let presentationStarter = self.presentationStarter {
                guard try presentationStarter(presentation) else {
                    throw CheckpointError.presentationFailed
                }
            } else {
                try self.presentAutomatically(presentation)
            }
        } catch {
            self.presentationState = nil
            self.presentedViewController = nil
            throw error
        }
    }

    func stage(_ update: PresentationUpdate) {
        self.presentationState?.record(update)
    }

    @discardableResult
    func presentationDidDismiss(reason: WorkflowDismissalReason? = nil) -> CheckpointPresentationOutcome? {
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
        self.presentationState = nil

        if let dismissalPerformer = self.dismissalPerformer {
            dismissalPerformer(completion)
            return
        }

        let viewController = self.presentedViewController
        self.presentedViewController = nil
        guard let viewController, viewController.presentingViewController != nil else {
            completion()
            return
        }
        viewController.dismiss(animated: true, completion: completion)
    }

    private func complete() -> CheckpointPresentationOutcome? {
        guard let state = self.takePresentationState() else { return nil }

        self.presentedViewController = nil

        let execution: CheckpointPresentationOutcome
        if state.dismissalReason == .navigatedBack, !state.outcome.hasCustomerInfo {
            execution = .backedOut
        } else {
            execution = state.outcome
        }
        self.finish(execution)
        return execution
    }

    private func finish(_ execution: CheckpointPresentationOutcome) {
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

    private func takePresentationState() -> PresentationState? {
        defer { self.presentationState = nil }
        return self.presentationState
    }

    private func handleDismissal(of controller: PaywallViewController) {
        self.stageDismissalReasonIfNeeded(controller.workflowDismissalReason)
        _ = self.presentationDidDismiss()
    }

    private func stageDismissalReasonIfNeeded(_ reason: WorkflowDismissalReason) {
        guard reason == .navigatedBack else { return }
        self.stage(.dismissalReason(reason))
    }

    private func presentAutomatically(_ presentation: WorkflowPresentationRequest) throws {
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
    }

    func makePaywallViewController(
        for presentation: WorkflowPresentationRequest
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
        viewController.disableExitOffers()
        viewController.customVariables = presentation.customVariables
        return viewController
    }

}

@available(iOS 15.0, macOS 12.0, *)
extension WorkflowPresenter {

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

    #endif

}

@available(iOS 15.0, macOS 12.0, *)
extension WorkflowPresenter: PaywallViewControllerDelegate {}

#else

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowPresenter: WorkflowPresenterType {

    func present(_ presentation: WorkflowPresentationRequest) async throws -> CheckpointPresentationOutcome {
        return .failed
    }

}

#endif
