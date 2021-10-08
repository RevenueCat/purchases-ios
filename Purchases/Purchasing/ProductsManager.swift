//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManager.swift
//
//  Created by Andrés Boedo on 7/14/20.
//

import Foundation
import StoreKit

class ProductsManager: NSObject {

    let productsFetcherSK1: ProductsFetcherSK1

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private(set) lazy var productsFetcherSK2 = ProductsFetcherSK2()

    init(productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory()) {
        self.productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory)
    }

    func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: Set<String>,
                                            completion: @escaping (Set<ProductDetails>) -> Void) {

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           SystemInfo.useStoreKit2IfAvailable {
            Task {
                let productDetails = await self.sk2ProductDetails(withIdentifiers: identifiers)
                completion(productDetails)
            }
        } else {
            productsFetcherSK1.products(withIdentifiers: identifiers, completion: completion)
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: Set<String>) async -> Set<ProductDetails> {
        return await withCheckedContinuation { continuation in
            productsFromOptimalStoreKitVersion(withIdentifiers: identifiers) { result in
                continuation.resume(returning: result)
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2ProductDetails(withIdentifiers identifiers: Set<String>) async -> Set<SK2ProductDetails> {
        do {
            let productDetails = try await productsFetcherSK2.products(identifiers: identifiers)
            return Set(productDetails)
        } catch {
            Logger.error("Error when fetching SK2 products: \(error.localizedDescription)")
            let emptySet: Set<SK2ProductDetails> = Set()
            return emptySet
        }
    }

    func products(withIdentifiers identifiers: Set<String>,
                  completion: @escaping (Set<SK1Product>) -> Void) {
        return productsFetcherSK1.sk1Products(withIdentifiers: identifiers, completion: completion)
    }

    func cacheProduct(_ product: SK1Product) {
        productsFetcherSK1.cacheProduct(product)
    }
}
