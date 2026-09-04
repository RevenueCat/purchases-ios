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

    private let handler: CheckpointPresentationHandler
    private var activePresentation: Session?

    init(handler: CheckpointPresentationHandler) {
        self.handler = handler
    }

    func present(
        _ presentation: CheckpointPresentation,
        paywallPresenter: CheckpointPaywallPresenter?
    ) async throws -> CheckpointPaywallOutcome {
        return try await self.withPresentationSession { session in
            try await self.handler.present(
                presentation,
                session: session,
                paywallPresenter: paywallPresenter
            )
        }
    }

    func withPresentationSession<T>(operation: (Session) async throws -> T) async throws -> T {
        guard self.activePresentation == nil else {
            throw CheckpointError.operationAlreadyInProgress
        }

        let session = Session(coordinator: self)
        self.activePresentation = session
        defer {
            if self.activePresentation === session {
                self.activePresentation = nil
            }
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
        return self.activePresentation === session
    }

    final class Session {
        private weak var coordinator: CheckpointPresentationCoordinator?
        private var cancellationHandler: (() -> Void)?

        fileprivate init(coordinator: CheckpointPresentationCoordinator) {
            self.coordinator = coordinator
        }

        @MainActor
        var isActive: Bool {
            return self.coordinator?.isActive(self) == true
        }

        func setCancellationHandler(_ handler: (() -> Void)?) {
            self.cancellationHandler = handler
        }

        fileprivate func cancel() {
            self.cancellationHandler?()
        }
    }

}

/// Owns the strategy used to render a checkpoint presentation.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol CheckpointPresentationHandler: AnyObject {

    func present(
        _ presentation: CheckpointPresentation,
        session: CheckpointPresentationCoordinator.Session,
        paywallPresenter: CheckpointPaywallPresenter?
    ) async throws -> CheckpointPaywallOutcome

}
