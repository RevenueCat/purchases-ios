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
    #if DEBUG
    typealias HealthReportResponseHandler = (Result<HealthReport, BackendError>) -> Void
    typealias HealthReportAvailabilityResponseHandler = (Result<HealthReportAvailability, BackendError>) -> Void

    private let healthReportCallbackCache: CallbackCache<HealthReportOperation.Callback>
    private let healthReportAvailabilityCallbackCache: CallbackCache<HealthReportAvailabilityOperation.Callback>
    #endif

    private let backendConfig: BackendConfiguration
    private let healthCallbackCache: CallbackCache<HealthOperation.Callback>

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.healthCallbackCache = .init()
        #if DEBUG
        self.healthReportCallbackCache = .init()
        self.healthReportAvailabilityCallbackCache = .init()
        #endif
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

    #if DEBUG
    func healthReportRequest(appUserID: String, completion: @escaping HealthReportResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = HealthReportOperation.createFactory(configuration: config,
                                                          callbackCache: self.healthReportCallbackCache)
        let callback = HealthReportOperation.Callback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.healthReportCallbackCache.add(callback)

        self.backendConfig.addCacheableOperation(with: factory,
                                                 delay: .none,
                                                 cacheStatus: cacheStatus)
    }

    func healthReportAvailabilityRequest(
        appUserID: String,
        completion: @escaping HealthReportAvailabilityResponseHandler
    ) {
        let config = NetworkOperation.UserSpecificConfiguration(
            httpClient: self.backendConfig.httpClient,
            appUserID: appUserID
        )
        let factory = HealthReportAvailabilityOperation.createFactory(
            configuration: config,
            callbackCache: self.healthReportAvailabilityCallbackCache
        )
        let callback = HealthReportAvailabilityOperation.Callback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.healthReportAvailabilityCallbackCache.add(callback)

        self.backendConfig.addCacheableOperation(with: factory,
                                                 delay: .none,
                                                 cacheStatus: cacheStatus)
    }
    #endif

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func postFeatureEvents(events: [StoredFeatureEvent], completion: @escaping ResponseHandler) {
        guard !events.isEmpty else {
            completion(nil)
            return
        }

        let request = FeatureEventsRequest(events: events)
        let operation = PostFeatureEventsOperation(
            configuration: .init(httpClient: self.backendConfig.httpClient),
            request: request,
            path: HTTPRequest.FeatureEventsPath.postEvents,
            responseHandler: completion
        )

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

    #if ENABLE_AD_EVENTS_TRACKING
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func postAdEvents(events: [StoredAdEvent], completion: @escaping ResponseHandler) {
        guard !events.isEmpty else {
            completion(nil)
            return
        }

        let request = AdEventsRequest(events: events)
        let operation = PostAdEventsOperation(
            configuration: .init(httpClient: self.backendConfig.httpClient),
            request: request,
            path: HTTPRequest.AdPath.postEvents,
            responseHandler: completion
        )

        self.backendConfig.operationQueue.addOperation(operation)
    }
    #endif

}

extension InternalAPI {

    /// - Throws: `BackendError`
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func postFeatureEvents(events: [StoredFeatureEvent]) async throws {
        let error = await Async.call { completion in
            self.postFeatureEvents(events: events, completion: completion)
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

    #if ENABLE_AD_EVENTS_TRACKING
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func postAdEvents(events: [StoredAdEvent]) async throws {
        let error = await Async.call { completion in
            self.postAdEvents(events: events, completion: completion)
        }

        if let error { throw error }
    }
    #endif

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension InternalAPI: @unchecked Sendable {}
