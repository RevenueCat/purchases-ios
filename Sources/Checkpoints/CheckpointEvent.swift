//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointEvent.swift

import Foundation

/// Records that a checkpoint was hit. Sent through the shared feature events pipeline, which is also how the
/// backend learns the checkpoint exists: hits register it, there is no separate registration call.
struct CheckpointEvent: FeatureEvent {

    var feature: Feature { .checkpoints }

    var eventDiscriminator: String? { nil }

    let id: UUID
    let identifier: String
    let date: Date

    init(id: UUID = .init(), identifier: String, date: Date) {
        self.id = id
        self.identifier = identifier
        self.date = date
    }

}

extension CheckpointEvent: Equatable, Codable, Sendable {}
