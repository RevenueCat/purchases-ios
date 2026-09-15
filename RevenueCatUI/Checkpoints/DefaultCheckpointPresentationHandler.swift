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
    private let customerInfoSynchronizer: CheckpointsManager.CustomerInfoSynchronizer
    var paywallPresenter: PaywallPresenter?

    init(
        executor: CheckpointExecutor,
        customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.executor = executor
        self.defaultPaywallPresenter = DefaultPaywallPresenter()
        self.customerInfoSynchronizer = customerInfoSynchronizer
    }

    init(
        executor: CheckpointExecutor,
        defaultPaywallPresenter: DefaultPaywallPresenting,
        customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.executor = executor
        self.defaultPaywallPresenter = defaultPaywallPresenter
        self.customerInfoSynchronizer = customerInfoSynchronizer
    }

    func presentWorkflow(
        _ presentation: CheckpointPresentation,
        session: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointExecution {
        session.setCancellationHandler { [weak self] in
            self?.executor.cancel()
        }
        return try await self.executor.execute(presentation)
    }

    func presentOffering(
        params: PaywallPresentationParams,
        session: CheckpointPresentationCoordinator.Session,
        paywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointExecution {
        guard let paywallPresentationHandler else {
            return try await self.defaultPaywallPresenter.present(params: params, session: session)
        }
        return try await OfferingPresentation(
            session: session,
            customerInfoSynchronizer: self.customerInfoSynchronizer
        ).present(
            params: params,
            presentationHandler: paywallPresentationHandler
        )
    }

    /// Bridges the custom presenter's completion callback into the checkpoint lifecycle.
    @MainActor
    private final class OfferingPresentation {

        private let session: CheckpointPresentationCoordinator.Session
        private let customerInfoSynchronizer: CheckpointsManager.CustomerInfoSynchronizer
        private var pendingContinuation: CheckedContinuation<
            CheckpointExecution, Error
        >?
        private var hasReportedCompletion = false

        init(
            session: CheckpointPresentationCoordinator.Session,
            customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer
        ) {
            self.session = session
            self.customerInfoSynchronizer = customerInfoSynchronizer
        }

        func present(
            params: PaywallPresentationParams,
            presentationHandler: PaywallPresentationHandler
        ) async throws -> CheckpointExecution {
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

            switch result.kind {
            case .navigatedBack:
                self.complete(execution: .backedOut(.dismissed))
            case .purchased, .closed, .continued:
                self.synchronizeCustomerInfo()
            }
        }

        private func synchronizeCustomerInfo() {
            Task { @MainActor [weak self] in
                guard let self else { return }

                do {
                    let customerInfo = try await self.customerInfoSynchronizer()
                    self.complete(execution: .completed(.finished(customerInfo: customerInfo)))
                } catch {
                    self.complete(execution: .completed(.error(error as NSError)))
                }
            }
        }

        private func complete(execution: CheckpointExecution) {
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
            CheckpointExecution, Error
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
    ) async throws -> CheckpointExecution
}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

@MainActor
@available(iOS 15.0, macOS 12.0, *)
private final class DefaultPaywallPresenter: NSObject, DefaultPaywallPresenting, PaywallViewControllerDelegate {

    private typealias Continuation = CheckedContinuation<CheckpointExecution, Error>

    private var continuation: Continuation?
    private weak var presentedViewController: PaywallViewController?
    private var outcome: CheckpointFlowOutcome = .dismissed

    func present(
        params: PaywallPresentationParams,
        session: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointExecution {
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
        self.outcome = .dismissed
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
            self.outcome = .purchased(transaction: transaction, customerInfo: customerInfo)
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        MainActor.assumeIsolated {
            self.outcome = .restored(customerInfo: customerInfo)
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        MainActor.assumeIsolated { self.outcome = .error(error) }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        MainActor.assumeIsolated { self.outcome = .error(error) }
    }

    nonisolated func paywallViewControllerDidOpenWebCheckout(_ controller: PaywallViewController) {
        MainActor.assumeIsolated { self.outcome = .webCheckoutOpened }
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
    ) async throws -> CheckpointExecution {
        throw CheckpointError.missingPresenter
    }
}
#endif
