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

/// Provides custom content for a checkpoint error dialog.
///
/// The factory is called with the error parameters for the failed checkpoint. Call
/// ``ErrorDialogFactoryCompletion/complete(with:)`` exactly once with the dialog content to use,
/// or with `nil` to use the SDK's default content. If the completion is not called within
/// ``ErrorDialogFactoryCompletion/timeoutInterval`` seconds, the SDK falls back to the default content
/// and any later completion call is ignored.
@_spi(Internal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias ErrorDialogFactory = @MainActor (
    ErrorPresentationParams,
    ErrorDialogFactoryCompletion
) -> Void

/// Delivers the dialog content for the SDK to show for a checkpoint error.
///
/// Call ``complete(with:)`` exactly once. Later calls on the same completion are ignored.
/// If the completion is not called within the timeout the SDK falls back to the default content;
/// any later call is then also ignored.
@_spi(Internal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class ErrorDialogFactoryCompletion {

    nonisolated static let defaultTimeoutInterval: TimeInterval = 5

    private var handler: ((CheckpointErrorDialog?) -> Void)?
    private var timeoutTask: Task<Void, Never>?

    init(
        timeoutInterval: TimeInterval = defaultTimeoutInterval,
        onComplete: @escaping @MainActor (CheckpointErrorDialog?) -> Void
    ) {
        self.handler = onComplete
        self.timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeoutInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.invokeOnTimeout()
        }
    }

    /// Delivers the dialog content to the SDK.
    ///
    /// Pass `nil` to use the SDK's default dialog content. Later calls after the first, or calls received
    /// after the timeout has elapsed, are ignored.
    public func complete(with dialog: CheckpointErrorDialog?) {
        self.invoke(dialog, fromTimeout: false)
    }

    private func invoke(_ dialog: CheckpointErrorDialog?, fromTimeout: Bool) {
        if !fromTimeout {
            self.timeoutTask?.cancel()
            self.timeoutTask = nil
        }
        guard let handler = self.handler else { return }
        self.handler = nil
        handler(dialog)
    }

    private func invokeOnTimeout() {
        Logger.warning("ErrorDialogFactory timed out after \(Self.defaultTimeoutInterval) seconds; " +
                       "falling back to the default error dialog.")
        self.invoke(nil, fromTimeout: true)
    }

}

// MARK: - Presentation handler factory

/// Creates an ``ErrorPresentationHandler`` that calls the given factory, waits for its dialog content,
/// then shows the result through the SDK's default presenter.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
func makeErrorDialogFactoryHandler(
    factory: @escaping ErrorDialogFactory,
    preferredUILocaleProvider: @escaping DefaultErrorPresenter.PreferredUILocaleProvider
) -> ErrorPresentationHandler {
    return { params, presentationCompletion in
        let factoryCompletion = ErrorDialogFactoryCompletion { dialog in
            DefaultErrorPresenter
                .makePresenter(for: dialog, preferredUILocaleProvider: preferredUILocaleProvider)
                .present(params: params, completion: presentationCompletion)
        }
        factory(params, factoryCompletion)
    }
}
