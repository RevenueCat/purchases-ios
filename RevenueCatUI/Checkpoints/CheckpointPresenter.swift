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

// swiftlint:disable file_length

import Foundation
@_spi(Internal) import RevenueCat

/// Owns and routes the single active checkpoint presentation.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointPresenter: CheckpointPresenterType {

    private let workflowPresenter: WorkflowPresenterType
    private let defaultPaywallPresenter: PaywallPresenter
    private let customerInfoSynchronizer: CheckpointsManager.CustomerInfoSynchronizer
    private let slot = CheckpointPresentationSlot()

    init(
        workflowPresenter: WorkflowPresenterType,
        cachedCustomerInfoProvider: @escaping CheckpointsManager.CachedCustomerInfoProvider = { nil },
        customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.workflowPresenter = workflowPresenter
        self.defaultPaywallPresenter = DefaultPaywallPresenter(
            cachedCustomerInfoProvider: cachedCustomerInfoProvider
        )
        self.customerInfoSynchronizer = customerInfoSynchronizer
    }

    init(
        workflowPresenter: WorkflowPresenterType,
        defaultPaywallPresenter: PaywallPresenter,
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

        do {
            return try await self.workflowPresenter.present(presentation)
        } catch CheckpointError.operationAlreadyInProgress {
            throw CheckpointError.operationAlreadyInProgress
        } catch CheckpointError.presentationContextUnavailable {
            throw CheckpointError.presentationContextUnavailable
        } catch {
            await withCheckedContinuation { continuation in
                presentation.errorPresentationHandler(
                    .init(
                        checkpointIdentifier: presentation.checkpointIdentifier,
                        error: error,
                        customVariables: presentation.customVariables,
                        kind: .flowCouldNotBeShown
                    ),
                    .init { continuation.resume() }
                )
            }
            return .failed
        }
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
        if let localPaywallPresentationHandler {
            presentationHandler = localPaywallPresentationHandler
        } else if let paywallPresenter = globalPaywallPresenter {
            presentationHandler = { params, completion in
                paywallPresenter.present(params: params, completion: completion)
            }
        } else {
            presentationHandler = { [defaultPaywallPresenter] params, completion in
                defaultPaywallPresenter.present(params: params, completion: completion)
            }
        }

        return await OfferingPresentation(
            slot: self.slot,
            token: token,
            customerInfoSynchronizer: self.customerInfoSynchronizer
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
        private var pendingContinuation: CheckedContinuation<CheckpointPresentationOutcome, Never>?
        private var hasReportedCompletion = false

        init(
            slot: CheckpointPresentationSlot,
            token: CheckpointPresentationSlot.Token,
            customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer
        ) {
            self.slot = slot
            self.token = token
            self.customerInfoSynchronizer = customerInfoSynchronizer
        }

        func present(
            params: PaywallPresentationParams,
            presentationHandler: PaywallPresentationHandler
        ) async -> CheckpointPresentationOutcome {
            return await withCheckedContinuation { continuation in
                self.pendingContinuation = continuation
                presentationHandler(params) { [weak self] result in
                    self?.completed(result)
                }
            }
        }

        fileprivate func completed(_ result: PaywallPresentationResult) {
            guard self.slot.contains(self.token),
                  !self.hasReportedCompletion,
                  self.pendingContinuation != nil else { return }
            self.hasReportedCompletion = true
            self.slot.release(self.token)

            if result == .failed {
                self.complete(execution: .failed)
            } else if result == .navigatedBack {
                self.complete(execution: .backedOut)
            } else {
                self.synchronizeCustomerInfo()
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
                    self.complete(execution: .synchronizationFailed(error))
                }
            }
        }

        private func complete(execution: CheckpointPresentationOutcome) {
            guard let continuation = self.takeContinuation() else { return }
            continuation.resume(returning: execution)
        }

        private func takeContinuation() -> CheckedContinuation<CheckpointPresentationOutcome, Never>? {
            defer { self.pendingContinuation = nil }
            return self.pendingContinuation
        }

    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol CheckpointPresenterType: AnyObject {

    func presentWorkflow(_ presentation: WorkflowPresentationRequest) async throws -> CheckpointPresentationOutcome

    func presentOffering(
        params: PaywallPresentationParams,
        globalPaywallPresenter: PaywallPresenter?,
        localPaywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointPresentationOutcome

}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

@MainActor
@available(iOS 15.0, macOS 12.0, *)
final class DefaultPaywallPresenter: NSObject, PaywallPresenter, PaywallViewControllerDelegate {

    private let cachedCustomerInfoProvider: CheckpointsManager.CachedCustomerInfoProvider
    private let presentationContextProvider: @MainActor () -> UIViewController?
    private var session: PresentationSession?

    init(
        cachedCustomerInfoProvider: @escaping CheckpointsManager.CachedCustomerInfoProvider = { nil },
        presentationContextProvider: @escaping @MainActor () -> UIViewController? = {
            UIApplication.extensionSafeApplication?.currentPresentationViewController
        }
    ) {
        self.cachedCustomerInfoProvider = cachedCustomerInfoProvider
        self.presentationContextProvider = presentationContextProvider
    }

    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        guard self.session == nil else {
            Self.presentStartupError(
                .operationAlreadyInProgress,
                params: params,
                completion: completion
            )
            return
        }
        guard let presentationContext = self.presentationContextProvider() else {
            Self.presentStartupError(
                .noPresentationContext,
                params: params,
                completion: completion
            )
            return
        }

        let controller = makeDefaultCheckpointPaywallViewController(
            params: params,
            workflowPresentationErrorHandler: { [weak self] error, behavior in
                self?.handleWorkflowPresentationError(error, behavior: behavior)
            }
        )
        self.prepareForPresentation(
            params: params,
            completion: completion,
            presentedViewController: controller
        )
        controller.delegate = self
        controller.modalPresentationStyle = params.presentationMode.modalPresentationStyle
        presentationContext.present(controller, animated: true)
        if controller.presentingViewController == nil, let session = self.takeSession() {
            Self.presentStartupError(
                .presentationFailed,
                params: session.params,
                completion: session.completion
            )
        }
    }

    private func finish(_ controller: PaywallViewController) {
        guard let session = self.takeSession() else { return }
        session.completion(Self.presentationResult(
            didPurchaseOrRestoreAccess: session.didPurchaseOrRestoreAccess,
            hasTerminalError: session.hasTerminalError,
            dismissalReason: controller.workflowDismissalReason
        ))
    }

    func presentationResult(dismissalReason: WorkflowDismissalReason) -> PaywallPresentationResult {
        return Self.presentationResult(
            didPurchaseOrRestoreAccess: self.session?.didPurchaseOrRestoreAccess == true,
            hasTerminalError: self.session?.hasTerminalError == true,
            dismissalReason: dismissalReason
        )
    }

    func prepareForPresentation(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion = { _ in },
        presentedViewController: PaywallViewController? = nil
    ) {
        self.session = PresentationSession(
            params: params,
            completion: completion,
            initialActiveEntitlementIdentifiers: self.cachedCustomerInfoProvider().map { customerInfo in
                Set(customerInfo.entitlements.active.keys)
            },
            presentedViewController: presentedViewController
        )
    }

    private func presentError(
        _ error: any Error,
        kind: CheckpointFailureKind,
        onCompletion: (@MainActor () -> Void)? = nil
    ) {
        guard let session = self.session,
              let handler = session.params.errorPresentationHandler else { return }
        let presentationID = UUID()
        session.activeErrorPresentationID = presentationID
        handler(
            .init(
                checkpointIdentifier: session.params.checkpointIdentifier,
                error: error,
                customVariables: session.params.customVariables,
                kind: kind
            ),
            .init { [weak self] in
                self?.handleErrorPresentationResult(
                    presentationID: presentationID,
                    onCompletion: onCompletion
                )
            }
        )
    }

    private func handleErrorPresentationResult(
        presentationID: UUID,
        onCompletion: (@MainActor () -> Void)?
    ) {
        guard let session = self.session,
              session.activeErrorPresentationID == presentationID else { return }
        session.activeErrorPresentationID = nil
        onCompletion?()
    }

    private func didCompleteRestore(
        controller: PaywallViewController,
        customerInfo: CustomerInfo
    ) {
        guard let session = self.session else { return }
        guard customerInfo.grantsNewEntitlements(
            comparedTo: session.initialActiveEntitlementIdentifiers
        ) else { return }

        session.activeErrorPresentationID = nil
        session.didPurchaseOrRestoreAccess = true
        controller.dismiss(animated: true)
    }

    private func dismissAfterTerminalError() {
        guard let session = self.session else { return }
        session.hasTerminalError = true
        session.presentedViewController?.continueAfterCheckpointError()
    }

    func handleWorkflowPresentationError(
        _ error: NSError,
        behavior: WorkflowPresentationErrorBehavior
    ) {
        switch behavior {
        case .endFlow:
            self.presentError(
                error,
                kind: .flowCouldNotBeShown,
                onCompletion: { [weak self] in
                    self?.dismissAfterTerminalError()
                }
            )
        case .keepCurrentScreen:
            self.presentError(error, kind: .flowActionFailed)
        }
    }

    private func takeSession() -> PresentationSession? {
        defer { self.session = nil }
        return self.session
    }

    private static func presentationResult(
        didPurchaseOrRestoreAccess: Bool,
        hasTerminalError: Bool,
        dismissalReason: WorkflowDismissalReason
    ) -> PaywallPresentationResult {
        guard !didPurchaseOrRestoreAccess else { return .continued }
        guard !hasTerminalError else { return .failed }
        return dismissalReason == .navigatedBack ? .navigatedBack : .closed
    }

    #if compiler(>=5.9)
    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFinishPurchasingWith customerInfo: CustomerInfo,
        transaction: StoreTransaction?
    ) {
        MainActor.assumeIsolated {
            self.session?.activeErrorPresentationID = nil
            self.session?.didPurchaseOrRestoreAccess = true
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        MainActor.assumeIsolated {
            self.didCompleteRestore(controller: controller, customerInfo: customerInfo)
        }
    }

    nonisolated func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        MainActor.assumeIsolated { self.finish(controller) }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        MainActor.assumeIsolated {
            guard !error.isPurchaseCancellation else { return }
            self.presentError(
                error,
                kind: .flowActionFailed
            )
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        MainActor.assumeIsolated {
            self.presentError(
                error,
                kind: .flowActionFailed
            )
        }
    }
    #else
    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishPurchasingWith customerInfo: CustomerInfo,
        transaction: StoreTransaction?
    ) {
        self.session?.activeErrorPresentationID = nil
        self.session?.didPurchaseOrRestoreAccess = true
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {
        self.didCompleteRestore(controller: controller, customerInfo: customerInfo)
    }

    func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        self.finish(controller)
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailPurchasingWith error: NSError
    ) {
        guard !error.isPurchaseCancellation else { return }
        self.presentError(
            error,
            kind: .flowActionFailed
        )
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        self.presentError(
            error,
            kind: .flowActionFailed
        )
    }
    #endif

}

