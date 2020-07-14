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
    private let cachedProductsByIdentifier: [String: SKProduct] = [:]
    private var requestsByProducts: [Set<String>: SKRequest] = [:]
    private var productsByRequests: [SKRequest: Set<String>] = [:]
    private var completionHandlers: [Set<String>: (Set<SKProduct>) -> Void] = [:]

    func products(withIdentifiers identifiers: Set<String>, completion: @escaping (Set<SKProduct>) -> Void) {
        let request = SKProductsRequest(productIdentifiers: identifiers)
        request.delegate = self
        
        requestsByProducts[identifiers] = request
        productsByRequests[request] = identifiers
        completionHandlers[identifiers] = completion
        
        request.start()
    }
}

extension ProductsManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        NSLog("products request received response")
        guard let products = productsByRequests[request] else { fatalError("couldn't find request") }
        guard let completion = completionHandlers[products] else { fatalError("couldn't find completion") }
        completionHandlers.removeValue(forKey: products)
        productsByRequests.removeValue(forKey: request)

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
