//
//  ProductEntitlementMappingTopicProvider.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol EntitlementMappingTopicProviderType: AnyObject {

    /// Returns the mapping when its remote-config blob is available and decodes successfully.
    func getProductEntitlementMapping() async -> ProductEntitlementMappingResponse?

}

/// Decodes the `product_entitlement_mapping.default` remote-config blob.
final class ProductEntitlementMappingTopicProvider: EntitlementMappingTopicProviderType {

    private static let itemKey = "default"

    private weak var manager: RemoteConfigManagerType?

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func getProductEntitlementMapping() async -> ProductEntitlementMappingResponse? {
        guard let manager = self.manager else { return nil }

        do {
            return try await manager.blobData(
                for: .productEntitlementMapping,
                itemKey: Self.itemKey,
                as: ProductEntitlementMappingResponse.self
            )
        } catch {
            Logger.error(Strings.remoteConfig.productEntitlementMappingDecodeFailed(error))
            return nil
        }
    }

}

extension ProductEntitlementMappingTopicProvider: @unchecked Sendable {}
