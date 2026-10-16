//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointResult.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// The result of passing a checkpoint.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CheckpointResult: Sendable {

    /// Information about the presented flow, or `nil` when the checkpoint had nothing to present.
    public let flow: FlowResult?

    init(flow: FlowResult?) {
        self.flow = flow
    }

}
