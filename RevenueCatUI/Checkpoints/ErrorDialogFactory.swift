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

/// Provides custom content for a checkpoint error dialog through an ``ErrorDialogFactoryCompletion``.
@_spi(Internal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias ErrorDialogFactory = @MainActor (
    ErrorPresentationParams,
    ErrorDialogFactoryCompletion
) -> Void

/// Delivers the dialog content for a checkpoint error, or `nil` for the SDK's default content.
///
/// Call ``complete(with:)`` exactly once. Later calls are ignored.
@_spi(Internal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class ErrorDialogFactoryCompletion {

    private var handler: ((CheckpointErrorDialog?) -> Void)?

    init(onComplete: @escaping @MainActor (CheckpointErrorDialog?) -> Void) {
        self.handler = onComplete
    }

    /// Delivers the dialog content to the SDK.
    public func complete(with dialog: CheckpointErrorDialog?) {
        guard let handler = self.handler else { return }
        self.handler = nil
        handler(dialog)
    }

}

// MARK: - Presentation handler factory

/// Creates an ``ErrorPresentationHandler`` that calls the given factory, waits for its dialog content,
/// then shows the result through the SDK's default presenter.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
func makeErrorDialogFactoryHandler(
    factory: @escaping ErrorDialogFactory,
    makePresenter: @escaping @MainActor (CheckpointErrorDialog?) -> any ErrorPresenter
) -> ErrorPresentationHandler {
    return { params, presentationCompletion in
        let factoryCompletion = ErrorDialogFactoryCompletion { dialog in
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
