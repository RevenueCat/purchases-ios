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
    private typealias Continuation = CheckedContinuation<CheckpointPresentationOutcome, Error>

    enum PresentationUpdate {
        case outcome(CheckpointPresentationOutcome)
        case recoverableErrorHandled
        case workflowPresentationError(NSError)
        case dismissalReason(WorkflowDismissalReason)
    }

    private enum WorkflowOutcomeState {
        case none
        case recoverableError
        case terminalError
        case reported(CheckpointPresentationOutcome)

        var outcome: CheckpointPresentationOutcome {
            switch self {
            case .none:
                return .completed(customerInfo: nil)
            case .recoverableError, .terminalError:
                return .failed
            case let .reported(outcome):
                return outcome
            }
        }

        var hasReportedOutcome: Bool {
            if case .none = self { return false }
            return true
        }
    }

    private struct PresentationState {
        let checkpointIdentifier: String
        let customVariables: [String: CustomVariableValue]
        let errorPresentationHandler: ErrorPresentationHandler
        let initialActiveEntitlementIdentifiers: Set<String>
        var outcomeState: WorkflowOutcomeState = .none
        var dismissalReason: WorkflowDismissalReason = .close

        mutating func record(_ update: PresentationUpdate) -> Bool {
            switch update {
            case let .outcome(outcome):
                guard !self.outcomeState.outcome.hasCustomerInfo || outcome.hasCustomerInfo else { return false }
                if case .failed = outcome {
                    guard case .terminalError = self.outcomeState else {
                        self.outcomeState = .recoverableError
                        return true
                    }
                    return false
                }
                self.outcomeState = .reported(outcome)
            case .recoverableErrorHandled:
                guard case .recoverableError = self.outcomeState else { return false }
                self.outcomeState = .none
            case let .workflowPresentationError(error):
                guard !self.outcomeState.hasReportedOutcome else { return false }
                Logger.error(error.localizedDescription)
                self.outcomeState = .terminalError
            case let .dismissalReason(reason):
                self.dismissalReason = reason
            }
            return true
        }
    }

    private struct ActiveErrorPresentation {
        let id: UUID
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

        return try await withCheckedThrowingContinuation { continuation in
            self.pendingContinuation = continuation
            do {
                try self.startPresentation(presentation)
            } catch {
                if case CheckpointError.presentationContextUnavailable = error {
                    Logger.warning(error.localizedDescription)
                } else {
                    Logger.error(error.localizedDescription)
                }
                self.finish(throwing: error)
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
                    throw CheckpointError.presentationContextUnavailable
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
        kind: CheckpointFailureKind,
        onCompletion: (@MainActor () -> Void)? = nil
    ) {
        guard let state = self.presentationState else { return }
        let presentation = ActiveErrorPresentation(id: UUID())
        self.activeErrorPresentation = presentation
        state.errorPresentationHandler(
            .init(
                checkpointIdentifier: state.checkpointIdentifier,
                error: error,
                customVariables: state.customVariables,
                kind: kind
            ),
            .init { [weak self] in
                self?.handleErrorPresentationResult(
                    presentationID: presentation.id,
                    onCompletion: onCompletion
                )
            }
        )
    }

    private func handleErrorPresentationResult(
        presentationID: UUID,
        onCompletion: (@MainActor () -> Void)?
    ) {
        guard self.activeErrorPresentation?.id == presentationID,
              self.presentationState != nil else { return }
        self.activeErrorPresentation = nil
        onCompletion?()
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
        if state.dismissalReason == .navigatedBack, !state.outcomeState.outcome.hasCustomerInfo {
            execution = .backedOut
        } else {
            execution = state.outcomeState.outcome
        }
        self.finish(execution)
        return execution
    }

    private func finish(_ execution: CheckpointPresentationOutcome) {
        guard let continuation = self.takePendingContinuation() else { return }
        continuation.resume(returning: execution)
    }

    private func finish(throwing error: any Error) {
        guard let continuation = self.takePendingContinuation() else { return }
        continuation.resume(throwing: error)
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
            throw CheckpointError.presentationContextUnavailable
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
            traceId: presentation.workflow.traceId,
            checkpointIdentifier: presentation.checkpointIdentifier
        )
        let viewController = PaywallViewController(
            workflowContext: workflowContext,
            displayCloseButton: true,
            workflowPresentationErrorHandler: { [weak self] error, behavior in
                guard let self else { return }
                switch behavior {
                case .endFlow:
                    guard self.stage(.workflowPresentationError(error)) else { return }
                    self.presentError(
                        error,
                        kind: .flowCouldNotBeShown,
                        onCompletion: { [weak self] in
                            self?.presentedViewController?.continueAfterCheckpointError()
                        }
                    )
                case .keepCurrentScreen:
                    Logger.error(error.localizedDescription)
                    self.presentError(error, kind: .flowActionFailed)
                }
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
            self.presentError(
                error,
                kind: .flowActionFailed,
                onCompletion: { [weak self] in self?.stage(.recoverableErrorHandled) }
            )
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        MainActor.assumeIsolated {
            Logger.error(error.localizedDescription)
            guard self.stage(.outcome(.failed)) else { return }
            self.presentError(
                error,
                kind: .flowActionFailed,
                onCompletion: { [weak self] in self?.stage(.recoverableErrorHandled) }
            )
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
        self.presentError(
            error,
            kind: .flowActionFailed,
            onCompletion: { [weak self] in self?.stage(.recoverableErrorHandled) }
        )
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        Logger.error(error.localizedDescription)
        guard self.stage(.outcome(.failed)) else { return }
        self.presentError(
            error,
            kind: .flowActionFailed,
            onCompletion: { [weak self] in self?.stage(.recoverableErrorHandled) }
        )
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
