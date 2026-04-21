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

struct WorkflowStep {

    let id: String
    let type: String
    let screenId: String?
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

struct WorkflowScreen {

    let name: String?
    let templateName: String
    @DefaultDecodable.Zero
    var revision: Int
    let assetBaseURL: URL
    let componentsConfig: PaywallComponentsData.ComponentsConfig
    let componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary]
    let defaultLocale: PaywallComponent.LocaleID
    @DefaultDecodable.EmptyDictionary
    var config: [String: AnyDecodable]
    let offeringId: String?

}

struct PublishedWorkflow {

    let id: String
    let displayName: String
    let initialStepId: String
    let steps: [String: WorkflowStep]
    let screens: [String: WorkflowScreen]
    let uiConfig: UIConfig
    let contentMaxWidth: Int?
    let metadata: [String: AnyDecodable]?

}

struct WorkflowFetchResult {

    let workflow: PublishedWorkflow
    let enrolledVariants: [String: String]?

}

// MARK: - Codable

extension WorkflowTrigger: Codable, Equatable, Sendable {}
extension WorkflowTriggerAction: Codable, Equatable, Sendable {}
extension WorkflowStep: Codable, Equatable, Sendable {}

extension WorkflowScreen: Codable, Equatable, Sendable {

    private enum CodingKeys: String, CodingKey {
        case name
        case templateName
        case revision
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
