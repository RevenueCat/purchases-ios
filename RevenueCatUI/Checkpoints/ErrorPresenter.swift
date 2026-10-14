//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/LICENSE-2.0
//
//  ErrorPresenter.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Presents a checkpoint error.
///
/// The presenter owns its UI, while the SDK decides how the Flow proceeds afterwards. Set one globally through
/// ``Purchases/errorPresenter`` or for an individual checkpoint call. When neither is set, the SDK presents errors.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol ErrorPresenter: AnyObject {

    /// Presents a checkpoint error.
    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion)

}

/// Presents a checkpoint error using a closure.
///
/// This is the closure form of an ``ErrorPresenter`` implementation.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias ErrorPresentationHandler = @MainActor (
    ErrorPresentationParams,
    ErrorPresentationCompletion
) -> Void

/// Context for a checkpoint error presentation.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class ErrorPresentationParams {

    /// The identifier of the checkpoint that failed.
    public let checkpointIdentifier: String

    /// The error that occurred.
    public let error: any Error

    /// The custom variables supplied to the checkpoint call.
    public let customVariables: [String: CustomVariableValue]

    /// When the error occurred relative to Flow presentation.
    public let stage: ErrorPresentationStage

    init(
        checkpointIdentifier: String,
        error: any Error,
        customVariables: [String: CustomVariableValue],
        stage: ErrorPresentationStage
    ) {
        self.checkpointIdentifier = checkpointIdentifier
        self.error = error
        self.customVariables = customVariables
        self.stage = stage
    }

}

/// Completes checkpoint error handling.
///
/// Call ``complete()`` exactly once after handling the error. Later calls on the same completion are ignored.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class ErrorPresentationCompletion {

    private let completeHandler: () -> Void
    private var hasCompleted = false

    init(complete: @escaping () -> Void) {
        self.completeHandler = complete
    }

    /// Reports that error presentation has finished.
    ///
    /// The SDK determines how the checkpoint flow proceeds after the presenter finishes.
    public func complete() {
        guard !self.hasCompleted else { return }
        self.hasCompleted = true
        self.completeHandler()
    }

}

extension NSError {

    var isPurchaseCancellation: Bool {
        return self.domain == ErrorCode.errorDomain && self.code == ErrorCode.purchaseCancelledError.rawValue
    }

}
