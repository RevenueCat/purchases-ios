//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresentationCoordinator.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// Coordinates the single active checkpoint presentation without knowing how that presentation is rendered.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointPresentationCoordinator {

    private let handler: CheckpointPresentationHandlerProtocol
    private let slot = CheckpointPresentationSlot()

    init(handler: CheckpointPresentationHandlerProtocol) {
        self.handler = handler
    }

    func presentWorkflow(
        _ presentation: CheckpointPresentation
    ) async throws -> CheckpointExecution {
        return try await self.withPresentationSession { session in
            try await self.handler.presentWorkflow(presentation, session: session)
        }
    }

    func presentOffering(
        params: PaywallPresentationParams,
        globalPaywallPresenter: PaywallPresenter?,
        localPaywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointExecution {
        return try await self.withPresentationSession { session in
            try await self.handler.presentOffering(
                params: params,
                session: session,
                globalPaywallPresenter: globalPaywallPresenter,
                localPaywallPresentationHandler: localPaywallPresentationHandler
            )
        }
    }

    func withPresentationSession<T>(operation: (Session) async throws -> T) async throws -> T {
        guard let token = self.slot.claim() else {
            throw CheckpointError.operationAlreadyInProgress
        }

        let session = Session(coordinator: self, token: token)
        defer {
            self.slot.release(token)
            session.setCancellationHandler(nil)
        }
        return try await withTaskCancellationHandler(operation: {
            try await operation(session)
        }, onCancel: {
            Task { @MainActor in
                session.cancel()
            }
        })
    }

    fileprivate func isActive(_ session: Session) -> Bool {
        return self.slot.contains(session.token)
    }

    fileprivate func releasePresentationSlot(for session: Session) {
        self.slot.release(session.token)
    }

    final class Session {
        private weak var coordinator: CheckpointPresentationCoordinator?
        fileprivate let token: CheckpointPresentationSlot.Token
        private var cancellationHandler: (() -> Void)?

        fileprivate init(
            coordinator: CheckpointPresentationCoordinator,
            token: CheckpointPresentationSlot.Token
        ) {
            self.coordinator = coordinator
            self.token = token
        }

        @MainActor
        var isActive: Bool {
            return self.coordinator?.isActive(self) == true
        }

        func setCancellationHandler(_ handler: (() -> Void)?) {
            self.cancellationHandler = handler
        }

        @MainActor
        func releasePresentationSlot() {
            self.coordinator?.releasePresentationSlot(for: self)
        }

        fileprivate func cancel() {
            self.cancellationHandler?()
        }
    }

}

/// Owns the strategy used to render a checkpoint presentation.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol CheckpointPresentationHandlerProtocol: AnyObject {

    func presentWorkflow(
        _ presentation: CheckpointPresentation,
        session: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointExecution

    func presentOffering(
        params: PaywallPresentationParams,
        session: CheckpointPresentationCoordinator.Session,
        globalPaywallPresenter: PaywallPresenter?,
        localPaywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointExecution

}
