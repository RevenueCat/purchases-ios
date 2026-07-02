//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeatureEventsRequest+WorkflowEvent.swift

import Foundation

/// Type alias to avoid naming conflict inside `FeatureEventsRequest.WorkflowEvent`.
private typealias StoredWorkflowEvent = WorkflowEvent

extension FeatureEventsRequest {

    /// Khepri-compatible wire format for workflow step lifecycle events.
    struct WorkflowEvent {

        let type: String
        let id: String
        let version: Int
        let eventName: String
        let timestampMs: UInt64
        let appUserID: String
        let context: Context
        let properties: Properties

        // swiftlint:disable nesting
        struct Context {
            let locale: String
        }

        struct Properties {
            let workflowId: String
            let stepId: String
            let traceId: String?
            let fromStepId: String?
            let toStepId: String?
            let entryReason: String?
            let isFirstStep: Bool?
            let isLastStep: Bool?
            let experimentId: String?
            let experimentVariant: String?
            let isLastVariantStep: Bool?
        }
        // swiftlint:enable nesting

    }

}

extension FeatureEventsRequest.WorkflowEvent {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: StoredFeatureEvent) {
        guard storedEvent.feature == .workflows else { return nil }

        guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
            Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
            return nil
        }

        do {
            let event = try JSONDecoder.default.decode(StoredWorkflowEvent.self, from: jsonData)
            let wire = Self.wireFields(for: event)

            self.init(
                type: Self.typeValue,
                id: event.creationData.id.uuidString,
                version: Self.schemaVersion,
                eventName: wire.eventName,
                timestampMs: event.creationData.date.millisecondsSince1970,
                appUserID: storedEvent.userID,
                context: Context(locale: event.data.localeIdentifier),
                properties: Properties(
                    workflowId: event.data.workflowId,
                    stepId: event.data.stepId,
                    traceId: event.data.traceId,
                    fromStepId: wire.fromStepId,
                    toStepId: wire.toStepId,
                    entryReason: wire.entryReason,
                    isFirstStep: event.data.isFirstStep,
                    isLastStep: event.data.isLastStep,
                    experimentId: event.data.experimentId,
                    experimentVariant: event.data.experimentVariant,
                    isLastVariantStep: event.data.isLastVariantStep
                )
            )
        } catch {
            Logger.error(Strings.paywalls.event_cannot_deserialize(error))
            return nil
        }
    }

    /// The event-name and navigation fields that vary per `WorkflowEvent` case. `close` is an
    /// abandonment signal, not a navigation, so it carries no from/to step or entry reason.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private static func wireFields(for event: StoredWorkflowEvent) -> WireFields {
        switch event {
        case .stepStarted:
            return .init(
                eventName: stepStartedEventName,
                fromStepId: event.data.fromStepId,
                toStepId: nil,
                entryReason: event.data.entryReason
            )
        case .stepCompleted:
            return .init(
                eventName: stepCompletedEventName,
                fromStepId: nil,
                toStepId: event.data.toStepId,
                entryReason: nil
            )
        case .close:
            return .init(eventName: closeEventName, fromStepId: nil, toStepId: nil, entryReason: nil)
        }
    }

    private struct WireFields {
        let eventName: String
        let fromStepId: String?
        let toStepId: String?
        let entryReason: String?
    }

    private static let schemaVersion = 1
    private static let typeValue = "workflows"
    private static let stepStartedEventName = "workflow_step_started"
    private static let stepCompletedEventName = "workflow_step_completed"
    private static let closeEventName = "workflow_close"

}

// MARK: - Encodable

extension FeatureEventsRequest.WorkflowEvent: Encodable {

    private enum CodingKeys: String, CodingKey {

        case type
        case id
        case version
        case eventName = "event_name"
        case timestampMs = "timestamp_ms"
        case appUserID = "app_user_id"
        case context
        case properties

    }

}

extension FeatureEventsRequest.WorkflowEvent.Context: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locale, forKey: .locale)
    }

    private enum CodingKeys: String, CodingKey {
        case locale
    }

}

extension FeatureEventsRequest.WorkflowEvent.Properties: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(workflowId, forKey: .workflowId)
        try container.encode(stepId, forKey: .stepId)
        try container.encodeIfPresent(traceId, forKey: .traceId)
        try container.encodeIfPresent(fromStepId, forKey: .fromStepId)
        try container.encodeIfPresent(toStepId, forKey: .toStepId)
        try container.encodeIfPresent(entryReason, forKey: .entryReason)
        try container.encodeIfPresent(isFirstStep, forKey: .isFirstStep)
        try container.encodeIfPresent(isLastStep, forKey: .isLastStep)
        try container.encodeIfPresent(experimentId, forKey: .experimentId)
        try container.encodeIfPresent(experimentVariant, forKey: .experimentVariant)
        try container.encodeIfPresent(isLastVariantStep, forKey: .isLastVariantStep)
    }

    private enum CodingKeys: String, CodingKey {

        case workflowId = "workflow_id"
        case stepId = "step_id"
        case traceId = "trace_id"
        case fromStepId = "from_step_id"
        case toStepId = "to_step_id"
        case entryReason = "entry_reason"
        case isFirstStep = "is_first_step"
        case isLastStep = "is_last_step"
        case experimentId = "experiment_id"
        case experimentVariant = "experiment_variant"
        case isLastVariantStep = "is_last_variant_step"

    }

}
