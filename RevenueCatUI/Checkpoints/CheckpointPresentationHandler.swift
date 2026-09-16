//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresentationHandler.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Routes checkpoint presentations to a custom presenter or RevenueCat's default presenter.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointPresentationHandler: CheckpointPresentationHandlerProtocol {

    private let workflowPresenter: CheckpointWorkflowPresenterProtocol
    private let defaultPaywallPresenter: DefaultPaywallPresenterProtocol
    private let customerInfoSynchronizer: CheckpointsManager.CustomerInfoSynchronizer
    var paywallPresenter: PaywallPresenter?

    init(
        workflowPresenter: CheckpointWorkflowPresenterProtocol,
        customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.workflowPresenter = workflowPresenter
        self.defaultPaywallPresenter = DefaultPaywallPresenter()
        self.customerInfoSynchronizer = customerInfoSynchronizer
    }

    init(
        workflowPresenter: CheckpointWorkflowPresenterProtocol,
        defaultPaywallPresenter: DefaultPaywallPresenterProtocol,
        customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.workflowPresenter = workflowPresenter
        self.defaultPaywallPresenter = defaultPaywallPresenter
        self.customerInfoSynchronizer = customerInfoSynchronizer
    }

    func presentWorkflow(
        _ presentation: CheckpointPresentation,
        session: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointExecution {
        session.setCancellationHandler { [weak self] in
            self?.workflowPresenter.cancel()
        }
        return try await self.workflowPresenter.present(presentation)
    }

    func presentOffering(
        params: PaywallPresentationParams,
        session: CheckpointPresentationCoordinator.Session,
        localPaywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointExecution {
        let presentationHandler: PaywallPresentationHandler
        let cancellationHandler: (() -> Void)?
        if let localPaywallPresentationHandler {
            presentationHandler = localPaywallPresentationHandler
            cancellationHandler = nil
        } else if let paywallPresenter = self.paywallPresenter {
            presentationHandler = { params, completion in
                paywallPresenter.present(params: params, completion: completion)
            }
            cancellationHandler = nil
        } else {
            presentationHandler = { [defaultPaywallPresenter] params, completion in
                defaultPaywallPresenter.present(params: params, completion: completion)
            }
            cancellationHandler = { [defaultPaywallPresenter] in
                defaultPaywallPresenter.cancel()
            }
        }

        return try await OfferingPresentation(
            session: session,
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

        private let session: CheckpointPresentationCoordinator.Session
        private let customerInfoSynchronizer: CheckpointsManager.CustomerInfoSynchronizer
        private let cancellationHandler: (() -> Void)?
        private var pendingContinuation: CheckedContinuation<
            CheckpointExecution, Error
        >?
        private var hasReportedCompletion = false

        init(
            session: CheckpointPresentationCoordinator.Session,
            customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer,
            cancellationHandler: (() -> Void)?
        ) {
            self.session = session
            self.customerInfoSynchronizer = customerInfoSynchronizer
            self.cancellationHandler = cancellationHandler
        }

        func present(
            params: PaywallPresentationParams,
            presentationHandler: PaywallPresentationHandler
        ) async throws -> CheckpointExecution {
            self.session.setCancellationHandler { [weak self] in
                self?.cancel()
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

            switch result {
            case .navigatedBack:
                self.complete(execution: .backedOut(.dismissed))
            case .continue, .closed:
                self.synchronizeCustomerInfo()
            }
        }

        private func cancel() {
            self.cancellationHandler?()
            self.fail(error: CancellationError(), force: true)
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
protocol DefaultPaywallPresenterProtocol: PaywallPresenter {
    func cancel()
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

    func cancel() {
        guard self.takeCompletion() != nil else { return }
        guard let controller = self.presentedViewController else {
            return
        }
        self.presentedViewController = nil
        controller.dismiss(animated: true)
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

    func cancel() {}
}
#endif
