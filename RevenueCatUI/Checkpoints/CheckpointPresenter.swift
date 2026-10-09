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
        private var endedWithError = false

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
                presentationHandler(self.trackingTerminalErrors(in: params)) { [weak self] result in
                    self?.completed(result)
                }
            }
        }

        private func trackingTerminalErrors(in params: PaywallPresentationParams) -> PaywallPresentationParams {
            let errorPresentationHandler = params.errorPresentationHandler.map { handler in
                let trackingHandler: ErrorPresentationHandler = { [weak self] errorParams, completion in
                    handler(errorParams, .init { result in
                        switch (result.action, errorParams.flowCanContinue) {
                        case (.continue, _), (.retry, false):
                            self?.endedWithError = true
                        case (.retry, true), (.navigateBack, _):
                            break
                        }
                        completion.complete(result)
                    })
                }
                return trackingHandler
            }

            return .init(
                checkpointIdentifier: params.checkpointIdentifier,
                customVariables: params.customVariables,
                presentationMode: params.presentationMode,
                offering: params.offering,
                errorPresentationHandler: errorPresentationHandler
            )
        }

        fileprivate func completed(_ result: PaywallPresentationResult) {
            guard self.slot.contains(self.token),
                  !self.hasReportedCompletion,
                  self.pendingContinuation != nil else { return }
            self.hasReportedCompletion = true
            self.slot.release(self.token)

            if self.endedWithError {
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
                    self.complete(execution: .failed)
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
    private var session: PresentationSession?

    init(
        cachedCustomerInfoProvider: @escaping CheckpointsManager.CachedCustomerInfoProvider = { nil }
    ) {
        self.cachedCustomerInfoProvider = cachedCustomerInfoProvider
    }

    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        guard let presentationContext = UIApplication.extensionSafeApplication?.currentPresentationViewController else {
            completion(.closed)
            return
        }
        guard self.session == nil else {
            completion(.closed)
            return
        }

        self.prepareForPresentation(params: params, completion: completion)
        let controller = makeDefaultCheckpointPaywallViewController(
            params: params,
            workflowPresentationErrorHandler: { [weak self] error in
                self?.presentError(error, flowCanContinue: false)
            }
        )
        self.session?.presentedViewController = controller
        controller.delegate = self
        controller.modalPresentationStyle = params.presentationMode.modalPresentationStyle
        presentationContext.present(controller, animated: true)
        if controller.presentingViewController == nil {
            self.completeAsClosed()
        }
    }

    private func finish(_ controller: PaywallViewController) {
        guard let session = self.takeSession() else { return }
        session.completion(Self.presentationResult(
            didPurchaseOrRestoreAccess: session.didPurchaseOrRestoreAccess,
            dismissalReason: controller.workflowDismissalReason
        ))
    }

    func presentationResult(dismissalReason: WorkflowDismissalReason) -> PaywallPresentationResult {
        return Self.presentationResult(
            didPurchaseOrRestoreAccess: self.session?.didPurchaseOrRestoreAccess == true,
            dismissalReason: dismissalReason
        )
    }

    func prepareForPresentation(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion = { _ in }
    ) {
        self.session = PresentationSession(
            params: params,
            completion: completion,
            initialActiveEntitlementIdentifiers: self.cachedCustomerInfoProvider().map { customerInfo in
                Set(customerInfo.entitlements.active.keys)
            }
        )
    }

    private func presentError(
        _ error: any Error,
        flowCanContinue: Bool,
        controller: PaywallViewController? = nil
    ) {
        guard let session = self.session,
              let handler = session.params.errorPresentationHandler else { return }
        let presentationID = UUID()
        session.activeErrorPresentationID = presentationID
        let controller = controller ?? session.presentedViewController

        handler(
            .init(
                checkpointIdentifier: session.params.checkpointIdentifier,
                error: error,
                customVariables: session.params.customVariables,
                flowCanContinue: flowCanContinue
            ),
            .init { [weak self, weak controller] result in
                self?.handleErrorPresentationResult(
                    result,
                    flowCanContinue: flowCanContinue,
                    presentationID: presentationID,
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
        guard let session = self.session,
              session.activeErrorPresentationID == presentationID else { return }
        session.activeErrorPresentationID = nil

        switch result.action {
        case .retry where flowCanContinue:
            break
        case .retry, .continue:
            controller?.continueAfterCheckpointError()
        case .navigateBack:
            controller?.navigateBackAfterCheckpointError(flowCanContinue: flowCanContinue)
        }
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

    private func completeAsClosed() {
        guard let session = self.takeSession() else { return }
        session.completion(.closed)
    }

    private func takeSession() -> PresentationSession? {
        defer { self.session = nil }
        return self.session
    }

    private static func presentationResult(
        didPurchaseOrRestoreAccess: Bool,
        dismissalReason: WorkflowDismissalReason
    ) -> PaywallPresentationResult {
        guard !didPurchaseOrRestoreAccess else { return .continued }
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
            self.presentError(error, flowCanContinue: true, controller: controller)
        }
    }

    nonisolated func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        MainActor.assumeIsolated {
            self.presentError(error, flowCanContinue: true, controller: controller)
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
        self.presentError(error, flowCanContinue: true, controller: controller)
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFailRestoringWith error: NSError
    ) {
        self.presentError(error, flowCanContinue: true, controller: controller)
    }
    #endif

    private final class PresentationSession {
        let params: PaywallPresentationParams
        let completion: PaywallPresentationCompletion
        let initialActiveEntitlementIdentifiers: Set<String>?
        weak var presentedViewController: PaywallViewController?
        var activeErrorPresentationID: UUID?
        var didPurchaseOrRestoreAccess = false

        init(
            params: PaywallPresentationParams,
            completion: @escaping PaywallPresentationCompletion,
            initialActiveEntitlementIdentifiers: Set<String>?
        ) {
            self.params = params
            self.completion = completion
            self.initialActiveEntitlementIdentifiers = initialActiveEntitlementIdentifiers
        }
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, *)
func makeDefaultCheckpointPaywallViewController(
    params: PaywallPresentationParams,
    workflowPresentationErrorHandler: ((NSError) -> Void)? = nil
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
        completion(.closed)
    }
}
#endif
