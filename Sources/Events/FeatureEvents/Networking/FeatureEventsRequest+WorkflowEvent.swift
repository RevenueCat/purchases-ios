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

        let discriminator: String
        let id: String
        let eventName: String
        let timestampMs: UInt64
        let appUserID: String
        let context: Context
        let properties: Properties

        // swiftlint:disable nesting
        struct Context {
            let locale: String?
        }

        struct Properties {
            let workflowId: String
            let stepId: String
            let fromStepId: String?
            let toStepId: String?
            let entryReason: String?
            let isFirstStep: Bool?
            let isLastStep: Bool?
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

            let eventName: String
            let fromStepId: String?
            let toStepId: String?
            let entryReason: String?

            switch event {
            case .stepStarted:
                eventName = Self.stepStartedEventName
                fromStepId = event.data.fromStepId
                toStepId = nil
                entryReason = event.data.entryReason
            case .stepCompleted:
                eventName = Self.stepCompletedEventName
                fromStepId = nil
                toStepId = event.data.toStepId
                entryReason = nil
            }

            self.init(
                discriminator: Self.discriminatorValue,
                id: event.creationData.id.uuidString,
                eventName: eventName,
                timestampMs: event.creationData.date.millisecondsSince1970,
                appUserID: storedEvent.userID,
                context: Context(locale: nil),
                properties: Properties(
                    workflowId: event.data.workflowId,
                    stepId: event.data.stepId,
                    fromStepId: fromStepId,
                    toStepId: toStepId,
                    entryReason: entryReason,
                    isFirstStep: event.data.isFirstStep,
                    isLastStep: event.data.isLastStep
                )
            )
        } catch {
            Logger.error(Strings.paywalls.event_cannot_deserialize(error))
            return nil
        }
    }

    private static let discriminatorValue = "workflows"
    private static let stepStartedEventName = "workflows_step_started"
    private static let stepCompletedEventName = "workflows_step_completed"

}

// MARK: - Encodable

extension FeatureEventsRequest.WorkflowEvent: Encodable {

    private enum CodingKeys: String, CodingKey {

        case discriminator
        case id
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
        try container.encodeIfPresent(locale, forKey: .locale)
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
        try container.encodeIfPresent(fromStepId, forKey: .fromStepId)
        try container.encodeIfPresent(toStepId, forKey: .toStepId)
        try container.encodeIfPresent(entryReason, forKey: .entryReason)
        try container.encodeIfPresent(isFirstStep, forKey: .isFirstStep)
        try container.encodeIfPresent(isLastStep, forKey: .isLastStep)
    }

    private enum CodingKeys: String, CodingKey {

        case workflowId = "workflow_id"
        case stepId = "step_id"
        case fromStepId = "from_step_id"
        case toStepId = "to_step_id"
        case entryReason = "entry_reason"
        case isFirstStep = "is_first_step"
        case isLastStep = "is_last_step"

    }

}
