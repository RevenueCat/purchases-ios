//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorPresentationStage.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// When an error handed to an ``ErrorPresenter`` occurred relative to Flow presentation.
///
/// The stage allows the presenter to tailor its message to the customer. The SDK determines what happens after error
/// presentation finishes based on the error and the state of the Flow.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ErrorPresentationStage: Hashable, Sendable {

    private let name: String

    private init(_ name: String) {
        self.name = name
    }

    /// The error occurred before the Flow was presented.
    public static let beforeFlowPresentation = Self("beforeFlowPresentation")

    /// The error occurred while the Flow was presented.
    public static let duringFlowPresentation = Self("duringFlowPresentation")

    /// The error occurred after the Flow ended.
    public static let afterFlowPresentation = Self("afterFlowPresentation")

}
