//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorPresentationQueue.swift
//
//  Created by Rick van der Linden.
//

import Foundation

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ErrorPresentationQueue {

    private struct Presentation {
        let id: UUID
        let params: ErrorPresentationParams
        let handler: ErrorPresentationHandler
        let completion: ErrorPresentationCompletion
    }

    private var pendingPresentations: [Presentation] = []
    private var activePresentationID: UUID?

    func enqueue(
        params: ErrorPresentationParams,
        handler: @escaping ErrorPresentationHandler,
        completion: ErrorPresentationCompletion,
        execution: EmbeddedCheckpointExecution? = nil
    ) {
        let id = UUID()
        let queueCompletion = ErrorPresentationCompletion { [weak self] in
            completion.complete()
            self?.removePresentation(id)
        }
        let enqueue: ErrorPresentationHandler = { [weak self] params, completion in
            guard let self else {
                completion.complete()
                return
            }
            self.pendingPresentations.append(.init(
                id: id,
                params: params,
                handler: handler,
                completion: completion
            ))
            self.presentNextIfNeeded()
        }
        // Register cancellation before waiting behind another execution's error UI, so a cancelled
        // execution leaves the queue even if its error was never shown.
        let enqueueForExecution = execution?.wrap(enqueue) ?? enqueue
        enqueueForExecution(params, queueCompletion)
    }

    private func removePresentation(_ id: UUID) {
        self.pendingPresentations.removeAll { $0.id == id }
        guard self.activePresentationID == id else { return }
        self.activePresentationID = nil
        Task { @MainActor [weak self] in
            self?.presentNextIfNeeded()
        }
    }

    private func presentNextIfNeeded() {
        guard self.activePresentationID == nil, !self.pendingPresentations.isEmpty else { return }

        let presentation = self.pendingPresentations.removeFirst()
        self.activePresentationID = presentation.id
        presentation.handler(presentation.params, presentation.completion)
    }

}
