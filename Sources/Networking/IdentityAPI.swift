//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IdentityAPI.swift
//
//  Created by Joshua Liebowitz on 6/15/22.

import Foundation

class IdentityAPI {

    typealias LogInSuccess = (
        info: CustomerInfo,
        created: Bool,
        attributesErrorResponse: IdentifyAttributesErrorResponse?
    )
    typealias LogInResponse = Result<LogInSuccess, BackendError>
    typealias LogInResponseHandler = (LogInResponse) -> Void

    private let logInCallbacksCache: CallbackCache<LogInCallback>

    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.logInCallbacksCache = CallbackCache<LogInCallback>()
    }

    /// - Parameter attributes: attributes to be written to whichever subscriber the log in resolves to.
    /// - Parameter previousUnsyncedAttributes: attributes to be flushed to `currentAppUserID` before the
    /// alias decision, so they only reach the logged-in user if aliasing merges that subscriber in.
    func logIn(currentAppUserID: String,
               newAppUserID: String,
               attributes: SubscriberAttribute.Dictionary,
               previousUnsyncedAttributes: SubscriberAttribute.Dictionary,
               completion: @escaping LogInResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: currentAppUserID)

        let factory = LogInOperation.createFactory(configuration: config,
                                                   newAppUserID: newAppUserID,
                                                   attributes: attributes,
                                                   previousUnsyncedAttributes: previousUnsyncedAttributes,
                                                   loginCallbackCache: self.logInCallbacksCache)

        let loginCallback = LogInCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.logInCallbacksCache.add(loginCallback)

        self.backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension IdentityAPI: @unchecked Sendable {}
