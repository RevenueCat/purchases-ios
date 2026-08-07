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

/// Bridges resolved checkpoint workflows into asynchronous UI outcomes.
@MainActor
protocol CheckpointExecutor: AnyObject {

    func execute(_ workflow: ResolvedCheckpointWorkflow) async throws -> CheckpointPaywallOutcome

}

/// Presents a resolved workflow and reports its terminal outcome through a delegate.
@MainActor
protocol CheckpointPresenter: AnyObject {

    func present(
        callID: String,
        workflow: ResolvedCheckpointWorkflow,
        delegate: CheckpointPresentationDelegate
    )

    func dismiss(callID: String, completion: @escaping () -> Void)

}

/// Receives the final staged outcome after checkpoint UI has fully dismissed.
@MainActor
protocol CheckpointPresentationDelegate: AnyObject {

    func checkpointPresentationFinished(callID: String, outcome: CheckpointPaywallOutcome)

}

/// Executes a resolved workflow using RevenueCatUI's checkpoint presenter.
@MainActor
final class CheckpointWorkflowExecutor: CheckpointExecutor, CheckpointPresentationDelegate {

    typealias PresenterProvider = @MainActor () -> CheckpointPresenter?

    private typealias Continuation = CheckedContinuation<CheckpointPaywallOutcome, Error>

    private var pendingCalls: [String: Continuation] = [:]
    private var activePresenter: CheckpointPresenter?
    private let presenterProvider: PresenterProvider

    init(presenterProvider: @escaping PresenterProvider = {
        guard #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) else {
            return nil
        }
        return CheckpointWorkflowPresenter()
    }) {
        self.presenterProvider = presenterProvider
    }

    func execute(_ workflow: ResolvedCheckpointWorkflow) async throws -> CheckpointPaywallOutcome {
        guard self.pendingCalls.isEmpty else {
            throw CheckpointError.operationAlreadyInProgress
        }
        guard let presenter = self.presenterProvider() else {
            throw CheckpointError.missingPresenter
        }

        self.activePresenter = presenter
        let callID = UUID().uuidString
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled else {
                    self.activePresenter = nil
                    continuation.resume(throwing: CancellationError())
                    return
                }
                self.store(continuation: continuation, for: callID)
                presenter.present(callID: callID, workflow: workflow, delegate: self)
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancel(callID: callID)
            }
        }
    }

    func checkpointPresentationFinished(callID: String, outcome: CheckpointPaywallOutcome) {
        self.finish(callID: callID, outcome: outcome)
    }

    private func store(continuation: Continuation, for callID: String) {
        self.pendingCalls[callID] = continuation
    }

    private func finish(callID: String, outcome: CheckpointPaywallOutcome) {
        guard let continuation = self.pendingCalls.removeValue(forKey: callID) else { return }
        self.activePresenter = nil
        continuation.resume(returning: outcome)
    }

    private func cancel(callID: String) {
        guard self.pendingCalls[callID] != nil,
              let presenter = self.activePresenter else { return }

        presenter.dismiss(callID: callID) { [weak self] in
            guard let self,
                  let continuation = self.pendingCalls.removeValue(forKey: callID) else { return }
            self.activePresenter = nil
            continuation.resume(throwing: CancellationError())
        }
    }

}
