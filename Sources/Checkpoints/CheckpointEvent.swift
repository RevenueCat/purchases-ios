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

enum CheckpointType: String, Equatable, Codable, Sendable {

    case standard
    case custom

}

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
        var checkpointType: CheckpointType
        var result: CheckpointHitResult
        var workflowID: String?
        var offeringID: String?
        var checkpointRuleID: String?
        var traceID: String?

        init(
            id: UUID = .init(),
            identifier: String,
            date: Date,
            checkpointType: CheckpointType = .custom,
            result: CheckpointHitResult,
            workflowID: String? = nil,
            offeringID: String? = nil,
            checkpointRuleID: String? = nil,
            traceID: String? = nil
        ) {
            self.id = id
            self.identifier = identifier
            self.date = date
            self.checkpointType = checkpointType
            self.result = result
            self.workflowID = workflowID
            self.offeringID = offeringID
            self.checkpointRuleID = checkpointRuleID
            self.traceID = traceID
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

    // The store encodes with `convertToSnakeCase` and decodes with `convertFromSnakeCase`, so `workflowID`
    // comes back as `workflowId`. Without these the ids decode as nil.
    private enum CodingKeys: String, CodingKey {

        case id
        case identifier
        case date
        case checkpointType
        case result
        case workflowID = "workflowId"
        case offeringID = "offeringId"
        case checkpointRuleID = "checkpointRuleId"
        case traceID = "traceId"

    }

}

extension CheckpointEvent.Data: Equatable, Codable, Sendable {}
extension CheckpointEvent: Equatable, Codable, Sendable {}

extension CheckpointEvent.Data {

    init(identifier: String, date: Date, resolved: ResolvedCheckpoint) {
        switch resolved.resolution {
        case let .matchedWorkflow(matched):
            self.init(
                identifier: identifier,
                date: date,
                result: .presentUI,
                workflowID: matched.workflow.id,
                checkpointRuleID: resolved.checkpointRuleID,
                traceID: resolved.traceID
            )

        case let .matchedOffering(offering):
            self.init(
                identifier: identifier,
                date: date,
                result: .returnData,
                offeringID: offering.identifier,
                checkpointRuleID: resolved.checkpointRuleID,
                traceID: resolved.traceID
            )

        case .matchedAd:
            // Like an offering, an ad step is handed to the app's registered presenter rather than presented
            // by RevenueCat UI.
            self.init(
                identifier: identifier,
                date: date,
                result: .returnData,
                checkpointRuleID: resolved.checkpointRuleID
            )

        case let .noAction(reason):
            self.init(
                identifier: identifier,
                date: date,
                result: .init(reason),
                traceID: resolved.traceID
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
