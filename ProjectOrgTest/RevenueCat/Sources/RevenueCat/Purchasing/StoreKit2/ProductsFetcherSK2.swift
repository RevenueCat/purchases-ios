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

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
actor ProductsFetcherSK2 {

    enum Error: Swift.Error {

        case productsRequestError(innerError: Swift.Error)

    }

    /// - Throws: `ProductsFetcherSK2.Error`
    func products(identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        do {
            let storeKitProducts = try await TimingUtil.measureAndLogIfTooSlow(
                threshold: .productRequest,
                message: Strings.storeKit.sk2_product_request_too_slow
            ) {
                try await StoreKit.Product.products(for: identifiers)
            }

            Logger.rcSuccess(Strings.storeKit.store_product_request_received_response)
            return Set(storeKitProducts.map { SK2StoreProduct(sk2Product: $0) })
        } catch {
            throw Error.productsRequestError(innerError: error)
        }
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension ProductsFetcherSK2.Error: CustomNSError {

    var errorUserInfo: [String: Any] {
        switch self {
        case let .productsRequestError(inner):
            return [
                NSUnderlyingErrorKey: inner,
                NSLocalizedDescriptionKey: self.localizedDescription
            ]
        }
    }

    var localizedDescription: String {
        switch self {
        case let .productsRequestError(innerError): return "Products request error: \(innerError.localizedDescription)"
        }
    }
}
