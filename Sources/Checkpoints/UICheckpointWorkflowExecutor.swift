//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UICheckpointWorkflowExecutor.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// Executes a checkpoint workflow by asking the linked RevenueCatUI module to present it.
final class UICheckpointWorkflowExecutor: CheckpointWorkflowExecutor, CheckpointEnginePresenterDelegate {

    private typealias PaywallContinuation = CheckedContinuation<CheckpointPaywallOutcome, Error>

    @MainActor
    private var pendingCalls: [String: PaywallContinuation] = [:]
    @MainActor
    private var presenting = false
    @MainActor
    private var activePresenter: CheckpointEnginePresenter?

    @MainActor
    func execute(
        _ presentation: CheckpointEnginePresentation,
        presenter: CheckpointEnginePresenter?
    ) async throws -> CheckpointWorkflowOutcome {
        guard let presenter else {
            throw ErrorUtils.configurationError(
                message: "Cannot present checkpoint UI: no presentation handler was supplied."
            )
        }
        guard !self.presenting else {
            throw ErrorUtils.operationAlreadyInProgressError(
                message: "Another checkpoint experience is already being presented.",
                replaceDefaultMessage: true
            )
        }

        self.presenting = true
        self.activePresenter = presenter
        let callID = UUID().uuidString
        let outcome = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: PaywallContinuation) in
                guard !Task.isCancelled else {
                    self.releasePresentation()
                    continuation.resume(throwing: CancellationError())
                    return
                }
                self.pendingCalls[callID] = continuation
                presenter.present(
                    callID: callID,
                    presentation: presentation,
                    delegate: self
                )
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancelPresentation(callID: callID)
            }
        }
        return .paywallFinished(outcome)
    }

    nonisolated func onCheckpointPaywallFinished(callID: String, outcome: CheckpointPaywallOutcome) {
        Task { @MainActor [weak self] in
            self?.finishPresentation(callID: callID, outcome: outcome)
        }
    }

    @MainActor
    private func finishPresentation(callID: String, outcome: CheckpointPaywallOutcome) {
        guard let continuation = self.pendingCalls.removeValue(forKey: callID) else {
            return
        }
        self.releasePresentation()
        continuation.resume(returning: outcome)
    }

    @MainActor
    private func cancelPresentation(callID: String) {
        guard let continuation = self.pendingCalls.removeValue(forKey: callID) else {
            return
        }
        self.releasePresentation()
        continuation.resume(throwing: CancellationError())
    }

    @MainActor
    private func releasePresentation() {
        self.presenting = false
        self.activePresenter = nil
    }

}
