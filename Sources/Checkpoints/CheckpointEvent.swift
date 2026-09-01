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

/// What a checkpoint resolved to, reported in the `result` field of a checkpoint hit.
enum CheckpointHitResult: String {

    case workflow
    case offering
    case noMatch = "no_match"
    case configurationUnavailable = "configuration_unavailable"
    case unknownCheckpoint = "unknown_checkpoint"

}

extension CheckpointEvent {

    /// The content of a ``CheckpointEvent``.
    ///
    /// `date` is when the user reached the checkpoint, not when the event was created, so hit volume over time
    /// stays comparable with events recorded before the outcome was attached.
    struct Data {

        var id: UUID
        var identifier: String
        var date: Date
        /// What the checkpoint resolved to. `nil` only for hits stored by an SDK version that recorded them
        /// before evaluating the checkpoint.
        var result: CheckpointHitResult?
        /// The workflow the checkpoint matched, when it matched one.
        var workflowID: String?
        /// The offering the checkpoint resolved to, when it resolved to one.
        var offeringID: String?

        init(
            id: UUID = .init(),
            identifier: String,
            date: Date,
            result: CheckpointHitResult? = nil,
            workflowID: String? = nil,
            offeringID: String? = nil
        ) {
            self.id = id
            self.identifier = identifier
            self.date = date
            self.result = result
            self.workflowID = workflowID
            self.offeringID = offeringID
        }

    }

}

extension CheckpointEvent.Data {

    // The `ID` suffix has to be spelled out: the events store encodes with `convertToSnakeCase` and decodes with
    // `convertFromSnakeCase`, which turns `workflow_id` back into `workflowId` and would otherwise miss these
    // keys on the way in.
    private enum CodingKeys: String, CodingKey {

        case id
        case identifier
        case date
        case result
        case workflowID = "workflowId"
        case offeringID = "offeringId"

    }

}

extension CheckpointEvent {

    /// Builds the hit event for a resolved checkpoint.
    ///
    /// - Parameter date: when the checkpoint was reached, captured before resolution started.
    static func hit(identifier: String, date: Date, resolution: CheckpointResolution) -> CheckpointEvent {
        switch resolution {
        case let .matchedWorkflow(resolved):
            return .hit(.init(identifier: identifier,
                              date: date,
                              result: .workflow,
                              workflowID: resolved.workflow.id,
                              offeringID: resolved.offering.identifier))

        case let .matchedOffering(offering):
            return .hit(.init(identifier: identifier,
                              date: date,
                              result: .offering,
                              offeringID: offering.identifier))

        case let .noAction(reason):
            return .hit(.init(identifier: identifier, date: date, result: .init(reason)))
        }
    }

}

extension CheckpointHitResult {

    init(_ reason: CheckpointResolutionReason) {
        switch reason {
        case .noMatch: self = .noMatch
        // A checkpoint reached while remote config is off is, for analytics, the same
        // story as configuration that could not be read — and it is what Android
        // reports for its own kill switch.
        case .configurationUnavailable, .disabled: self = .configurationUnavailable
        case .unknownCheckpoint: self = .unknownCheckpoint
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

extension CheckpointHitResult: Equatable, Codable, Sendable {}
extension CheckpointEvent.Data: Equatable, Codable, Sendable {}
extension CheckpointEvent: Equatable, Codable, Sendable {}
