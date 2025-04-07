//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppHealthResponse.swift
//
//
//  Created by Pol Piella Abadia on 2/4/25.
//

import Foundation

// swiftlint:disable nesting

public struct AppHealthResponse: Sendable {
    public let offerings: [AppHealthOffering]
    
    public struct AppHealthOffering: Sendable {
        public let identifier: String
        public let products: [AppHealthOfferingPackage]
        
        public struct AppHealthOfferingPackage: Sendable {
            public let packageIdentifier: String
            public let status: AppHealthOfferingStatus
        }
        
        public struct AppHealthOfferingStatus: Sendable {
            public let productTitle: String?
            public let productIdentifier: String
            public let status: AppHealthStatus
            public let helperText: String
            public let storeAppId: String?
            public let storeProductId: String?
            public let storeProductType: String?
        }
        
        public enum AppHealthStatus: String, Sendable {
            case ok = "ok"
            case couldNotCheck = "could_not_check"
            case notFound = "not_found"
            case actionInProgress = "action_in_progress"
            case needsAction = "needs_action"
            case unknown = "unknown"
        }
    }
}

extension AppHealthResponse.AppHealthOffering: Codable, Equatable {}
extension AppHealthResponse.AppHealthOffering.AppHealthOfferingPackage: Codable, Equatable {}
extension AppHealthResponse.AppHealthOffering.AppHealthOfferingStatus: Codable, Equatable {}
extension AppHealthResponse.AppHealthOffering.AppHealthStatus: Codable, Equatable {}
extension AppHealthResponse: Codable, Equatable {}

extension AppHealthResponse: HTTPResponseBody {}
