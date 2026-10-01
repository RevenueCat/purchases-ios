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

/// Presents an error from a RevenueCat-presented checkpoint flow.
///
/// The presenter owns its UI and decides how the flow proceeds afterwards.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol ErrorPresenter: AnyObject {

    /// Presents a checkpoint error and decides how the flow proceeds.
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

    /// The error that prevented the checkpoint from completing.
    public let error: any Error

    /// The custom variables supplied to the checkpoint call.
    public let customVariables: [String: CustomVariableValue]

    /// Whether the flow remains on screen and can be retried after this error.
    public let flowCanContinue: Bool

    init(
        checkpointIdentifier: String,
        error: any Error,
        customVariables: [String: CustomVariableValue],
        flowCanContinue: Bool
    ) {
        self.checkpointIdentifier = checkpointIdentifier
        self.error = error
        self.customVariables = customVariables
        self.flowCanContinue = flowCanContinue
    }

}

/// Completes checkpoint error handling.
///
/// Call ``complete(_:)`` exactly once after handling the error. Later calls for the same checkpoint are ignored.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class ErrorPresentationCompletion {

    private let complete: (Result) -> Void

    init(complete: @escaping (Result) -> Void) {
        self.complete = complete
    }

    /// Reports how the checkpoint flow should proceed.
    public func complete(_ result: Result) {
        self.complete(result)
    }

    /// A requested action following error presentation.
    public struct Result: Sendable {

        fileprivate enum Action: Sendable {
            case retry
            case continued
            case navigateBack
        }

        fileprivate let action: Action

        private init(_ action: Action) {
            self.action = action
        }

        /// Resumes the flow at the current paywall so the user can try again.
        public static let retry = Self(.retry)

        /// Ends the flow as if the user had closed it and lets the checkpoint continue.
        public static let continued = Self(.continued)

        /// Navigates to the previous workflow step, or ends the flow if there is no prior step.
        public static let navigateBack = Self(.navigateBack)
    }

}
