//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowsResponse.swift
//
//  Created by RevenueCat.
// swiftlint:disable missing_docs

import Foundation

// MARK: - Detail models

@_spi(Internal) public enum WorkflowTriggerType: String, Codable, Equatable, Sendable {
    case onPress = "on_press"
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "on_press":
            self = .onPress
        default:
            Logger.warn(Strings.backendError.unknown_workflow_trigger_type(type: value))
            self = .unknown
        }
    }
}

@_spi(Internal) public struct WorkflowTrigger {

    public let name: String?
    public let type: WorkflowTriggerType
    public let actionId: String?
    public let componentId: String?

    @_spi(Internal) public init(
        name: String?,
        type: WorkflowTriggerType,
        actionId: String?,
        componentId: String?
    ) {
        self.name = name
        self.type = type
        self.actionId = actionId
        self.componentId = componentId
    }

}

@_spi(Internal) public enum WorkflowTriggerAction: Equatable, Sendable {
    case step(stepId: String)
    case unknown
}

@_spi(Internal) public struct WorkflowStep {

    public let id: String
    let type: String
    public let screenId: String?
    @DefaultDecodable.EmptyArray
    var screenType: [String]
    @DefaultDecodable.EmptyDictionary
    var paramValues: [String: AnyDecodable]
    @DefaultDecodable.EmptyArray
    var triggers: [WorkflowTrigger]
    @DefaultDecodable.EmptyDictionary
    var outputs: [String: AnyDecodable]
    @DefaultDecodable.EmptyDictionary
    var triggerActions: [String: WorkflowTriggerAction]

    public var stepTriggers: [WorkflowTrigger] { triggers }
    public var stepTriggerActions: [String: WorkflowTriggerAction] { triggerActions }
    public var stepScreenType: [String] { screenType }
    let metadata: [String: AnyDecodable]?

    // `screenType`, `paramValues`, `outputs`, and `metadata` carry backend step config that the
    // renderer doesn't read, and `paramValues`/`outputs`/`metadata` are typed with the internal
    // `AnyDecodable`, so they're defaulted rather than exposed.
    @_spi(Internal) public init(
        id: String,
        type: String,
        screenId: String?,
        triggers: [WorkflowTrigger] = [],
        triggerActions: [String: WorkflowTriggerAction] = [:]
    ) {
        self.id = id
        self.type = type
        self.screenId = screenId
        self.screenType = []
        self.paramValues = [:]
        self.triggers = triggers
        self.outputs = [:]
        self.triggerActions = triggerActions
        self.metadata = nil
    }

}

@_spi(Internal) public struct WorkflowScreen {

    public let name: String?
    public let templateName: String
    @DefaultDecodable.Zero
    // swiftlint:disable:next identifier_name
    var _revision: Int
    public var revision: Int { _revision }
    public let assetBaseURL: URL
    public let componentsConfig: PaywallComponentsData.ComponentsConfig
    public let componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary]
    public let defaultLocale: PaywallComponent.LocaleID
    @DefaultDecodable.EmptyDictionary
    var config: [String: AnyDecodable]
    public let offeringIdentifier: String?
    public let exitOffers: ExitOffers?

    // `config` carries backend screen config the renderer doesn't read and is typed with the
    // internal `AnyDecodable`, so it's defaulted rather than exposed.
    @_spi(Internal) public init(
        name: String?,
        templateName: String,
        revision: Int = 0,
        assetBaseURL: URL,
        componentsConfig: PaywallComponentsData.ComponentsConfig,
        componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary],
        defaultLocale: PaywallComponent.LocaleID,
        offeringIdentifier: String?,
        exitOffers: ExitOffers? = nil
    ) {
        self.name = name
        self.templateName = templateName
        self._revision = revision
        self.assetBaseURL = assetBaseURL
        self.componentsConfig = componentsConfig
        self.componentsLocalizations = componentsLocalizations
        self.defaultLocale = defaultLocale
        self.config = [:]
        self.offeringIdentifier = offeringIdentifier
        self.exitOffers = exitOffers
    }

}

@_spi(Internal) public struct PublishedWorkflow {

    public let id: String
    let displayName: String
    public let initialStepId: String
    public let singleStepFallbackId: String?
    public let steps: [String: WorkflowStep]
    public let screens: [String: WorkflowScreen]
    public let uiConfig: UIConfig
    let contentMaxWidth: Int?
    let metadata: [String: AnyDecodable]?

    // `metadata` is typed with the internal `AnyDecodable`, so it's defaulted rather than exposed.
    @_spi(Internal) public init(
        id: String,
        displayName: String,
        initialStepId: String,
        singleStepFallbackId: String?,
        steps: [String: WorkflowStep],
        screens: [String: WorkflowScreen],
        uiConfig: UIConfig,
        contentMaxWidth: Int? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.initialStepId = initialStepId
        self.singleStepFallbackId = singleStepFallbackId
        self.steps = steps
        self.screens = screens
        self.uiConfig = uiConfig
        self.contentMaxWidth = contentMaxWidth
        self.metadata = nil
    }

}

@_spi(Internal) public struct WorkflowDataResult {

    public let workflow: PublishedWorkflow
    public let enrolledVariants: [String: String]?

}

// MARK: - Codable

extension WorkflowTrigger: Codable, Equatable, Sendable {}

extension WorkflowTriggerAction: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
        case stepId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "step":
            let stepId = try container.decode(String.self, forKey: .stepId)
            self = .step(stepId: stepId)
        default:
            Logger.warn(Strings.backendError.unknown_workflow_trigger_action_type(type: type))
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .step(let stepId):
            try container.encode("step", forKey: .type)
            try container.encode(stepId, forKey: .stepId)
        case .unknown:
            try container.encode("unknown", forKey: .type)
        }
    }

}
extension WorkflowStep: Codable, Equatable, Sendable {}

extension WorkflowScreen: Codable, Equatable, Sendable {

    private enum CodingKeys: String, CodingKey {
        case name
        case templateName
        // swiftlint:disable:next identifier_name
        case _revision = "revision"
        case assetBaseURL = "assetBaseUrl"
        case componentsConfig
        case componentsLocalizations
        case defaultLocale
        case config
        case offeringIdentifier
        case exitOffers
    }

}

extension PublishedWorkflow: Codable, Equatable, Sendable {}
extension WorkflowDataResult: Codable, Equatable, Sendable {}

extension PublishedWorkflow: HTTPResponseBody {}

// MARK: - List models

@_spi(Internal) public struct WorkflowSummary {

    public let id: String
    public let displayName: String
    public let offeringId: String?
    public let prefetch: Bool

}

@_spi(Internal) public struct WorkflowsListResponse {

    public let workflows: [WorkflowSummary]

}

// MARK: - Codable

extension WorkflowSummary: Codable, Equatable, Sendable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.offeringId = try container.decodeIfPresent(String.self, forKey: .offeringId)
        self.prefetch = try container.decodeIfPresent(Bool.self, forKey: .prefetch) ?? false
    }

}

extension WorkflowsListResponse: Codable, Equatable, Sendable {}

extension WorkflowsListResponse: HTTPResponseBody {}
