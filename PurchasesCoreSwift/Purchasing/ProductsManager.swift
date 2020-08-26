//
//  ProductsManager.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/14/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit

internal class ProductsManager: NSObject {
    private let productsRequestFactory: ProductsRequestFactory

    private var cachedProductsByIdentifier: [String: SKProduct] = [:]
    private let queue = DispatchQueue(label: "ProductsManager")
    private var productsByRequests: [SKRequest: Set<String>] = [:]
    private var completionHandlers: [Set<String>: [(Set<SKProduct>) -> Void]] = [:]

    init(productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory()) {
        self.productsRequestFactory = productsRequestFactory
    }

    func products(withIdentifiers identifiers: Set<String>, completion: @escaping (Set<SKProduct>) -> Void) {
        queue.async { [self] in
            let productsAlreadyCached = self.cachedProductsByIdentifier.filter { key, _ in identifiers.contains(key) }
            if productsAlreadyCached.count == identifiers.count {
                let productsAlreadyCachedSet = Set(productsAlreadyCached.values)
                NSLog("skipping products request because products were already cached. products: \(identifiers)")
                completion(productsAlreadyCachedSet)
                return
            }

            if let existingHandlers = self.completionHandlers[identifiers] {
                NSLog("found an existing request for products: \(identifiers), appending to completion")
                self.completionHandlers[identifiers] = existingHandlers + [completion]
                return
            }

            NSLog("no existing requests and products not cached, starting SKProducts request for: \(identifiers)")
            let request = self.productsRequestFactory.request(productIdentifiers: identifiers)
            request.delegate = self
            self.completionHandlers[identifiers] = [completion]
            self.productsByRequests[request] = identifiers
            request.start()
        }
    }
}

extension ProductsManager: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        queue.async { [self] in
            NSLog("products request received response")
            guard let requestProducts = self.productsByRequests[request] else { fatalError("couldn't find request") }
            guard let completionBlocks = self.completionHandlers[requestProducts] else {
                fatalError("couldn't find completion")
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
        NSLog("request did finish")
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        queue.async { [self] in
            NSLog("products request failed! error: \(error.localizedDescription)")
            guard let products = self.productsByRequests[request] else { fatalError("couldn't find request") }
            guard let completionBlocks = self.completionHandlers[products] else {
                fatalError("couldn't find completion")
            }

            self.completionHandlers.removeValue(forKey: products)
            self.productsByRequests.removeValue(forKey: request)
            for completion in completionBlocks {
                completion(Set())
            }
        }
    }
}

private extension ProductsManager {

    func cacheProducts(_ products: [SKProduct]) {
        let productsByIdentifier = products.reduce(into: [:]) { resultDict, product in
            resultDict[product.productIdentifier] = product
        }

        cachedProductsByIdentifier.merge(productsByIdentifier) { (_, new) in new }
    }
}
