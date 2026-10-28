//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointErrorDialog.swift
//
//  Created by Cesar de la Vega.
//

import Foundation

/// The content of a checkpoint error dialog supplied by an ``ErrorDialogFactory``.
///
/// When an ``ErrorDialogFactory`` provides a non-nil value, the SDK shows a dialog with these strings through
/// the default error presenter. Return `nil` from the factory to use the SDK's default localized content.
@_spi(Internal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CheckpointErrorDialog: Sendable, Equatable {

    /// The dialog's message.
    public let message: String

    /// The title of the dismiss button.
    public let buttonTitle: String

    /// Creates a ``CheckpointErrorDialog`` with the given content.
    ///
    /// - Parameters:
    ///   - message: The dialog's message.
    ///   - buttonTitle: The title of the dismiss button.
    @_spi(Internal)
    public init(message: String, buttonTitle: String) {
        self.message = message
        self.buttonTitle = buttonTitle
    }

}
