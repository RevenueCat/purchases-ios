//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManagerSK2.swift
//
//  Created by Andrés Boedo on 7/23/21.

import Foundation
import StoreKit

enum ProductsManagerSK2Error: Error {

    case productsRequestError(innerError: Error)

}

struct ProductsFetcherSK2 {

    @available(iOS 15.0, tvOS 15.0, macOS 13.0, watchOS 8.0, *)
    func products(identifiers: Set<String>) async throws -> Set<ProductWrapper> {
        do {
            let storeKitProducts = try await StoreKit.Product.products(for: identifiers)
            let sk2Wrappers = storeKitProducts.map { SK2ProductWrapper(sk2Product: $0) }
            return Set(sk2Wrappers)
        } catch let error {
            throw ProductsManagerSK2Error.productsRequestError(innerError: error)
        }
    }

}
