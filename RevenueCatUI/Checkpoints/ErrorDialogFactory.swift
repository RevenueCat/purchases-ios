//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorDialogFactory.swift
//
//  Created by Cesar de la Vega.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Chooses custom dialog content, the SDK's default dialog, or no dialog for a checkpoint error.
///
/// Called on the main actor with the error parameters. The factory may retain the completion and respond later.
/// The SDK waits for the outcome before presenting a dialog or continuing without one.
@_spi(Internal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias ErrorDialogFactory = @MainActor (
    ErrorPresentationParams,
    ErrorDialogFactoryCompletion
) -> Void

/// What an ``ErrorDialogFactory`` decides to do with a checkpoint error.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public enum ErrorDialogFactoryOutcome: Sendable, Equatable {

    /// Show the SDK's error dialog with the supplied content.
    case show(CheckpointErrorDialog)

    /// Show the SDK's error dialog with its own localized copy.
    case useDefault

    /// Show no dialog. The SDK continues as if the user had acknowledged one.
    case suppress

}

/// Delivers the outcome chosen by an ``ErrorDialogFactory``.
///
/// Call ``complete(with:)`` exactly once. Later calls are ignored.
@_spi(Internal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class ErrorDialogFactoryCompletion {

    private var handler: ((ErrorDialogFactoryOutcome) -> Void)?

    init(onComplete: @escaping @MainActor (ErrorDialogFactoryOutcome) -> Void) {
        self.handler = onComplete
    }

    /// Applies the outcome. This supplies the decision; the SDK handles presentation and acknowledgement.
    public func complete(with outcome: ErrorDialogFactoryOutcome) {
        guard let handler = self.handler else { return }
        self.handler = nil
        handler(outcome)
    }

}

// MARK: - Presentation handler factory

/// Creates an ``ErrorPresentationHandler`` that waits for the factory's outcome, then shows the dialog through
/// the SDK's default presenter or completes immediately when suppressed.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
func makeErrorDialogFactoryHandler(
    factory: @escaping ErrorDialogFactory,
    makePresenter: @escaping @MainActor (CheckpointErrorDialog?) -> any ErrorPresenter
) -> ErrorPresentationHandler {
    return { params, presentationCompletion in
        let factoryCompletion = ErrorDialogFactoryCompletion { outcome in
            let dialog: CheckpointErrorDialog?
            switch outcome {
            case .show(let content):
                dialog = content
            case .useDefault:
                dialog = nil
            case .suppress:
                presentationCompletion.complete()
                return
            }
            // Keep the presenter alive until acknowledgement, then break the ownership cycle.
            var presenter: (any ErrorPresenter)? = makePresenter(dialog)
            presenter?.present(params: params, completion: .init {
                presenter = nil
                presentationCompletion.complete()
            })
        }
        factory(params, factoryCompletion)
    }
}
