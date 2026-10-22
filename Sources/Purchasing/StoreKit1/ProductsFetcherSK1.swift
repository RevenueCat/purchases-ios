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

final class ProductsFetcherSK1: NSObject {

    typealias Callback = (Result<Set<SK1Product>, PurchasesError>) -> Void

    let requestTimeout: TimeInterval
    private let productsRequestFactory: ProductsRequestFactory

    // Note: these 3 must be used only inside `queue` to be thread-safe.
    private var requestIDsByIdentifiers: [Set<String>: UUID] = [:]
    private var productsByRequests: [SKRequest: ProductRequest] = [:]
    private var completionHandlersByRequestID: [UUID: [Callback]] = [:]

    private let queue = DispatchQueue(label: "ProductsFetcherSK1")

    private static let numberOfRetries: Int = 10

    /// - Parameter requestTimeout: requests made by this class will return after whichever condition comes first:
    ///     - A success
    ///     - Retries up to ``Self.numberOfRetries``
    ///     - Timeout specified by this parameter
    init(productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory(),
         requestTimeout: TimeInterval) {
        self.productsRequestFactory = productsRequestFactory
        self.requestTimeout = requestTimeout
    }

    func products(withIdentifiers identifiers: Set<String>,
                  completion: @escaping (Result<Set<SK1StoreProduct>, PurchasesError>) -> Void) {
        let resolvedIdentifiers = CompoundProductIdentifierResolver.resolve(
            identifiers,
            supportsBillingPlans: Self.areProductsWithBillingPlansSupported
        )

        TimingUtil.measureAndLogIfTooSlow(
            threshold: .productRequest,
            message: Strings.storeKit.sk1_product_request_too_slow,
            work: { completion in
                self.sk1Products(withIdentifiers: resolvedIdentifiers.storeKitProductIdentifiers) { skProducts in
                    completion(skProducts.map { Set($0.map(SK1StoreProduct.init)) })
                }
            },
            result: completion
        )
    }

    func products(withIdentifiers identifiers: Set<String>) async throws -> Set<SK1StoreProduct> {
        return try await Async.call { completion in
            self.products(withIdentifiers: identifiers, completion: completion)
        }
    }

    /// Stops new callers from joining pending requests. Existing callers still receive their results.
    func invalidateRequests() {
        self.queue.async {
            self.requestIDsByIdentifiers.removeAll(keepingCapacity: true)
        }
    }

}

private extension ProductsFetcherSK1 {

    // Note: this isn't thread-safe and must therefore be used inside of `queue` only.
    func startRequest(_ productRequest: ProductRequest) {
        let request = self.productsRequestFactory.request(productIdentifiers: productRequest.identifiers)
        request.delegate = self
        self.productsByRequests[request] = productRequest
        request.start()
    }

    func sk1Products(withIdentifiers identifiers: Set<String>, completion: @escaping Callback) {
        guard identifiers.count > 0 else {
            completion(.success([]))
            return
        }

        self.queue.async { [self] in
            if let requestID = self.requestIDsByIdentifiers[identifiers] {
                Logger.debug(Strings.offering.found_existing_product_request(identifiers: identifiers))
                self.completionHandlersByRequestID[requestID, default: []].append(completion)
                return
            }

            let request = ProductRequest(id: UUID(), identifiers: identifiers, retriesLeft: Self.numberOfRetries)
            self.requestIDsByIdentifiers[identifiers] = request.id
            self.completionHandlersByRequestID[request.id] = [completion]
            self.startRequest(request)
            self.scheduleCancellationInCaseOfTimeout(for: request)
        }
    }

    static func areProductsWithBillingPlansSupported(compoundIdentifier: CompoundProductIdentifier) -> Bool {
        Logger.warn(
            StoreKitStrings.sk1_does_not_support_billing_plans(
                compoundProductIdentifier: compoundIdentifier
            )
        )

        return false
    }

    struct ProductRequest {

        let id: UUID
        let identifiers: Set<String>
        let retriesLeft: Int

    }

}

extension ProductsFetcherSK1: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.queue.async { [self] in
            Logger.rcSuccess(Strings.storeKit.store_product_request_received_response)
            guard let productRequest = self.productsByRequests[request] else {
                Logger.error("requested products not found for request: \(request)")
                return
            }
            guard let completionBlocks = self.finishRequest(productRequest) else {
                Logger.error("callback not found for failing request: \(request)")
                return
            }

            for completion in completionBlocks {
                completion(.success(Set(response.products)))
            }
        }
    }

    func requestDidFinish(_ request: SKRequest) {
        Logger.rcSuccess(Strings.storeKit.store_product_request_finished)
        self.cancelRequestToPreventTimeoutWarnings(request)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        defer {
            self.cancelRequestToPreventTimeoutWarnings(request)
        }

        self.queue.async { [self] in
            Logger.appleError(Strings.storeKit.store_products_request_failed(error as NSError))

            guard let productRequest = self.productsByRequests.removeValue(forKey: request) else {
                Logger.error(Strings.purchase.requested_products_not_found(request: request))
                return
            }

            if productRequest.retriesLeft <= 0 {
                guard let completionBlocks = self.finishRequest(productRequest) else {
                    Logger.error(Strings.purchase.callback_not_found_for_request(request: request))
                    return
                }

                for completion in completionBlocks {
                    completion(.failure(ErrorUtils.purchasesError(withSKError: error)))
                }
            } else {
                let delayInSeconds = Int((self.requestTimeout / 10).rounded())
                self.queue.asyncAfter(deadline: .now() + .seconds(delayInSeconds)) { [self] in
                    guard self.completionHandlersByRequestID[productRequest.id] != nil else { return }
                    self.startRequest(.init(id: productRequest.id,
                                            identifiers: productRequest.identifiers,
                                            retriesLeft: productRequest.retriesLeft - 1))
                }
            }
        }
    }

}

private extension ProductsFetcherSK1 {

    // Must be called on `queue`. Do not remove the identifier entry if it belongs to a newer request.
    func finishRequest(_ request: ProductRequest) -> [Callback]? {
        if self.requestIDsByIdentifiers[request.identifiers] == request.id {
            self.requestIDsByIdentifiers.removeValue(forKey: request.identifiers)
        }
        self.productsByRequests = self.productsByRequests.filter { $0.value.id != request.id }
        return self.completionHandlersByRequestID.removeValue(forKey: request.id)
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
    func scheduleCancellationInCaseOfTimeout(for request: ProductRequest) {
        self.queue.asyncAfter(deadline: .now() + self.requestTimeout) { [weak self] in
            guard let self = self,
                  self.completionHandlersByRequestID[request.id] != nil else { return }

            let attempts = self.productsByRequests.filter { $0.value.id == request.id }.map(\.key)
            let completionBlocks = self.finishRequest(request) ?? []
            attempts.forEach { $0.cancel() }

            Logger.appleError(Strings.storeKit.skproductsrequest_timed_out(
                after: Int(self.requestTimeout.rounded())
            ))
            for completion in completionBlocks {
                completion(.failure(ErrorUtils.productRequestTimedOutError()))
            }
        }
    }

}

// @unchecked because:
// - It has mutable state, but it's made thread-safe through `queue`.
extension ProductsFetcherSK1: @unchecked Sendable {}

#if hasFeature(RetroactiveAttribute)
// Conformance should be safe since it is only used as dictionary key
extension SKRequest: @unchecked @retroactive Sendable {}
extension SKProductsRequest: @unchecked @retroactive Sendable {}
#endif
