//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultCheckpointPresentationHandler.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Routes checkpoint presentations to a custom presenter or RevenueCat's default presenter.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class DefaultCheckpointPresentationHandler: CheckpointPresentationHandler {

    private let executor: CheckpointExecutor
    private let defaultPaywallPresenter: DefaultPaywallPresenting
    var paywallPresenter: PaywallPresenter?

    init(executor: CheckpointExecutor) {
        self.executor = executor
        self.defaultPaywallPresenter = DefaultPaywallPresenter()
    }

    init(
        executor: CheckpointExecutor,
        defaultPaywallPresenter: DefaultPaywallPresenting
    ) {
        self.executor = executor
        self.defaultPaywallPresenter = defaultPaywallPresenter
    }

    func presentWorkflow(
        _ presentation: CheckpointPresentation,
        session: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointExecutionResult<CheckpointPaywallOutcome> {
        session.setCancellationHandler { [weak self] in
            self?.executor.cancel()
        }
        return try await self.executor.execute(presentation)
    }

    func presentOffering(
        params: PaywallPresentationParams,
        session: CheckpointPresentationCoordinator.Session,
        paywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointExecutionResult<CheckpointPaywallOutcome> {
        guard let paywallPresentationHandler else {
            return try await self.defaultPaywallPresenter.present(params: params, session: session)
        }
        return try await OfferingPresentation(session: session).present(
            params: params,
            presentationHandler: paywallPresentationHandler
        )
    }

    /// Bridges the custom presenter's completion callback into the checkpoint lifecycle.
    @MainActor
    private final class OfferingPresentation {

        private let session: CheckpointPresentationCoordinator.Session
        private var pendingContinuation: CheckedContinuation<
            CheckpointExecutionResult<CheckpointPaywallOutcome>, Error
        >?
        private var hasReportedCompletion = false

        init(session: CheckpointPresentationCoordinator.Session) {
            self.session = session
        }

        func present(
            params: PaywallPresentationParams,
            presentationHandler: PaywallPresentationHandler
        ) async throws -> CheckpointExecutionResult<CheckpointPaywallOutcome> {
            self.session.setCancellationHandler { [weak self] in
                self?.fail(error: CancellationError(), force: true)
            }
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    guard !Task.isCancelled else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }

                    self.pendingContinuation = continuation
                    presentationHandler(params) { [weak self] result in
                        self?.completed(result)
                    }
                }
            } onCancel: {
                Task { @MainActor [weak self] in
                    self?.fail(error: CancellationError(), force: true)
                }
            }
        }

        fileprivate func completed(_ result: PaywallPresentationResult) {
            guard self.session.isActive,
                  !self.hasReportedCompletion,
                  self.pendingContinuation != nil else { return }
            self.hasReportedCompletion = true

            if let purchaseResult = result.purchaseResult {
                self.complete(execution: .completed(CheckpointPaywallOutcome.Purchased(
                    transaction: purchaseResult.transaction,
                    customerInfo: purchaseResult.customerInfo
                )))
            } else if result === PaywallPresentationResult.navigatedBack {
                self.complete(execution: .backedOut(CheckpointPaywallOutcome.Dismissed.shared))
            } else {
                self.complete(execution: .completed(CheckpointPaywallOutcome.Dismissed.shared))
            }
        }

        private func complete(execution: CheckpointExecutionResult<CheckpointPaywallOutcome>) {
            guard self.session.isActive,
                  let continuation = self.takeContinuation() else { return }
            continuation.resume(returning: execution)
        }

        private func fail(error: Error, force: Bool = false) {
            guard self.pendingContinuation != nil,
                  force || !self.hasReportedCompletion else { return }
            self.hasReportedCompletion = true
            guard self.session.isActive,
                  let continuation = self.takeContinuation() else { return }
            continuation.resume(throwing: error)
        }

        private func takeContinuation() -> CheckedContinuation<
            CheckpointExecutionResult<CheckpointPaywallOutcome>, Error
        >? {
            defer { self.pendingContinuation = nil }
            return self.pendingContinuation
        }

    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol DefaultPaywallPresenting: AnyObject {
    func present(
        params: PaywallPresentationParams,
        session: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointExecutionResult<CheckpointPaywallOutcome>
}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

@MainActor
@available(iOS 15.0, macOS 12.0, *)
private final class DefaultPaywallPresenter: NSObject, DefaultPaywallPresenting, PaywallViewControllerDelegate {

    private typealias Continuation = CheckedContinuation<CheckpointExecutionResult<CheckpointPaywallOutcome>, Error>

    private var continuation: Continuation?
    private weak var presentedViewController: PaywallViewController?
    private var outcome: CheckpointPaywallOutcome = CheckpointPaywallOutcome.Dismissed.shared

    func present(
        params: PaywallPresentationParams,
        session: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointExecutionResult<CheckpointPaywallOutcome> {
        guard let presentationContext = UIApplication.extensionSafeApplication?.currentPresentationViewController else {
            throw CheckpointError.noPresentationContext
        }
        guard self.continuation == nil else {
            throw CheckpointError.operationAlreadyInProgress
        }

        let controller = PaywallViewController(offering: params.offering, displayCloseButton: true)
        controller.customVariables = params.customVariables
        controller.delegate = self
        self.presentedViewController = controller
        self.outcome = CheckpointPaywallOutcome.Dismissed.shared
        session.setCancellationHandler { [weak self] in self?.cancel() }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            presentationContext.present(controller, animated: true)
            if controller.presentingViewController == nil {
                self.fail(CheckpointError.presentationFailed)
            }
        }
    }

    private func cancel() {
        guard let continuation = self.takeContinuation() else { return }
        guard let controller = self.presentedViewController else {
            continuation.resume(throwing: CancellationError())
            return
        }
        self.presentedViewController = nil
        controller.dismiss(animated: true) {
            continuation.resume(throwing: CancellationError())
        }
    }

    private func finish() {
        guard let continuation = self.takeContinuation() else { return }
        self.presentedViewController = nil
        continuation.resume(returning: .completed(self.outcome))
    }

    private func fail(_ error: Error) {
        guard let continuation = self.takeContinuation() else { return }
        self.presentedViewController = nil
        continuation.resume(throwing: error)
    }

    private func takeContinuation() -> Continuation? {
        defer { self.continuation = nil }
        return self.continuation
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFinishPurchasingWith customerInfo: CustomerInfo,
        transaction: StoreTransaction?
    ) {
        MainActor.assumeIsolated {
            self.outcome = CheckpointPaywallOutcome.Purchased(transaction: transaction, customerInfo: customerInfo)
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        MainActor.assumeIsolated {
            self.outcome = CheckpointPaywallOutcome.Restored(customerInfo: customerInfo)
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        MainActor.assumeIsolated { self.outcome = CheckpointPaywallOutcome.Error(error: error) }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        MainActor.assumeIsolated { self.outcome = CheckpointPaywallOutcome.Error(error: error) }
    }

    nonisolated func paywallViewControllerDidOpenWebCheckout(_ controller: PaywallViewController) {
        MainActor.assumeIsolated { self.outcome = CheckpointPaywallOutcome.WebCheckoutOpened.shared }
    }

    nonisolated func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        MainActor.assumeIsolated { self.finish() }
    }

}
#else
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class DefaultPaywallPresenter: DefaultPaywallPresenting {
    func present(
        params: PaywallPresentationParams,
        session: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointExecutionResult<CheckpointPaywallOutcome> {
        throw CheckpointError.missingPresenter
    }
}
#endif
