//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowBranch.swift
//
//  Created by RevenueCat.
// swiftlint:disable missing_docs

import Foundation

/// A `branch` trigger action. The first audience that matches decides the route.
@_spi(Internal) public struct WorkflowBranch: Equatable, Sendable, Decodable {

    @_spi(Internal) public struct Route: Equatable, Sendable, Decodable {

        /// Rules live in the `audiences` topic.
        public let audienceId: String
        public let stepId: String

        @_spi(Internal) public init(audienceId: String, stepId: String) {
            self.audienceId = audienceId
            self.stepId = stepId
        }

    }

    public let branches: [Route]
    public let fallbackStepId: String

    @_spi(Internal) public init(branches: [Route], fallbackStepId: String) {
        self.branches = branches
        self.fallbackStepId = fallbackStepId
    }

}
