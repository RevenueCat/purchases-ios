//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowExecutor.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Everything needed to present a checkpoint experience.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum CheckpointPresentation {
    case workflow(ResolvedCheckpointWorkflow, customVariables: [String: CustomVariableValue])
    case offering(Offering, customVariables: [String: CustomVariableValue])

    var customVariables: [String: CustomVariableValue] {
        switch self {
        case let .workflow(_, customVariables), let .offering(_, customVariables):
            return customVariables
        }
    }

}

/// Bridges resolved checkpoint workflows into asynchronous UI outcomes.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol CheckpointExecutor: AnyObject {

    func execute(_ presentation: CheckpointPresentation) async throws -> CheckpointPaywallOutcome

    func execute(offering: Offering, customVariables: [String: CustomVariableValue]) async throws
    -> CheckpointPaywallOutcome

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CheckpointExecutor {

    func execute(
        offering: Offering,
        customVariables: [String: CustomVariableValue]
    ) async throws -> CheckpointPaywallOutcome {
        return try await self.execute(
            .offering(offering, customVariables: customVariables)
        )
    }

}

/// Presents a resolved workflow and reports its terminal outcome through a delegate.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol CheckpointPresenter: AnyObject {

    func present(
        presentation: CheckpointPresentation,
        delegate: CheckpointPresentationDelegate
    ) throws

    func dismiss(completion: @escaping () -> Void)

}

/// Receives the final staged outcome after checkpoint UI has fully dismissed.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol CheckpointPresentationDelegate: AnyObject {

    func checkpointPresentationFinished(outcome: CheckpointPaywallOutcome)

}

/// Executes a resolved workflow using RevenueCatUI's checkpoint presenter.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointWorkflowExecutor: CheckpointExecutor, CheckpointPresentationDelegate {

    typealias PresenterProvider = @MainActor () -> CheckpointPresenter?

    private typealias Continuation = CheckedContinuation<CheckpointPaywallOutcome, Error>

    private var pendingContinuation: Continuation?
    private var activePresenter: CheckpointPresenter?
    private let presenterProvider: PresenterProvider

    init(presenterProvider: @escaping PresenterProvider = {
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        return CheckpointWorkflowPresenter()
        #else
        return nil
        #endif
    }) {
        self.presenterProvider = presenterProvider
    }

    func execute(_ presentation: CheckpointPresentation) async throws -> CheckpointPaywallOutcome {
        guard self.pendingContinuation == nil else {
            throw CheckpointError.operationAlreadyInProgress
        }
        guard let presenter = self.presenterProvider() else {
            throw CheckpointError.missingPresenter
        }

        self.activePresenter = presenter
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled else {
                    self.activePresenter = nil
                    continuation.resume(throwing: CancellationError())
                    return
                }
                self.store(continuation: continuation)
                do {
                    try presenter.present(presentation: presentation, delegate: self)
                } catch {
                    self.fail(error: error)
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancel()
            }
        }
    }

    func execute(
        offering: Offering,
        customVariables: [String: CustomVariableValue]
    ) async throws -> CheckpointPaywallOutcome {
        return try await self.execute(
            .offering(offering, customVariables: customVariables)
        )
    }

    func checkpointPresentationFinished(outcome: CheckpointPaywallOutcome) {
        self.finish(outcome: outcome)
    }

    private func store(continuation: Continuation) {
        self.pendingContinuation = continuation
    }

    private func finish(outcome: CheckpointPaywallOutcome) {
        guard let continuation = self.takePendingContinuation() else { return }
        self.activePresenter = nil
        continuation.resume(returning: outcome)
    }

    private func fail(error: Error) {
        guard let continuation = self.takePendingContinuation() else { return }
        self.activePresenter = nil
        continuation.resume(throwing: error)
    }

    private func cancel() {
        guard self.pendingContinuation != nil,
              let presenter = self.activePresenter else { return }

        presenter.dismiss { [weak self] in
            guard let self,
                  let continuation = self.takePendingContinuation() else { return }
            self.activePresenter = nil
            continuation.resume(throwing: CancellationError())
        }
    }

    private func takePendingContinuation() -> Continuation? {
        defer { self.pendingContinuation = nil }
        return self.pendingContinuation
    }

}
