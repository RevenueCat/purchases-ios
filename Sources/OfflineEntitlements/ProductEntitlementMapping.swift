//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductEntitlementMapping.swift
//
//  Created by Nacho Soto on 3/22/23.

import Foundation

/// A mapping between products and entitlements.
struct ProductEntitlementMapping {

    var entitlementsByProduct: [String: Set<String>]

}

extension ProductEntitlementMapping {

    /// - Returns: entitlement identifiers associated to the given product identifier
    func entitlements(for productIdentifier: String) -> Set<String> {
        return self.entitlementsByProduct[productIdentifier] ?? []
    }

}

extension ProductEntitlementMapping {

    static let empty: Self = .init(entitlementsByProduct: [:])

}

extension ProductEntitlementMappingResponse {

    func toMapping() -> ProductEntitlementMapping {
        return .init(entitlementsByProduct: self.products.mapValues { Set($0.entitlements) })
    }

}

// MARK: -

extension ProductEntitlementMapping: Equatable {}
extension ProductEntitlementMapping: Codable {}
