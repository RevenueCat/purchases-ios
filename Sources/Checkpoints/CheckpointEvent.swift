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

/// Checkpoint events. Sent through the shared feature events pipeline, which is also how the backend learns
/// a checkpoint exists: hits register it, there is no separate registration call.
enum CheckpointEvent: FeatureEvent {

    var feature: Feature { .checkpoints }

    var eventDiscriminator: String? { nil }

    /// A checkpoint was hit.
    case hit(Data)

}

extension CheckpointEvent {

    /// The content of a ``CheckpointEvent``.
    struct Data {

        var id: UUID
        var identifier: String
        var date: Date

        init(id: UUID = .init(), identifier: String, date: Date) {
            self.id = id
            self.identifier = identifier
            self.date = date
        }

    }

}

extension CheckpointEvent {

    /// - Returns: the underlying ``CheckpointEvent/Data-swift.struct`` for this event.
    var data: Data {
        switch self {
        case let .hit(data): return data
        }
    }

    /// The value khepri discriminates the analytics events union on. Single source of truth for both the wire
    /// format and ``FeatureEvent/toMap()``, so a new case has to be given one here before it compiles.
    var eventType: String {
        switch self {
        case .hit: return "checkpoint_hit"
        }
    }

}

extension CheckpointEvent.Data: Equatable, Codable, Sendable {}
extension CheckpointEvent: Equatable, Codable, Sendable {}
