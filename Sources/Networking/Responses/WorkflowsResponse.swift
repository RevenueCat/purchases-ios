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

import Foundation

// MARK: - Detail models

struct WorkflowTrigger {

    let name: String?
    let type: String
    let actionId: String?
    let componentId: String?

}

struct WorkflowTriggerAction {

    let type: String
    let stepId: String

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
    let metadata: [String: AnyDecodable]?

}

@_spi(Internal) public struct WorkflowScreen {

    let name: String?
    public let templateName: String
    @DefaultDecodable.Zero
    var _revision: Int
    public var revision: Int { _revision }
    public let assetBaseURL: URL
    public let componentsConfig: PaywallComponentsData.ComponentsConfig
    public let componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary]
    public let defaultLocale: PaywallComponent.LocaleID
    @DefaultDecodable.EmptyDictionary
    var config: [String: AnyDecodable]
    public let offeringId: String?

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

@_spi(Internal) public struct WorkflowFetchResult {

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
        case _revision = "revision"
        case assetBaseURL = "assetBaseUrl"
        case componentsConfig
        case componentsLocalizations
        case defaultLocale
        case config
        case offeringId
    }

}

extension PublishedWorkflow: Codable, Equatable, Sendable {}
extension WorkflowFetchResult: Equatable, Sendable {}

extension PublishedWorkflow: HTTPResponseBody {}
