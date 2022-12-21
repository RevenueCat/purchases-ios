//
//  ProductFetcherSK1.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 12/19/22.
//

import RevenueCat
import StoreKit

/// Simplified version of the fetcher in RevenueCat.
/// Used to fetch products directly and test observer mode.
final class ProductFetcherSK1: NSObject {

    typealias Callback = (Result<Set<SK1Product>, Error>) -> Void

    private var completionHandlers: [Set<String>: Callback] = [:]
    private var productsByRequests: [SKRequest: Set<String>] = [:]

    func products(with identifiers: Set<String>, completion: @escaping Callback) {
        assert(self.completionHandlers[identifiers] == nil)

        self.completionHandlers[identifiers] = completion
        self.startRequest(for: identifiers)
    }

    private func startRequest(for identifiers: Set<String>) {
        let request = SKProductsRequest(productIdentifiers: identifiers)
        request.delegate = self
        self.productsByRequests[request] = identifiers
        request.start()
    }

    func products(with identifiers: Set<String>) async throws -> Set<SK1Product> {
        return try await withCheckedThrowingContinuation { continuation in
            self.products(with: identifiers) { result in
                continuation.resume(with: result)
            }
        }
    }

}

extension ProductFetcherSK1: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.report(result: .success(Set(response.products)), from: request)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.report(result: .failure(error), from: request)
    }

    private func report(result: Result<Set<SK1Product>, Error>, from request: SKRequest) {
        guard let identifiers = self.productsByRequests.removeValue(forKey: request),
              let completion = self.completionHandlers.removeValue(forKey: identifiers) else {
            fatalError("Couldn't find matching callback")
        }

        completion(result)
    }

}
