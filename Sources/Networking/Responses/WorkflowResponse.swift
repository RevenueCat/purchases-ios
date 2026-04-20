//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowResponse.swift
//
// swiftlint:disable missing_docs

import Foundation

@_spi(Internal) public struct WorkflowResponse: Codable, Equatable, HTTPResponseBody {

    public let workflow: PublishedWorkflow
    public let enrolledVariants: [String: String]?

}

@_spi(Internal) public extension WorkflowResponse {

    struct PublishedWorkflow: Codable, Equatable {

        public let id: String
        public let initialStepId: String?
        public let steps: [WorkflowStep]
        // keyed by screen ID
        public let screens: [String: WorkflowScreen]
        public let uiConfig: UIConfig

    }

    struct WorkflowStep: Codable, Equatable {

        public let id: String
        public let screenId: String?

    }

    struct WorkflowScreen: Codable, Equatable {

        public let offeringId: String
        public let templateName: String
        public let assetBaseURL: URL
        public let revision: Int
        public let componentsConfig: PaywallComponentsData.ComponentsConfig
        public let componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary]
        public let defaultLocale: String

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case offeringId
            case templateName
            case assetBaseURL = "assetBaseUrl"
            case revision
            case componentsConfig
            case componentsLocalizations
            case defaultLocale
        }

    }

}

extension WorkflowResponse: Sendable {}
extension WorkflowResponse.PublishedWorkflow: Sendable {}
extension WorkflowResponse.WorkflowStep: Sendable {}
extension WorkflowResponse.WorkflowScreen: Sendable {}
