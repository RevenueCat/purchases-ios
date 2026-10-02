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

// swiftlint:disable file_length

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
    private typealias Continuation = CheckedContinuation<CheckpointPresentationOutcome, Never>

    enum PresentationUpdate {
        case outcome(CheckpointPresentationOutcome)
        case recoverableErrorHandled
        case workflowPresentationError(NSError)
        case dismissalReason(WorkflowDismissalReason)
    }

    private struct PresentationState {
        let checkpointIdentifier: String
        let customVariables: [String: CustomVariableValue]
        let errorPresentationHandler: ErrorPresentationHandler
        let initialActiveEntitlementIdentifiers: Set<String>?
        var outcome: CheckpointPresentationOutcome = .completed(customerInfo: nil)
        var hasReportedOutcome = false
        var dismissalReason: WorkflowDismissalReason = .close

        mutating func record(_ update: PresentationUpdate) -> Bool {
            switch update {
            case let .outcome(outcome):
                guard !self.outcome.hasCustomerInfo || outcome.hasCustomerInfo else { return false }
                self.outcome = outcome
                self.hasReportedOutcome = true
            case .recoverableErrorHandled:
                guard case .failed = self.outcome else { return false }
                self.outcome = .completed(customerInfo: nil)
                self.hasReportedOutcome = false
            case let .workflowPresentationError(error):
                guard !self.hasReportedOutcome else { return false }
                Logger.error(error.localizedDescription)
                self.outcome = .failed
                self.hasReportedOutcome = true
            case let .dismissalReason(reason):
                self.dismissalReason = reason
            }
            return true
        }
    }

    private struct ActiveErrorPresentation {
        let id: UUID
        let flowCanContinue: Bool
    }

    private let presentationStarter: PresentationStarter?
    private var presentationState: PresentationState?
    private var pendingContinuation: Continuation?
    private weak var presentedViewController: PaywallViewController?
    private var activeErrorPresentation: ActiveErrorPresentation?

    init(presentationStarter: PresentationStarter? = nil) {
        self.presentationStarter = presentationStarter
        super.init()
    }

    func present(_ presentation: WorkflowPresentationRequest) async throws -> CheckpointPresentationOutcome {
        guard self.pendingContinuation == nil else {
            throw CheckpointError.operationAlreadyInProgress
        }

        return await withCheckedContinuation { continuation in
            self.pendingContinuation = continuation
            do {
                try self.startPresentation(presentation)
            } catch {
                Logger.error(error.localizedDescription)
                self.finish(.failed)
            }
        }
    }

    func startPresentation(_ presentation: WorkflowPresentationRequest) throws {
        guard self.presentationState == nil else {
            throw CheckpointError.operationAlreadyInProgress
        }
        self.presentationState = PresentationState(
            checkpointIdentifier: presentation.checkpointIdentifier,
            customVariables: presentation.customVariables,
            errorPresentationHandler: presentation.errorPresentationHandler,
            initialActiveEntitlementIdentifiers: presentation.initialActiveEntitlementIdentifiers
        )

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

    @discardableResult
    func stage(_ update: PresentationUpdate) -> Bool {
        return self.presentationState?.record(update) == true
    }

    private func presentError(
        _ error: any Error,
        flowCanContinue: Bool,
        controller: PaywallViewController? = nil
    ) {
        guard let state = self.presentationState else { return }
        if flowCanContinue, self.activeErrorPresentation?.flowCanContinue == false {
            return
        }
        let presentation = ActiveErrorPresentation(id: UUID(), flowCanContinue: flowCanContinue)
        self.activeErrorPresentation = presentation
        let controller = controller ?? self.presentedViewController
        state.errorPresentationHandler(
            .init(
                checkpointIdentifier: state.checkpointIdentifier,
                error: error,
                customVariables: state.customVariables,
                flowCanContinue: flowCanContinue
            ),
            .init { [weak self, weak controller] result in
                self?.handleErrorPresentationResult(
                    result,
                    flowCanContinue: flowCanContinue,
                    presentationID: presentation.id,
                    controller: controller
                )
            }
        )
    }

    private func handleErrorPresentationResult(
        _ result: ErrorPresentationCompletion.Result,
        flowCanContinue: Bool,
        presentationID: UUID,
        controller: PaywallViewController?
    ) {
        guard self.activeErrorPresentation?.id == presentationID,
              self.presentationState != nil else { return }
        self.activeErrorPresentation = nil

        switch result.action {
        case .retry where flowCanContinue:
            self.stage(.recoverableErrorHandled)
        case .retry, .continue:
            self.stage(.outcome(.completed(customerInfo: nil)))
            controller?.continueAfterCheckpointError()
        case .navigateBack where flowCanContinue:
            self.stage(.recoverableErrorHandled)
            controller?.navigateBackAfterCheckpointError(flowCanContinue: true)
        case .navigateBack:
            self.stage(.outcome(.completed(customerInfo: nil)))
            controller?.navigateBackAfterCheckpointError(flowCanContinue: flowCanContinue)
        }
    }

    @discardableResult
    func presentationDidDismiss(reason: WorkflowDismissalReason? = nil) -> CheckpointPresentationOutcome? {
        if let reason {
            self.stage(.dismissalReason(reason))
        }
        return self.complete()
    }

    private func complete() -> CheckpointPresentationOutcome? {
        guard let state = self.takePresentationState() else { return nil }

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

    private func takePendingContinuation() -> Continuation? {
        defer { self.pendingContinuation = nil }
        return self.pendingContinuation
    }

    private func takePresentationState() -> PresentationState? {
        defer { self.presentationState = nil }
        self.activeErrorPresentation = nil
        self.presentedViewController = nil
        return self.presentationState
    }

    private func handleDismissal(of controller: PaywallViewController) {
        self.stageDismissalReasonIfNeeded(controller.workflowDismissalReason)
        _ = self.presentationDidDismiss()
    }

    private func didCompleteRestore(customerInfo: CustomerInfo) {
        guard customerInfo.grantsNewEntitlements(
            comparedTo: self.presentationState?.initialActiveEntitlementIdentifiers
        ) else { return }

        self.stage(.outcome(.completed(customerInfo: customerInfo)))
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
        viewController.modalPresentationStyle = presentation.presentationMode.modalPresentationStyle
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
            workflowBlobRef: presentation.workflow.workflowBlobRef,
            traceId: presentation.workflow.traceId
        )
        let viewController = PaywallViewController(
            workflowContext: workflowContext,
            displayCloseButton: true,
            workflowPresentationErrorHandler: { [weak self] error in
                guard let self, self.stage(.workflowPresentationError(error)) else { return }
                self.presentError(error, flowCanContinue: false)
            }
        )
        self.presentedViewController = viewController
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
            self.activeErrorPresentation = nil
            self.stage(.outcome(.completed(customerInfo: customerInfo)))
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        MainActor.assumeIsolated {
            self.activeErrorPresentation = nil
            self.didCompleteRestore(customerInfo: customerInfo)
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        MainActor.assumeIsolated {
            guard !error.isPurchaseCancellation else { return }
            Logger.error(error.localizedDescription)
            guard self.stage(.outcome(.failed)) else { return }
            self.presentError(error, flowCanContinue: true, controller: controller)
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        MainActor.assumeIsolated {
            Logger.error(error.localizedDescription)
            guard self.stage(.outcome(.failed)) else { return }
            self.presentError(error, flowCanContinue: true, controller: controller)
        }
    }

    nonisolated func paywallViewControllerDidOpenWebCheckout(_ controller: PaywallViewController) {
        MainActor.assumeIsolated {
            self.activeErrorPresentation = nil
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
        self.activeErrorPresentation = nil
        self.stage(.outcome(.completed(customerInfo: customerInfo)))
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        self.activeErrorPresentation = nil
        self.didCompleteRestore(customerInfo: customerInfo)
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        guard !error.isPurchaseCancellation else { return }
        Logger.error(error.localizedDescription)
        guard self.stage(.outcome(.failed)) else { return }
        self.presentError(error, flowCanContinue: true, controller: controller)
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        Logger.error(error.localizedDescription)
        guard self.stage(.outcome(.failed)) else { return }
        self.presentError(error, flowCanContinue: true, controller: controller)
    }

    func paywallViewControllerDidOpenWebCheckout(_ controller: PaywallViewController) {
        self.activeErrorPresentation = nil
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
