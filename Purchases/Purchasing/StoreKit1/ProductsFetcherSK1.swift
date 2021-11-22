//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsFetcherSK1.swift
//
//  Created by Andrés Boedo on 7/26/21.

import Foundation
import StoreKit

class ProductsFetcherSK1: NSObject {

    private let productsRequestFactory: ProductsRequestFactory

    private var cachedProductsByIdentifier: [String: SK1Product] = [:]
    private let queue = DispatchQueue(label: "ProductsFetcherSK1")
    private var productsByRequests: [SKRequest: Set<String>] = [:]
    private var completionHandlers: [Set<String>: [(Set<SK1Product>) -> Void]] = [:]
    private let requestTimeoutInSeconds: Int

    init(productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory(),
         requestTimeoutInSeconds: Int = 30) {
        self.productsRequestFactory = productsRequestFactory
        self.requestTimeoutInSeconds = requestTimeoutInSeconds
    }

    func sk1Products(withIdentifiers identifiers: Set<String>,
                     completion: @escaping (Set<SK1Product>) -> Void) {
        guard identifiers.count > 0 else {
            completion([])
            return
        }
        queue.async { [self] in
            let productsAlreadyCached = self.cachedProductsByIdentifier.filter { key, _ in identifiers.contains(key) }
            if productsAlreadyCached.count == identifiers.count {
                let productsAlreadyCachedSet = Set(productsAlreadyCached.values)
                Logger.debug(Strings.offering.products_already_cached(identifiers: identifiers))
                completion(productsAlreadyCachedSet)
                return
            }

            if let existingHandlers = self.completionHandlers[identifiers] {
                Logger.debug(Strings.offering.found_existing_product_request(identifiers: identifiers))
                self.completionHandlers[identifiers] = existingHandlers + [completion]
                return
            }

            Logger.debug(
                Strings.offering.no_cached_requests_and_products_starting_skproduct_request(identifiers: identifiers)
            )
            let request = self.productsRequestFactory.request(productIdentifiers: identifiers)
            request.delegate = self
            self.completionHandlers[identifiers] = [completion]
            self.productsByRequests[request] = identifiers
            request.start()
            scheduleCancellationInCaseOfTimeout(for: request)
        }
    }

    func products(withIdentifiers identifiers: Set<String>,
                  completion: @escaping (Set<ProductDetails>) -> Void) {
        self.sk1Products(withIdentifiers: identifiers) { skProducts in
            let wrappedProductsArray = skProducts.map { SK1ProductDetails(sk1Product: $0) }
            completion(Set(wrappedProductsArray))
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func products(withIdentifiers identifiers: Set<String>) async -> Set<ProductDetails> {
        return await withCheckedContinuation { continuation in
            products(withIdentifiers: identifiers) { result in
                continuation.resume(returning: result)
            }
        }
    }

}

extension ProductsFetcherSK1: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        queue.async { [self] in
            Logger.rcSuccess(Strings.storeKit.skproductsrequest_received_response)
            guard let requestProducts = self.productsByRequests[request] else {
                Logger.error("requested products not found for request: \(request)")
                return
            }
            guard let completionBlocks = self.completionHandlers[requestProducts] else {
                Logger.error("callback not found for failing request: \(request)")
                self.productsByRequests.removeValue(forKey: request)
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
        Logger.rcSuccess(Strings.storeKit.skproductsrequest_finished)
        self.cancelRequestToPreventTimeoutWarnings(request)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        queue.async { [self] in
            Logger.appleError(Strings.storeKit.skproductsrequest_failed(error: error))
            guard let products = self.productsByRequests[request] else {
                Logger.error(Strings.purchase.requested_products_not_found(request: request))
                return
            }
            guard let completionBlocks = self.completionHandlers[products] else {
                Logger.error(Strings.purchase.callback_not_found_for_request(request: request))
                self.productsByRequests.removeValue(forKey: request)
                return
            }

            self.completionHandlers.removeValue(forKey: products)
            self.productsByRequests.removeValue(forKey: request)
            for completion in completionBlocks {
                completion(Set())
            }
        }
        self.cancelRequestToPreventTimeoutWarnings(request)
    }

    func cacheProduct(_ product: SK1Product) {
        queue.async {
            self.cachedProductsByIdentifier[product.productIdentifier] = product
        }
    }
}

private extension ProductsFetcherSK1 {

    func cacheProducts(_ products: [SK1Product]) {
        queue.async {
            let productsByIdentifier = products.reduce(into: [:]) { resultDict, product in
                resultDict[product.productIdentifier] = product
            }

            self.cachedProductsByIdentifier += productsByIdentifier
        }
    }

    // Even though the request has finished, we've seen instances where
    // the request seems to live on. So we manually call `cancel` to prevent warnings in runtime.
    // https://github.com/RevenueCat/purchases-ios/issues/250
    // https://github.com/RevenueCat/purchases-ios/issues/391
    func cancelRequestToPreventTimeoutWarnings(_ request: SKRequest) {
        request.cancel()
    }

    // Even though there's a specific delegate method for when SKProductsRequest fails,
    // there seem to be some situations in which SKProductsRequest hangs forever,
    // without timing out and calling the delegate.
    // So we schedule a cancellation just in case, and skip it if all goes as expected.
    // More information: https://rev.cat/skproductsrequest-hangs
    func scheduleCancellationInCaseOfTimeout(for request: SKProductsRequest) {
        queue.asyncAfter(deadline: .now() + .seconds(requestTimeoutInSeconds)) { [weak self] in
            guard let self = self,
                  let products = self.productsByRequests[request] else { return }

            request.cancel()

            Logger.appleError(Strings.storeKit.skproductsrequest_timed_out(after: self.requestTimeoutInSeconds))
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
    }

}
