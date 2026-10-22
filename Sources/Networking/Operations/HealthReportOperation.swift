//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HealthReportOperation.swift
//
//  Created by Pol Piella on 4/8/25.

#if DEBUG
import Foundation

final class HealthReportOperation: CacheableNetworkOperation {

    struct Callback: CacheKeyProviding {

        let cacheKey: String
        let completion: InternalAPI.HealthReportResponseHandler

    }

    private let configuration: AppUserConfiguration
    private let callbackCache: CallbackCache<Callback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        callbackCache: CallbackCache<Callback>
    ) -> CacheableNetworkOperationFactory<HealthReportOperation> {
        return .init({ .init(configuration: configuration,
                             callbackCache: callbackCache,
                             cacheKey: $0) },
                     individualizedCacheKeyPart: "")
    }

    private init(configuration: UserSpecificConfiguration,
                 callbackCache: CallbackCache<Callback>,
                 cacheKey: String) {
        self.configuration = configuration
        self.callbackCache = callbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        let request: HTTPRequest = .init(method: .get,
                                         path: .appHealthReport(appUserID: configuration.appUserID))

        self.httpClient.perform(
            request
        ) { (response: VerifiedHTTPResponse<HealthReport>.Result) in
            self.finish(with: response, completion: completion)
        }
    }

    private func finish(with response: VerifiedHTTPResponse<HealthReport>.Result,
                        completion: () -> Void) {
        self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
            callback.completion(
                response
                    .mapError(BackendError.networkError)
                    .map { $0.body }
            )
        }

        completion()
    }
}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension HealthReportOperation: @unchecked Sendable {}
#endif
