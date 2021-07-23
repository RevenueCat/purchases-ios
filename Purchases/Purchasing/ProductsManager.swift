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

    private let productsRequestFactory: ProductsRequestFactory
    private var cachedProductsByIdentifier: [String: SKProduct] = [:]
    private let queue = DispatchQueue(label: "ProductsManager")
    private var productsByRequests: [SKRequest: Set<String>] = [:]
    private var completionHandlers: [Set<String>: [(Set<SKProduct>) -> Void]] = [:]

    init(productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory()) {
        self.productsRequestFactory = productsRequestFactory
    }

   
    func productsFromOptimalStore(withIdentifiers identifiers: Set<String>,
                                  completion: @escaping (Set<ProductWrapper>) -> Void) {

        if #available(iOS 15.0, tvOS 15.0, watchOS 7.0, macOS 15.0, *) {
            Task.init {
                let productsManagerSK2 = ProductsManagerSK2()
                do {
                    let products = try await productsManagerSK2.products(identifiers: identifiers)
                    completion(products)
                } catch let error {
                    Logger.error("error when fetching SK2 products: \(error.localizedDescription)")
                    let emptySet: Set<ProductWrapper> = Set()
                    completion(emptySet)
                }
            }
        } else {
            self.products(withIdentifiers: identifiers) { skProducts in
                let wrappedProductsArray = skProducts.map { SK1ProductWrapper(sk1Product: $0) }
                completion(Set(wrappedProductsArray))
            }
        }
    }

    func products(withIdentifiers identifiers: Set<String>,
                  completion: @escaping (Set<SKProduct>) -> Void) {
        guard identifiers.count > 0 else {
            completion([])
            return
        }
        queue.async { [self] in
            let productsAlreadyCached = self.cachedProductsByIdentifier.filter { key, _ in identifiers.contains(key) }
            if productsAlreadyCached.count == identifiers.count {
                let productsAlreadyCachedSet = Set(productsAlreadyCached.values)
                Logger.debug(String(format: Strings.offering.products_already_cached, identifiers))
                completion(productsAlreadyCachedSet)
                return
            }

            if let existingHandlers = self.completionHandlers[identifiers] {
                Logger.debug(String(format: Strings.offering.found_existing_product_request, identifiers))
                self.completionHandlers[identifiers] = existingHandlers + [completion]
                return
            }

            Logger.debug(
                String(format: Strings.offering.no_cached_requests_and_products_starting_skproduct_request, identifiers)
            )
            let request = self.productsRequestFactory.request(productIdentifiers: identifiers)
            request.delegate = self
            self.completionHandlers[identifiers] = [completion]
            self.productsByRequests[request] = identifiers
            request.start()
        }
    }

    func cacheProduct(_ product: SKProduct) {
        queue.async {
            self.cachedProductsByIdentifier[product.productIdentifier] = product
        }
    }

}

extension ProductsManager: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        queue.async { [self] in
            Logger.rcSuccess(Strings.network.skproductsrequest_received_response)
            guard let requestProducts = self.productsByRequests[request] else {
                Logger.error("requested products not found for request: \(request)")
                return
            }
            guard let completionBlocks = self.completionHandlers[requestProducts] else {
                Logger.error("callback not found for failing request: \(request)")
                return
            }

            self.completionHandlers.removeValue(forKey: requestProducts)
            self.productsByRequests.removeValue(forKey: request)

            self.cacheProducts(response.products)
            for completion in completionBlocks {
                completion(Set(response.products))
            }
        }
    }

    func requestDidFinish(_ request: SKRequest) {
        Logger.rcSuccess(Strings.network.skproductsrequest_finished)
        request.cancel()
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        queue.async { [self] in
            Logger.appleError(String(format: Strings.network.skproductsrequest_failed, error.localizedDescription))
            guard let products = self.productsByRequests[request] else {
                Logger.error("requested products not found for request: \(request)")
                return
            }
            guard let completionBlocks = self.completionHandlers[products] else {
                Logger.error("callback not found for failing request: \(request)")
                return
            }

            self.completionHandlers.removeValue(forKey: products)
            self.productsByRequests.removeValue(forKey: request)
            for completion in completionBlocks {
                completion(Set())
            }
        }
        request.cancel()
    }

}

private extension ProductsManager {

    func cacheProducts(_ products: [SKProduct]) {
        let productsByIdentifier = products.reduce(into: [:]) { resultDict, product in
            resultDict[product.productIdentifier] = product
        }

        cachedProductsByIdentifier = cachedProductsByIdentifier.merging(productsByIdentifier)
    }

}