@MainActor
@available(iOS 15.0, macOS 12.0, *)
private final class PresentationSession {
    let params: PaywallPresentationParams
    let completion: PaywallPresentationCompletion
    let initialActiveEntitlementIdentifiers: Set<String>?
    weak var presentedViewController: PaywallViewController?
    var activeErrorPresentationID: UUID?
    var didPurchaseOrRestoreAccess = false
    var hasTerminalError = false

    init(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion,
        initialActiveEntitlementIdentifiers: Set<String>?,
        presentedViewController: PaywallViewController?
    ) {
        self.params = params
        self.completion = completion
        self.initialActiveEntitlementIdentifiers = initialActiveEntitlementIdentifiers
        self.presentedViewController = presentedViewController
    }
}

@MainActor
@available(iOS 15.0, macOS 12.0, *)
func makeDefaultCheckpointPaywallViewController(
    params: PaywallPresentationParams,
    workflowPresentationErrorHandler: WorkflowPresentationErrorHandler? = nil
) -> PaywallViewController {
    let controller = PaywallViewController(
        checkpointOffering: params.offering,
        displayCloseButton: true,
        workflowPresentationErrorHandler: workflowPresentationErrorHandler
    )
    controller.disableExitOffers()
    controller.customVariables = params.customVariables
    return controller
}
#else
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class DefaultPaywallPresenter: PaywallPresenter {

    init(
        cachedCustomerInfoProvider _: @escaping CheckpointsManager.CachedCustomerInfoProvider = { nil }
    ) {}

    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        Self.presentStartupError(
            .presentationFailed,
            params: params,
            completion: completion
        )
    }
}
#endif

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DefaultPaywallPresenter {

    static func presentStartupError(
        _ error: CheckpointError,
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        guard let handler = params.errorPresentationHandler else {
            completion(.failed)
            return
        }

        handler(
            .init(
                checkpointIdentifier: params.checkpointIdentifier,
                error: error,
                customVariables: params.customVariables,
                kind: .flowCouldNotBeShown
            ),
            .init { completion(.failed) }
        )
    }

}
