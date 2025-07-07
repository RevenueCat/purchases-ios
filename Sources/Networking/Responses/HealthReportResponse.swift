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
//  Created by Pol Piella on 4/8/25.

#if DEBUG
import Foundation

enum HealthCheckStatus: String {
    case passed
    case failed
    case warning
    case unknown
}

enum HealthCheckType: String {
    case apiKey = "api_key"
    case bundleId = "bundle_id"
    case products = "products"
    case offerings = "offerings"
    case offeringsProducts = "offerings_products"
}

enum ProductStatus: String {
    case valid = "ok"
    case couldNotCheck = "could_not_check"
    case notFound = "not_found"
    case actionInProgress = "action_in_progress"
    case needsAction = "needs_action"
    case unknown
}

struct PackageHealthReport {
    let identifier: String
    let title: String?
    let status: ProductStatus
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

struct BundleIdCheckDetails {
    let sdkBundleId: String
    let appBundleId: String
}

enum HealthCheckDetails {
    case offeringsProducts(OfferingsCheckDetails)
    case bundleId(BundleIdCheckDetails)
    case products(ProductsCheckDetails)
}

struct ProductsCheckDetails {
    let products: [ProductHealthReport]
}

struct ProductHealthReport {
    let identifier: String
    let title: String?
    let status: ProductStatus
    let description: String
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

    init(name: HealthCheckType, status: HealthCheckStatus, details: HealthCheckDetails? = nil) {
        self.name = name
        self.status = status
        self.details = details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(HealthCheckType.self, forKey: .name)
        status = try container.decode(HealthCheckStatus.self, forKey: .status)

        switch name {
        case .offeringsProducts:
            details = (try container.decodeIfPresent(OfferingsCheckDetails.self, forKey: .details))
                .map({ .offeringsProducts($0) })
        case .bundleId:
            details = (try container.decodeIfPresent(BundleIdCheckDetails.self, forKey: .details))
                .map({ .bundleId($0) })

        case .products:
            details = (try container.decodeIfPresent(ProductsCheckDetails.self, forKey: .details))
                .map({ .products($0) })

        default:
            details = nil
        }
    }
}

struct HealthReport {
    let status: HealthCheckStatus
    let projectId: String?
    let appId: String?
    let checks: [HealthCheck]
}

extension HealthReport: HTTPResponseBody {}
extension HealthReport: Codable, Equatable {}
extension HealthCheck: Codable, Equatable {}
extension HealthCheckDetails: Codable, Equatable {}
extension HealthCheckType: Codable, Equatable {}
extension HealthCheckStatus: Codable, Equatable {}
extension OfferingsCheckDetails: Codable, Equatable {}
extension BundleIdCheckDetails: Codable, Equatable {}
extension ProductsCheckDetails: Codable, Equatable {}
extension ProductStatus: Codable, Equatable {}
extension ProductHealthReport: Codable, Equatable {}
extension OfferingHealthReport: Codable, Equatable {}
extension PackageHealthReport: Codable, Equatable {}
#endif
