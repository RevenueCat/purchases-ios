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

/// Whether a checkpoint is one RevenueCat defines or one the app declares.
///
/// Every checkpoint is `custom` today. `standard` is declared so this vocabulary and the backend's stay in step,
/// and so producing it later is a one-line change rather than a new type.
enum CheckpointType: String {

    case standard
    case custom

}

/// What the SDK did after resolving a checkpoint, reported in the `result` field of a checkpoint hit.
enum CheckpointHitResult: String {

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
        /// Whether the checkpoint is one RevenueCat defines or one the app declares. `nil` only for hits stored
        /// by an SDK version that predates the field.
        var checkpointType: CheckpointType?
        /// What the checkpoint resolved to. `nil` only for hits stored by an SDK version that recorded them
        /// before evaluating the checkpoint.
        var result: CheckpointHitResult?
        /// The workflow the checkpoint matched, when it matched one.
        var workflowID: String?
        /// The offering the checkpoint resolved to, when it resolved to one.
        var offeringID: String?
        /// The checkpoint rule that was served, when the checkpoint matched one.
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

extension CheckpointEvent.Data {

    // The `ID` suffix has to be spelled out: the events store encodes with `convertToSnakeCase` and decodes with
    // `convertFromSnakeCase`, which turns `workflow_id` back into `workflowId` and would otherwise miss these
    // keys on the way in.
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

extension CheckpointEvent {

    /// Builds the hit event for a resolved checkpoint.
    static func hit(identifier: String, date: Date, resolved: ResolvedCheckpoint) -> CheckpointEvent {
        switch resolved.resolution {
        case let .matchedWorkflow(matched):
            return .hit(.init(identifier: identifier,
                              date: date,
                              checkpointType: .custom,
                              result: .presentUI,
                              workflowID: matched.workflow.id,
                              offeringID: matched.offering.identifier,
                              checkpointRuleID: resolved.checkpointRuleID))

        case let .matchedOffering(offering):
            return .hit(.init(identifier: identifier,
                              date: date,
                              checkpointType: .custom,
                              result: .returnData,
                              offeringID: offering.identifier,
                              checkpointRuleID: resolved.checkpointRuleID))

        case let .noAction(reason):
            return .hit(.init(identifier: identifier,
                              date: date,
                              checkpointType: .custom,
                              result: .init(reason)))
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

extension CheckpointType: Equatable, Codable, Sendable {}
extension CheckpointHitResult: Equatable, Codable, Sendable {}
extension CheckpointEvent.Data: Equatable, Codable, Sendable {}
extension CheckpointEvent: Equatable, Codable, Sendable {}
