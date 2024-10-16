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

// Restating inherited @unchecked Sendable from Foundation's Operation
extension LogInOperation: @unchecked Sendable {}

private extension LogInOperation {

    func logIn(completion: @escaping () -> Void) {
        guard self.newAppUserID.isNotEmpty else {
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .post(Body(appUserID: self.configuration.appUserID,
                                                     newAppUserID: self.newAppUserID)),
                                  path: .logIn)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<CustomerInfo>.Result) in
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleLogin(response, completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleLogin(_ result: VerifiedHTTPResponse<CustomerInfo>.Result,
                     completion: IdentityAPI.LogInResponseHandler) {
        let result: Result<(info: CustomerInfo, created: Bool), BackendError> = result
            .map { response in
                (
                    response.body.copy(with: response.verificationResult),
                    created: response.httpStatusCode == .createdSuccess
                )
            }
            .mapError(BackendError.networkError)

        if case .success = result {
            Logger.user(Strings.identity.login_success)
        }

        completion(result)
    }
}

extension LogInOperation {

    struct Body: Encodable {

        // These need to be explicit for `contentForSignature`
        // swiftlint:disable:next nesting
        fileprivate enum CodingKeys: String, CodingKey {
            case appUserID = "app_user_id"
            case newAppUserID = "new_app_user_id"
        }

        let appUserID: String
        let newAppUserID: String

    }

}

extension LogInOperation.Body: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String?)] {
        return [
            (Self.CodingKeys.appUserID.stringValue, self.appUserID),
            (Self.CodingKeys.newAppUserID.stringValue, self.newAppUserID)
        ]
    }

}
