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
    private var cachedProductsByIdentifier: [String: SKProduct] = [:]
    private var productsByRequests: [SKRequest: Set<String>] = [:]
    private var completionHandlers: [Set<String>: (Set<SKProduct>) -> Void] = [:]

    func products(withIdentifiers identifiers: Set<String>, completion: @escaping (Set<SKProduct>) -> Void) {
        let productsAlreadyCached = cachedProductsByIdentifier.filter { key, _ in identifiers.contains(key) }
        if productsAlreadyCached.count == identifiers.count {
            let productsAlreadyCachedSet = Set(productsAlreadyCached.values)
            completion(productsAlreadyCachedSet)
            return
        }
        
        let request = SKProductsRequest(productIdentifiers: identifiers)
        request.delegate = self
        
        productsByRequests[request] = identifiers
        completionHandlers[identifiers] = completion
        
        request.start()
    }
}

extension ProductsManager: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        NSLog("products request received response")
        guard let requestProducts = productsByRequests[request] else { fatalError("couldn't find request") }
        guard let completion = completionHandlers[requestProducts] else { fatalError("couldn't find completion") }
        completionHandlers.removeValue(forKey: requestProducts)
        productsByRequests.removeValue(forKey: request)
        
        cacheProducts(response.products)
        completion(Set(response.products))
    }

    func requestDidFinish(_ request: SKRequest) {
        NSLog("request did finish")
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        NSLog("products request failed! error: \(error.localizedDescription)")
        guard let products = productsByRequests[request] else { fatalError("couldn't find request") }
        
        completionHandlers.removeValue(forKey: products)
        productsByRequests.removeValue(forKey: request)
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
