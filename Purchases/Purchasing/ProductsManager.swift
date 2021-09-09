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

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            Task {
                do {
                    let products = try await self.productsFetcherSK2.products(identifiers: identifiers)
                    completion(products)
                } catch {
                    Logger.error("error when fetching SK2 products: \(error.localizedDescription)")
                    let emptySet: Set<ProductDetails> = Set()
                    completion(emptySet)
                }
            }
        } else {
            self.products(withIdentifiers: identifiers) { skProducts in
                let wrappedProductsArray = skProducts.map { SK1ProductDetails(sk1Product: $0) }
                completion(Set(wrappedProductsArray))
            }
        }
    }

    func products(withIdentifiers identifiers: Set<String>,
                  completion: @escaping (Set<SKProduct>) -> Void) {
        return productsFetcherSK1.products(withIdentifiers: identifiers, completion: completion)
    }

    func cacheProduct(_ product: SKProduct) {
        productsFetcherSK1.cacheProduct(product)
    }
}
