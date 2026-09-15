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

/// How the checkpoint was declared.
enum CheckpointType: String, Equatable, Codable, Sendable {

    case standard
    case custom

}

/// What the SDK did with the checkpoint. Named after the action rather than the match, so the backend
/// can tell a presented UI from data handed back to the app.
enum CheckpointHitResult: String, Equatable, Codable, Sendable {

    case presentUI = "present_ui"
    case returnData = "return_data"
    case noMatch = "no_match"
    case configurationUnavailable = "configuration_unavailable"
    case unknownCheckpoint = "unknown_checkpoint"

}

extension CheckpointEvent {

    /// The content of a ``CheckpointEvent``.
    struct Data {

        var id: UUID
        var identifier: String
        var date: Date
        /// `nil` only for hits stored by an SDK version that predates the field.
        var checkpointType: CheckpointType?
        /// `nil` only for hits stored by an SDK version that recorded the hit before resolving it.
        var result: CheckpointHitResult?
        /// Set only when the checkpoint resolved to a workflow.
        var workflowID: String?
        /// Set only when the checkpoint resolved to an offering.
        var offeringID: String?
        /// Set only when a rule was actually served.
        var checkpointRuleID: String?

        init(
            id: UUID = .init(),
            identifier: String,
            date: Date,
            checkpointType: CheckpointType? = nil,
            result: CheckpointHitResult? = nil,
            workflowID: String? = nil,
            offeringID: String? = nil,
            checkpointRuleID: String? = nil
        ) {
            self.id = id
            self.identifier = identifier
            self.date = date
            self.checkpointType = checkpointType
            self.result = result
            self.workflowID = workflowID
            self.offeringID = offeringID
            self.checkpointRuleID = checkpointRuleID
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

extension CheckpointEvent.Data {

    // The `ID` suffix has to be spelled out: the events store encodes with `convertToSnakeCase` and decodes
    // with `convertFromSnakeCase`, so `workflow_id` comes back as `workflowId` and would miss these keys.
    private enum CodingKeys: String, CodingKey {

        case id
        case identifier
        case date
        case checkpointType
        case result
        case workflowID = "workflowId"
        case offeringID = "offeringId"
        case checkpointRuleID = "checkpointRuleId"

    }

}

extension CheckpointEvent.Data: Equatable, Codable, Sendable {}
extension CheckpointEvent: Equatable, Codable, Sendable {}

extension CheckpointEvent.Data {

    /// Builds the hit content for a resolved checkpoint.
    init(identifier: String, date: Date, resolved: ResolvedCheckpoint) {
        switch resolved.resolution {
        case let .matchedWorkflow(matched):
            self.init(
                identifier: identifier,
                date: date,
                checkpointType: .custom,
                result: .presentUI,
                workflowID: matched.workflow.id,
                checkpointRuleID: resolved.checkpointRuleID
            )

        case let .matchedOffering(offering):
            self.init(
                identifier: identifier,
                date: date,
                checkpointType: .custom,
                result: .returnData,
                offeringID: offering.identifier,
                checkpointRuleID: resolved.checkpointRuleID
            )

        case let .noAction(reason):
            self.init(
                identifier: identifier,
                date: date,
                checkpointType: .custom,
                result: .init(reason)
            )
        }
    }

}

private extension CheckpointHitResult {

    init(_ reason: CheckpointResolutionReason) {
        switch reason {
        case .noMatch: self = .noMatch
        case .configurationUnavailable: self = .configurationUnavailable
        case .unknownCheckpoint: self = .unknownCheckpoint
        }
    }

}
