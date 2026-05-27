//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowEvent.swift

import Foundation

// swiftlint:disable missing_docs

/// Workflow step lifecycle events. Sibling to ``PaywallEvent``. Internal-only.
@_spi(Internal) public enum WorkflowEvent: FeatureEvent {

    var feature: Feature { .workflows }
    var eventDiscriminator: String? { nil }

    case stepStarted(CreationData, Data)
    case stepCompleted(CreationData, Data)

}

extension WorkflowEvent {

    @_spi(Internal) public struct CreationData {

        public var id: UUID
        public var date: Date

        public init(id: UUID = .init(), date: Date = .init()) {
            self.id = id
            self.date = date
        }

    }

}

extension WorkflowEvent {

    @_spi(Internal) public struct Data {

        public var workflowId: String
        public var stepId: String
        /// Not sent to the backend; used for local context only.
        public var workflowType: String?
        /// Not sent to the backend; used for local context only.
        public var stepType: String?
        /// Not sent to the backend; used for local context only.
        public var screenType: [String]
        /// Set for `stepStarted` events; the step navigated from, if any.
        public var fromStepId: String?
        /// Set for `stepCompleted` events; the step navigated to, if any.
        public var toStepId: String?
        /// Set for `stepStarted` events; the reason the step was entered.
        public var entryReason: String?
        public var isFirstStep: Bool?
        public var isLastStep: Bool?

        public init(
            workflowId: String,
            stepId: String,
            workflowType: String? = nil,
            stepType: String? = nil,
            screenType: [String] = [],
            fromStepId: String? = nil,
            toStepId: String? = nil,
            entryReason: String? = nil,
            isFirstStep: Bool? = nil,
            isLastStep: Bool? = nil
        ) {
            self.workflowId = workflowId
            self.stepId = stepId
            self.workflowType = workflowType
            self.stepType = stepType
            self.screenType = screenType
            self.fromStepId = fromStepId
            self.toStepId = toStepId
            self.entryReason = entryReason
            self.isFirstStep = isFirstStep
            self.isLastStep = isLastStep
        }

    }

}

extension WorkflowEvent {

    @_spi(Internal) public var creationData: CreationData {
        switch self {
        case let .stepStarted(creationData, _): return creationData
        case let .stepCompleted(creationData, _): return creationData
        }
    }

    @_spi(Internal) public var data: Data {
        switch self {
        case let .stepStarted(_, data): return data
        case let .stepCompleted(_, data): return data
        }
    }

}

extension WorkflowEvent.CreationData: Equatable, Codable, Sendable {}
extension WorkflowEvent.Data: Equatable, Codable, Sendable {}
extension WorkflowEvent: Equatable, Codable, Sendable {}
