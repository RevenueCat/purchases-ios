//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FlowEvent.swift
//

import Foundation
@_spi(Internal) import RevenueCat

// swiftlint:disable missing_docs

public typealias FlowEventHandler = @MainActor @Sendable (_ event: FlowEvent) -> Void

/// A flow step or paywall lifecycle event.
///
/// A flow is the whole paywall experience, from one step to many. A paywall shown without a flow reports only
/// `paywall_impression` and `paywall_close`.
@objc(RCFlowEvent)
public final class FlowEvent: NSObject, @unchecked Sendable {

    /// The event as snake-case keys (``Key/name``) for analytics SDKs; keys that do not apply are absent.
    @objc public let rawProperties: [String: Any]

    /// Names for the app callback, kept separately from the analytics event.
    struct PaywallNames: Sendable {
        let flowName: String?
        let screenName: String?
    }

    init(rawProperties: [String: Any]) {
        self.rawProperties = rawProperties
        super.init()
    }

    convenience init(_ event: WorkflowEvent) {
        let data = event.data
        var properties: [String: Any] = [
            Keys.timestamp.name: UInt64(event.creationData.date.timeIntervalSince1970 * 1000),
            Keys.flowId.name: data.workflowId,
            Keys.stepId.name: data.stepId,
            Keys.locale.name: data.localeIdentifier
        ]
        switch event {
        case .stepStarted:
            properties[Keys.eventType.name] = EventTypes.flowStepStarted
            Self.insertIfPresent(data.fromStepId, for: Keys.fromStepId, into: &properties)
            Self.insertIfPresent(data.entryReason, for: Keys.entryReason, into: &properties)
        case .stepCompleted:
            properties[Keys.eventType.name] = EventTypes.flowStepCompleted
            Self.insertIfPresent(data.toStepId, for: Keys.toStepId, into: &properties)
        case .close:
            properties[Keys.eventType.name] = EventTypes.flowClose
        }
        Self.insertIfPresent(data.traceId, for: Keys.traceId, into: &properties)
        Self.insertIfPresent(data.workflowName, for: Keys.flowName, into: &properties)
        Self.insertIfPresent(data.stepType, for: Keys.stepType, into: &properties)
        Self.insertIfPresent(data.screenType.isEmpty ? nil : data.screenType, for: Keys.screenType, into: &properties)
        Self.insertIfPresent(data.screenName, for: Keys.screenName, into: &properties)
        Self.insertIfPresent(data.experiment?.experimentId, for: Keys.experimentId, into: &properties)
        Self.insertIfPresent(data.experiment?.experimentVariant, for: Keys.experimentVariant, into: &properties)
        Self.insertIfPresent(data.isFirstStep, for: Keys.isFirstStep, into: &properties)
        Self.insertIfPresent(data.isLastStep, for: Keys.isLastStep, into: &properties)
        self.init(rawProperties: properties)
    }

    convenience init?(_ event: PaywallEvent, names: PaywallNames?) {
        let eventType: String
        switch event {
        case .impression: eventType = EventTypes.paywallImpression
        case .close: eventType = EventTypes.paywallClose
        default: return nil
        }
        let data = event.data
        var properties = event.paywallMap().filter { Keys.paywallEventKeys.contains($0.key) }
        properties[Keys.eventType.name] = eventType
        Self.insertIfPresent(data.workflowId, for: Keys.flowId, into: &properties)
        Self.insertIfPresent(data.stepId, for: Keys.stepId, into: &properties)
        Self.insertIfPresent(data.traceId, for: Keys.traceId, into: &properties)
        Self.insertIfPresent(names?.flowName, for: Keys.flowName, into: &properties)
        Self.insertIfPresent(names?.screenName, for: Keys.screenName, into: &properties)
        self.init(rawProperties: properties)
    }

    private static func insertIfPresent<Value>(_ value: Value?, for key: Key<Value>, into output: inout [String: Any]) {
        if let value {
            output[key.name] = value
        }
    }

    /// The value for `key`, or `nil` when it does not apply to this event.
    public func property<Value>(for key: Key<Value>) -> Value? {
        return self.rawProperties[key.name] as? Value
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? FlowEvent else { return false }
        return (self.rawProperties as NSDictionary).isEqual(to: other.rawProperties)
    }

    public override var hash: Int {
        return (self.rawProperties as NSDictionary).hash
    }

    public override var description: String {
        return "FlowEvent(\(self.rawProperties))"
    }

    public struct Key<Value>: Sendable {

        public let name: String

        init(_ name: String) {
            self.name = name
        }

    }

    public struct Keys {
        private init() {}

        /// One of ``EventTypes``.
        public static let eventType = Key<String>("event_type")
        /// Milliseconds since the epoch.
        public static let timestamp = Key<UInt64>("timestamp")
        public static let flowId = Key<String>("flow_id")
        public static let flowName = Key<String>("flow_name")
        public static let stepId = Key<String>("step_id")
        public static let stepType = Key<String>("step_type")
        public static let screenType = Key<[String]>("screen_type")
        public static let screenName = Key<String>("screen_name")
        public static let traceId = Key<String>("trace_id")
        public static let locale = Key<String>("locale")
        public static let experimentId = Key<String>("experiment_id")
        public static let experimentVariant = Key<String>("experiment_variant")
        public static let fromStepId = Key<String>("from_step_id")
        public static let toStepId = Key<String>("to_step_id")
        public static let entryReason = Key<String>("entry_reason")
        public static let isFirstStep = Key<Bool>("is_first_step")
        public static let isLastStep = Key<Bool>("is_last_step")

        public static let paywallId = Key<String>("paywall_id")
        public static let offeringId = Key<String>("offering_id")
        public static let paywallRevision = Key<Int>("paywall_revision")
        public static let sessionId = Key<String>("session_id")
        public static let displayMode = Key<String>("display_mode")
        public static let darkMode = Key<Bool>("dark_mode")

        static let paywallEventKeys: Set<String> = [
            timestamp.name, locale.name, paywallId.name, offeringId.name, paywallRevision.name,
            sessionId.name, displayMode.name, darkMode.name
        ]
    }

    /// Known values of ``Keys/eventType``.
    public struct EventTypes {
        private init() {}

        public static let flowStepStarted = "flow_step_started"
        public static let flowStepCompleted = "flow_step_completed"
        public static let flowClose = "flow_close"
        public static let paywallImpression = "paywall_impression"
        public static let paywallClose = "paywall_close"
    }

}
