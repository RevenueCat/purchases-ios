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

class InternalAPI {

    typealias ResponseHandler = (BackendError?) -> Void

    private let backendConfig: BackendConfiguration
    private let healthCallbackCache: CallbackCache<HealthOperation.Callback>

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.healthCallbackCache = .init()
    }

    func healthRequest(signatureVerification: Bool, completion: @escaping ResponseHandler) {
        let factory = HealthOperation.createFactory(httpClient: self.backendConfig.httpClient,
                                                    callbackCache: self.healthCallbackCache,
                                                    signatureVerification: signatureVerification)

        let callback = HealthOperation.Callback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.healthCallbackCache.add(callback)

        self.backendConfig.addCacheableOperation(with: factory,
                                                 delay: .none,
                                                 cacheStatus: cacheStatus)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func postPaywallEvents(events: [PaywallStoredEvent], completion: @escaping ResponseHandler) {
        guard !events.isEmpty else {
            self.backendConfig.operationDispatcher.dispatchOnMainThread {
                completion(nil)
            }
            return
        }

        let operation = PostPaywallEventsOperation(configuration: .init(httpClient: self.backendConfig.httpClient),
                                                   request: .init(events: events),
                                                   responseHandler: completion)

        self.backendConfig.operationQueue.addOperation(operation)
    }

}

extension InternalAPI {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func postPaywallEvents(events: [PaywallStoredEvent]) async -> BackendError? {
        return await Async.call { completion in
            self.postPaywallEvents(events: events, completion: completion)
        }
    }

}
