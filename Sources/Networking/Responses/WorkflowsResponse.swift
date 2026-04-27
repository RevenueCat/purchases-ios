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
        self = WorkflowTriggerType(rawValue: value) ?? .unknown
    }
}

@_spi(Internal) public enum WorkflowTriggerActionType: String, Codable, Equatable, Sendable {
    case step
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = WorkflowTriggerActionType(rawValue: value) ?? .unknown
    }
}

@_spi(Internal) public struct WorkflowTrigger {

    public let name: String?
    public let type: WorkflowTriggerType
    public let actionId: String?
    public let componentId: String?

}

@_spi(Internal) public struct WorkflowTriggerAction {

    public let type: WorkflowTriggerActionType
    public let stepId: String?

}

@_spi(Internal) public struct WorkflowStep {

    public let id: String
    let type: String
    public let screenId: String?
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
    let metadata: [String: AnyDecodable]?

}

@_spi(Internal) public struct WorkflowScreen {

    let name: String?
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

}

@_spi(Internal) public struct PublishedWorkflow {

    public let id: String
    let displayName: String
    public let initialStepId: String
    public let steps: [String: WorkflowStep]
    public let screens: [String: WorkflowScreen]
    public let uiConfig: UIConfig
    let contentMaxWidth: Int?
    let metadata: [String: AnyDecodable]?

}

@_spi(Internal) public struct WorkflowDataResult {

    public let workflow: PublishedWorkflow
    public let enrolledVariants: [String: String]?

}

// MARK: - Codable

extension WorkflowTrigger: Codable, Equatable, Sendable {}
extension WorkflowTriggerAction: Codable, Equatable, Sendable {}
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
    }

}

extension PublishedWorkflow: Codable, Equatable, Sendable {}
extension WorkflowDataResult: Equatable, Sendable {}

extension PublishedWorkflow: HTTPResponseBody {}
