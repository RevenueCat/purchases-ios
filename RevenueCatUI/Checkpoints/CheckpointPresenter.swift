//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresenter.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Owns and routes the single active checkpoint presentation.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointPresenter: CheckpointPresenterProtocol {

    private let workflowPresenter: WorkflowPresenterProtocol
    private let defaultPaywallPresenter: DefaultPaywallPresenterProtocol
    private let customerInfoSynchronizer: CheckpointsManager.CustomerInfoSynchronizer
    private let slot = CheckpointPresentationSlot()

    init(
        workflowPresenter: WorkflowPresenterProtocol,
        customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.workflowPresenter = workflowPresenter
        self.defaultPaywallPresenter = DefaultPaywallPresenter()
        self.customerInfoSynchronizer = customerInfoSynchronizer
    }

    init(
        workflowPresenter: WorkflowPresenterProtocol,
        defaultPaywallPresenter: DefaultPaywallPresenterProtocol,
        customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.workflowPresenter = workflowPresenter
        self.defaultPaywallPresenter = defaultPaywallPresenter
        self.customerInfoSynchronizer = customerInfoSynchronizer
    }

    func presentWorkflow(_ presentation: WorkflowPresentationRequest) async throws -> CheckpointPresentationOutcome {
        guard let token = self.slot.claim() else {
            throw CheckpointError.operationAlreadyInProgress
        }
        defer { self.slot.release(token) }
        return try await self.workflowPresenter.present(presentation)
    }

    func presentOffering(
        params: PaywallPresentationParams,
        globalPaywallPresenter: PaywallPresenter?,
        localPaywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointPresentationOutcome {
        guard let token = self.slot.claim() else {
            throw CheckpointError.operationAlreadyInProgress
        }
        defer { self.slot.release(token) }

        let presentationHandler: PaywallPresentationHandler
        let cancellationHandler: ((@escaping () -> Void) -> Void)?
        if let localPaywallPresentationHandler {
            presentationHandler = localPaywallPresentationHandler
            cancellationHandler = nil
        } else if let paywallPresenter = globalPaywallPresenter {
            presentationHandler = { params, completion in
                paywallPresenter.present(params: params, completion: completion)
            }
            cancellationHandler = nil
        } else {
            presentationHandler = { [defaultPaywallPresenter] params, completion in
                defaultPaywallPresenter.present(params: params, completion: completion)
            }
            cancellationHandler = { [defaultPaywallPresenter] completion in
                defaultPaywallPresenter.cancel(completion: completion)
            }
        }

        return try await OfferingPresentation(
            slot: self.slot,
            token: token,
            customerInfoSynchronizer: self.customerInfoSynchronizer,
            cancellationHandler: cancellationHandler
        ).present(
            params: params,
            presentationHandler: presentationHandler
        )
    }

    /// Bridges a paywall presenter's completion callback into the checkpoint lifecycle.
    @MainActor
    private final class OfferingPresentation {

        private let slot: CheckpointPresentationSlot
        private let token: CheckpointPresentationSlot.Token
        private let customerInfoSynchronizer: CheckpointsManager.CustomerInfoSynchronizer
        private let cancellationHandler: ((@escaping () -> Void) -> Void)?
        private var pendingContinuation: CheckedContinuation<
            CheckpointPresentationOutcome, Error
        >?
        private var hasReportedCompletion = false

        init(
            slot: CheckpointPresentationSlot,
            token: CheckpointPresentationSlot.Token,
            customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer,
            cancellationHandler: ((@escaping () -> Void) -> Void)?
        ) {
            self.slot = slot
            self.token = token
            self.customerInfoSynchronizer = customerInfoSynchronizer
            self.cancellationHandler = cancellationHandler
        }

        func present(
            params: PaywallPresentationParams,
            presentationHandler: PaywallPresentationHandler
        ) async throws -> CheckpointPresentationOutcome {
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
                    self?.cancel()
                }
            }
        }

        fileprivate func completed(_ result: PaywallPresentationResult) {
            guard self.slot.contains(self.token),
                  !self.hasReportedCompletion,
                  self.pendingContinuation != nil else { return }
            self.hasReportedCompletion = true
            self.slot.release(self.token)

            if result == .navigatedBack {
                self.complete(execution: .backedOut)
            } else {
                self.synchronizeCustomerInfo()
            }
        }

        private func cancel() {
            guard let cancellationHandler else {
                self.finishCancellation(force: true)
                return
            }
            cancellationHandler { [weak self] in
                self?.finishCancellation(force: true)
            }
        }

        private func synchronizeCustomerInfo() {
            Task { @MainActor [weak self] in
                guard let self else { return }

                do {
                    let customerInfo = try await self.customerInfoSynchronizer()
                    self.complete(execution: .completed(customerInfo: customerInfo))
                } catch {
                    Logger.error(error.localizedDescription)
                    self.complete(execution: .failed)
                }
            }
        }

        private func complete(execution: CheckpointPresentationOutcome) {
            guard let continuation = self.takeContinuation() else { return }
            continuation.resume(returning: execution)
        }

        private func finishCancellation(force: Bool = false) {
            guard self.pendingContinuation != nil,
                  force || !self.hasReportedCompletion else { return }
            self.hasReportedCompletion = true
            guard let continuation = self.takeContinuation() else { return }
            continuation.resume(throwing: CancellationError())
        }

        private func takeContinuation() -> CheckedContinuation<
            CheckpointPresentationOutcome, Error
        >? {
            defer { self.pendingContinuation = nil }
            return self.pendingContinuation
        }

    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol CheckpointPresenterProtocol: AnyObject {

    func presentWorkflow(_ presentation: WorkflowPresentationRequest) async throws -> CheckpointPresentationOutcome

    func presentOffering(
        params: PaywallPresentationParams,
        globalPaywallPresenter: PaywallPresenter?,
        localPaywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointPresentationOutcome

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol DefaultPaywallPresenterProtocol: PaywallPresenter {
    func cancel(completion: @escaping () -> Void)
}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

@MainActor
@available(iOS 15.0, macOS 12.0, *)
private final class DefaultPaywallPresenter: NSObject, DefaultPaywallPresenterProtocol, PaywallViewControllerDelegate {

    private var completion: PaywallPresentationCompletion?
    private weak var presentedViewController: PaywallViewController?

    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        guard let presentationContext = UIApplication.extensionSafeApplication?.currentPresentationViewController else {
            completion(.closed)
            return
        }
        guard self.completion == nil else {
            completion(.closed)
            return
        }

        let controller = PaywallViewController(offering: params.offering, displayCloseButton: true)
        controller.customVariables = params.customVariables
        controller.delegate = self
        self.completion = completion
        self.presentedViewController = controller
        presentationContext.present(controller, animated: true)
        if controller.presentingViewController == nil {
            self.completeAsClosed()
        }
    }

    func cancel(completion: @escaping () -> Void) {
        guard self.takeCompletion() != nil else {
            completion()
            return
        }
        guard let controller = self.presentedViewController else {
            completion()
            return
        }
        self.presentedViewController = nil
        controller.dismiss(animated: true, completion: completion)
    }

    private func finish(_ controller: PaywallViewController) {
        guard let completion = self.takeCompletion() else { return }
        self.presentedViewController = nil
        completion(controller.workflowDismissalReason == .navigatedBack ? .navigatedBack : .closed)
    }

    private func completeAsClosed() {
        guard let completion = self.takeCompletion() else { return }
        self.presentedViewController = nil
        completion(.closed)
    }

    private func takeCompletion() -> PaywallPresentationCompletion? {
        defer { self.completion = nil }
        return self.completion
    }

    nonisolated func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        MainActor.assumeIsolated { self.finish(controller) }
    }

}
#else
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class DefaultPaywallPresenter: DefaultPaywallPresenterProtocol {
    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        completion(.closed)
    }

    func cancel(completion: @escaping () -> Void) {
        completion()
    }
}
#endif
