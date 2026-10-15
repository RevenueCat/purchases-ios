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
        let params: ErrorPresentationParams
        let handler: ErrorPresentationHandler
        let completion: ErrorPresentationCompletion
    }

    private var pendingPresentations: [Presentation] = []
    private var isPresenting = false

    func enqueue(
        params: ErrorPresentationParams,
        handler: @escaping ErrorPresentationHandler,
        completion: ErrorPresentationCompletion
    ) {
        self.pendingPresentations.append(.init(
            params: params,
            handler: handler,
            completion: completion
        ))
        self.presentNextIfNeeded()
    }

    private func presentNextIfNeeded() {
        guard !self.isPresenting, !self.pendingPresentations.isEmpty else { return }

        self.isPresenting = true
        let presentation = self.pendingPresentations.removeFirst()
        presentation.handler(
            presentation.params,
            .init { [weak self] in
                presentation.completion.complete()
                self?.isPresenting = false
                self?.presentNextIfNeeded()
            }
        )
    }

}
