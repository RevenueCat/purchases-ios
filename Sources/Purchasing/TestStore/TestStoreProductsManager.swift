//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestStoreProductsManager.swift
//
//  Created by Antonio Pallares on 21/7/25.

/// Implementation of `ProductsManagerType` for the Test Store.
final class TestStoreProductsManager: ProductsManagerType {

    let requestTimeout: TimeInterval
    let backend: Backend
    let currentUserProvider: CurrentUserProvider

    init(backend: Backend, currentUserProvider: CurrentUserProvider, requestTimeout: TimeInterval) {
        self.requestTimeout = requestTimeout
        self.backend = backend
        self.currentUserProvider = currentUserProvider
    }

    func products(withIdentifiers identifiers: Set<String>, completion: @escaping Completion) {
        let appUserID = self.currentUserProvider.currentAppUserID
        backend.offerings.getWebProducts(appUserID: appUserID, productIds: identifiers, completion: WebProductsResponseHandler)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2Products(withIdentifiers identifiers: Set<String>, completion: @escaping SK2Completion) {
        // TODO: implement
        fatalError()
    }

    // This class does not implement caching.
    // See `CachingProductsManager`.
    func cache(_ product: any StoreProductType) { }

    // This class does not implement caching.
    // See `CachingProductsManager`.
    func clearCache() { }
}
