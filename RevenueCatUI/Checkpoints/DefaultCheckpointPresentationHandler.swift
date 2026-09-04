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

/// Routes checkpoint presentations to an app-owned presenter or RevenueCat's default presenter.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class DefaultCheckpointPresentationHandler: CheckpointPresentationHandler {

    private let executor: CheckpointExecutor
    private let fetchCustomerInfo: () async throws -> CustomerInfo
    var offeringPresenter: CheckpointOfferingPresenter?

    init(
        executor: CheckpointExecutor,
        fetchCustomerInfo: @escaping () async throws -> CustomerInfo
    ) {
        self.executor = executor
        self.fetchCustomerInfo = fetchCustomerInfo
    }

    func present(
        _ presentation: CheckpointPresentation,
        session: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointPaywallOutcome {
        switch presentation {
        case .workflow:
            session.setCancellationHandler { [weak self] in
                self?.executor.cancel()
            }
            return try await self.executor.execute(presentation)
        case let .offering(offering, _):
            if let presenter = self.offeringPresenter {
                return try await OfferingPresentation(
                    session: session,
                    fetchCustomerInfo: self.fetchCustomerInfo
                ).present(offering: offering, presenter: presenter)
            } else {
                return try await self.executor.execute(presentation)
            }
        }
    }

    /// Bridges the app-owned presenter's completion callback into the checkpoint lifecycle.
    @MainActor
    private final class OfferingPresentation {

        private let session: CheckpointPresentationCoordinator.Session
        private let fetchCustomerInfo: () async throws -> CustomerInfo
        private var pendingContinuation: CheckedContinuation<CheckpointPaywallOutcome, Error>?
        private var hasReportedCompletion = false
        private var fetchTask: Task<Void, Never>?

        init(
            session: CheckpointPresentationCoordinator.Session,
            fetchCustomerInfo: @escaping () async throws -> CustomerInfo
        ) {
            self.session = session
            self.fetchCustomerInfo = fetchCustomerInfo
        }

        func present(
            offering: Offering,
            presenter: CheckpointOfferingPresenter
        ) async throws -> CheckpointPaywallOutcome {
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
                    do {
                        try presenter.present(
                            offering: offering,
                            completion: Completion(presentation: self)
                        )
                    } catch {
                        self.fail(error: error)
                    }
                }
            } onCancel: {
                Task { @MainActor [weak self] in
                    self?.fail(error: CancellationError(), force: true)
                }
            }
        }

        private func finished() {
            guard self.session.isActive,
                  !self.hasReportedCompletion,
                  self.pendingContinuation != nil else { return }
            self.hasReportedCompletion = true

            self.fetchTask = Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let customerInfo = try await self.fetchCustomerInfo()
                    self.complete(outcome: .Finished(customerInfo: customerInfo))
                } catch {
                    self.complete(outcome: .Error(error: error as NSError))
                }
            }
        }

        private func complete(outcome: CheckpointPaywallOutcome) {
            guard self.session.isActive,
                  let continuation = self.takeContinuation() else { return }
            self.fetchTask = nil
            continuation.resume(returning: outcome)
        }

        private func fail(error: Error, force: Bool = false) {
            guard self.pendingContinuation != nil,
                  force || !self.hasReportedCompletion else { return }
            self.hasReportedCompletion = true
            self.fetchTask?.cancel()
            self.fetchTask = nil
            guard self.session.isActive,
                  let continuation = self.takeContinuation() else { return }
            continuation.resume(throwing: error)
        }

        private func takeContinuation() -> CheckedContinuation<CheckpointPaywallOutcome, Error>? {
            defer { self.pendingContinuation = nil }
            return self.pendingContinuation
        }

        private final class Completion: CheckpointOfferingCompletion {

            private weak var presentation: OfferingPresentation?

            init(presentation: OfferingPresentation) {
                self.presentation = presentation
            }

            func finished() {
                self.presentation?.finished()
            }

            func failed() {
                self.presentation?.fail(
                    error: NSError(
                        domain: ErrorCode.errorDomain,
                        code: ErrorCode.unknownError.rawValue,
                        userInfo: [
                            NSLocalizedDescriptionKey: "The checkpoint offering presenter reported a failure."
                        ]
                    )
                )
            }
        }
    }

}
