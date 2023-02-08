//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InternalAPI.swift
//
//  Created by Nacho Soto on 10/5/22.

import Foundation

final class InternalAPI {

    typealias ResponseHandler = (BackendError?) -> Void

    private let backendConfig: BackendConfiguration
    private let callbackCache: CallbackCache<HealthOperation.Callback>

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.callbackCache = .init()
    }

    func healthRequest(signatureVerification: Bool, completion: @escaping ResponseHandler) {
        let factory = HealthOperation.createFactory(httpClient: self.backendConfig.httpClient,
                                                    callbackCache: self.callbackCache,
                                                    signatureVerification: signatureVerification)

        let callback = HealthOperation.Callback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.callbackCache.add(callback)

        self.backendConfig.addCacheableOperation(with: factory,
                                                 withRandomDelay: false,
                                                 cacheStatus: cacheStatus)
    }

}

// MARK: - Health

private final class HealthOperation: CacheableNetworkOperation {

    struct Callback: CacheKeyProviding {

        let cacheKey: String
        let completion: InternalAPI.ResponseHandler

    }

    struct Configuration: NetworkConfiguration {

        let httpClient: HTTPClient

    }

    private let callbackCache: CallbackCache<Callback>
    private let signatureVerification: Bool

    static func createFactory(
        httpClient: HTTPClient,
        callbackCache: CallbackCache<Callback>,
        signatureVerification: Bool
    ) -> CacheableNetworkOperationFactory<HealthOperation> {
        return .init({ .init(httpClient: httpClient,
                             callbackCache: callbackCache,
                             cacheKey: $0,
                             signatureVerification: signatureVerification) },
                     individualizedCacheKeyPart: "")
    }

    private init(httpClient: HTTPClient,
                 callbackCache: CallbackCache<Callback>,
                 cacheKey: String,
                 signatureVerification: Bool) {
        self.callbackCache = callbackCache
        self.signatureVerification = signatureVerification

        super.init(configuration: Configuration(httpClient: httpClient), cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        let request = self.createRequest()

        self.httpClient.perform(request) { (response: HTTPResponse<HTTPEmptyResponseBody>.Result) in
            if self.signatureVerification, response.value?.validationResult == .failedValidation {
                self.finish(with: .failure(.signatureVerificationFailed(path: request.path)), completion: completion)
            } else {
                self.finish(with: response, completion: completion)
            }
        }
    }

    private func createRequest() -> HTTPRequest {
        var request: HTTPRequest = .init(method: .get, path: .health)

        if self.signatureVerification, #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            request.addRandomNonce()
        }

        return request
    }

    private func finish(with response: HTTPResponse<HTTPEmptyResponseBody>.Result,
                        completion: () -> Void) {
        self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
            callback.completion(
                response
                    .mapError(BackendError.networkError)
                    .error
            )
        }

        completion()
    }

}
