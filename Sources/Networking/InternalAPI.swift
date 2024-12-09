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
    func postPaywallEvents(events: [StoredEvent], completion: @escaping ResponseHandler) {
        guard !events.isEmpty else {
            completion(nil)
            return
        }

        let request = EventsRequest(events: events)
        let operation = PostPaywallEventsOperation(configuration: .init(httpClient: self.backendConfig.httpClient),
                                                   request: request,
                                                   responseHandler: completion)

        self.backendConfig.operationQueue.addOperation(operation)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func postDiagnosticsEvents(events: [DiagnosticsEvent], completion: @escaping ResponseHandler) {
        guard !events.isEmpty else {
            completion(nil)
            return
        }

        let operation = DiagnosticsPostOperation(configuration: .init(httpClient: self.backendConfig.httpClient),
                                                 request: .init(events: events),
                                                 responseHandler: completion)

        self.backendConfig.addDiagnosticsOperation(operation, delay: .long)
    }

}

extension InternalAPI {

    /// - Throws: `BackendError`
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func postPaywallEvents(events: [StoredEvent]) async throws {
        let error = await Async.call { completion in
            self.postPaywallEvents(events: events, completion: completion)
        }

        if let error { throw error }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func postDiagnosticsEvents(events: [DiagnosticsEvent]) async throws {
        let error = await Async.call { completion in
            self.postDiagnosticsEvents(events: events, completion: completion)
        }

        if let error { throw error }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension InternalAPI: @unchecked Sendable {}
