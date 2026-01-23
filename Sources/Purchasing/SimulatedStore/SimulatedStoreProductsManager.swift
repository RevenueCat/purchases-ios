//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SimulatedStoreProductsManager.swift
//
//  Created by Antonio Pallares on 21/7/25.

import Foundation

/// Implementation of `ProductsManagerType` for the Simulated Store.
final class SimulatedStoreProductsManager: ProductsManagerType {

    let requestTimeout: TimeInterval
    let backend: Backend
    let deviceCache: DeviceCache

    init(backend: Backend, deviceCache: DeviceCache, requestTimeout: TimeInterval) {
        self.requestTimeout = requestTimeout
        self.backend = backend
        self.deviceCache = deviceCache
    }

    func products(withIdentifiers identifiers: Set<String>, completion: @escaping Completion) {
        guard !identifiers.isEmpty else {
            completion(.success(Set()))
            return
        }

        let appUserID = self.deviceCache.cachedAppUserID ?? ""
        backend.webBilling.getWebBillingProducts(appUserID: appUserID, productIds: identifiers) { result in
            switch result {
            case let .success(response):
                do {
                    let products: [StoreProduct] = try response.productDetails.map {
                        try $0.convertToStoreProduct()
                    }
                    completion(.success(Set(products)))
                } catch {
                    let purchasesError = ErrorUtils.purchasesError(withUntypedError: error)
                    completion(.failure(purchasesError))
                }

            case let .failure(backendError):
                completion(.failure(backendError.asPurchasesError))
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2Products(withIdentifiers identifiers: Set<String>, completion: @escaping SK2Completion) {
        completion(.success(Set()))
    }

    // This class does not implement caching.
    // See `CachingProductsManager`.
    func cache(_ product: any StoreProductType) { }

    // This class does not implement caching.
    // See `CachingProductsManager`.
    func clearCache() { }
}
