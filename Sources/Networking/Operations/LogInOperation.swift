//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LogInOperation.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

final class LogInOperation: CacheableNetworkOperation {

    private let loginCallbackCache: CallbackCache<LogInCallback>
    private let configuration: UserSpecificConfiguration
    private let newAppUserID: String

    static func createFactory(
        configuration: UserSpecificConfiguration,
        newAppUserID: String,
        loginCallbackCache: CallbackCache<LogInCallback>
    ) -> CacheableNetworkOperationFactory<LogInOperation> {
        return .init({
            .init(
                configuration: configuration,
                newAppUserID: newAppUserID,
                loginCallbackCache: loginCallbackCache,
                cacheKey: $0
            ) },
                     individualizedCacheKeyPart: configuration.appUserID + newAppUserID)
    }

    private init(
        configuration: UserSpecificConfiguration,
        newAppUserID: String,
        loginCallbackCache: CallbackCache<LogInCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.newAppUserID = newAppUserID
        self.loginCallbackCache = loginCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.logIn(completion: completion)
    }

}

private extension LogInOperation {

    func logIn(completion: @escaping () -> Void) {
        guard let newAppUserID = try? self.newAppUserID.trimmedOrError() else {
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .post(Body(appUserID: self.configuration.appUserID,
                                                     newAppUserID: newAppUserID)),
                                  path: .logIn)

        self.httpClient.perform(request) { (response: HTTPResponse<CustomerInfo>.Result) in
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleLogin(response, completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleLogin(_ result: HTTPResponse<CustomerInfo>.Result,
                     completion: IdentityAPI.LogInResponseHandler) {
        let result: Result<(info: CustomerInfo, created: Bool), BackendError> = result
            .map { response in
                (response.body, created: response.statusCode == .createdSuccess)
            }
            .mapError(BackendError.networkError)

        if case .success = result {
            Logger.user(Strings.identity.login_success)
        }

        completion(result)
    }
}

private extension LogInOperation {

    struct Body: Encodable {

        let appUserID: String
        let newAppUserID: String

    }

}
