//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HealthReportResponse.swift
//
//  Created by Pol Piella on 4/8/22.

import Foundation

enum HealthCheckStatus: String {
    case passed
    case failed
    case unknown
}

enum HealthCheckType: String {
    case apiKey = "api_key"
    case sdkVersion = "sdk_version"
    case offerings = "offerings"
    case offeringsProducts = "offerings_products"
}

enum OfferingHealthErrorType: String {
    case noProducts = "no_products"
    case productsIssues = "products_issues"
}

struct PackageHealthReport {
    let identifier: String
    let title: String?
    let status: String
    let description: String
    let productIdentifier: String
    let productTitle: String?
}

struct OfferingHealthReport {
    let identifier: String
    let packages: [PackageHealthReport]
    let status: HealthCheckStatus
}

struct OfferingsCheckDetails {
    let offerings: [OfferingHealthReport]
}

enum HealthCheckDetails {
    case offeringsProducts(OfferingsCheckDetails)
}

struct HealthCheck {
    let name: HealthCheckType
    let status: HealthCheckStatus
    let details: HealthCheckDetails?

    enum CodingKeys: String, CodingKey {
        case name
        case status
        case details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(HealthCheckType.self, forKey: .name)
        status = try container.decode(HealthCheckStatus.self, forKey: .status)

        switch name {
        case .offeringsProducts:
            details = (try container.decodeIfPresent(OfferingsCheckDetails.self, forKey: .details)).map({ .offeringsProducts($0) })
        default:
            details = nil
        }
    }
}

struct HealthReport {
    let status: HealthCheckStatus
    let checks: [HealthCheck]
}

extension HealthReport: HTTPResponseBody {}
extension HealthReport: Codable, Equatable {}
extension HealthCheck: Codable, Equatable {}
extension HealthCheckDetails: Codable, Equatable {}
extension HealthCheckType: Codable, Equatable {}
extension HealthCheckStatus: Codable, Equatable {}
extension OfferingsCheckDetails: Codable, Equatable {}
extension OfferingHealthReport: Codable, Equatable {}
extension PackageHealthReport: Codable, Equatable {}
extension OfferingHealthErrorType: Codable, Equatable {}
