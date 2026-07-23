//
//  ProductEntitlementMappingTopicProvider.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol EntitlementMappingTopicProviderType: AnyObject {

    var isAvailable: Bool { get }

    /// Returns the mapping when its remote-config blob is available and decodes successfully.
    func getProductEntitlementMapping() async -> ProductEntitlementMappingResult?

}

struct ProductEntitlementMappingResult: @unchecked Sendable {

    let response: ProductEntitlementMappingResponse
    private let useIfCurrentOperation: ((ProductEntitlementMappingResponse) -> Void) -> Bool

    init(
        response: ProductEntitlementMappingResponse,
        useIfCurrent: @escaping ((ProductEntitlementMappingResponse) -> Void) -> Bool
    ) {
        self.response = response
        self.useIfCurrentOperation = useIfCurrent
    }

    func useIfCurrent(_ operation: (ProductEntitlementMappingResponse) -> Void) -> Bool {
        return self.useIfCurrentOperation(operation)
    }

}

/// Decodes the `product_entitlement_mapping.default` remote-config blob.
final class ProductEntitlementMappingTopicProvider: EntitlementMappingTopicProviderType {

    private static let itemKey = "default"

    private weak var manager: RemoteConfigManagerType?

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    var isAvailable: Bool {
        guard let manager = self.manager else { return false }
        return !manager.isDisabled
    }

    func getProductEntitlementMapping() async -> ProductEntitlementMappingResult? {
        guard let manager = self.manager,
              let blobData = await manager.blobDataSnapshot(
                for: .productEntitlementMapping,
                itemKey: Self.itemKey
              ) else { return nil }

        do {
            let response = try JSONDecoder.default.decode(
                ProductEntitlementMappingResponse.self,
                from: blobData.value
            )
            return ProductEntitlementMappingResult(response: response) { operation in
                manager.useIfCurrent(blobData) { _ in operation(response) }
            }
        } catch {
            Logger.error(Strings.offlineEntitlements.product_entitlement_mapping_remote_config_decoding_error(error))
            return nil
        }
    }

}

extension ProductEntitlementMappingTopicProvider: @unchecked Sendable {}
