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

class LogInOperation: CacheableNetworkOperation {

    private let loginCallbackCache: CallbackCache<LogInCallback>
    private let configuration: UserSpecificConfiguration
    private let newAppUserID: String

    init(configuration: UserSpecificConfiguration,
         newAppUserID: String,
         loginCallbackCache: CallbackCache<LogInCallback>) {
        self.configuration = configuration
        self.newAppUserID = newAppUserID
        self.loginCallbackCache = loginCallbackCache

        super.init(configuration: configuration, individualizedCacheKeyPart: configuration.appUserID + newAppUserID)
    }

    override func begin(completion: @escaping () -> Void) {
        self.logIn(completion: completion)
    }

}

private extension LogInOperation {

    func logIn(completion: @escaping () -> Void) {
        guard let newAppUserID = try? self.newAppUserID.trimmedOrError() else {
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(nil, false, ErrorUtils.missingAppUserIDError())
            }
            completion()

            return
        }

        let requestBody = ["app_user_id": self.configuration.appUserID, "new_app_user_id": newAppUserID]
        self.httpClient.performPOSTRequest(path: "/subscribers/identify",
                                           requestBody: requestBody,
                                           headers: self.authHeaders) { statusCode, response, error in
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleLogin(response: response,
                                 statusCode: statusCode,
                                 error: error,
                                 completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleLogin(response: [String: Any]?,
                     statusCode: Int,
                     error: Error?,
                     completion: LogInResponseHandler) {
        if let error = error {
            completion(nil, false, ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        guard let response = response else {
            let subErrorCode = UnexpectedBackendResponseSubErrorCode.loginMissingResponse
            let responseError = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
            completion(nil, false, responseError)
            return
        }

        if statusCode > HTTPStatusCodes.redirect.rawValue {
            let backendCode = BackendErrorCode(code: response["code"])
            let backendMessage = response["message"] as? String
            let responsError = ErrorUtils.backendError(withBackendCode: backendCode, backendMessage: backendMessage)
            completion(nil, false, ErrorUtils.networkError(withUnderlyingError: responsError))
            return
        }

        do {
            let customerInfo = try CustomerInfo.from(json: response)
            let created = statusCode == HTTPStatusCodes.createdSuccess.rawValue
            Logger.user(Strings.identity.login_success)
            completion(customerInfo, created, nil)
        } catch let customerInfoError {
            Logger.error(Strings.backendError.customer_info_instantiation_error(response: response))
            let extraContext = "statusCode: \(statusCode)"
            let subErrorCode = UnexpectedBackendResponseSubErrorCode
                .loginResponseDecoding
                .addingUnderlyingError(customerInfoError)
            let responseError = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode,
                                                                     extraContext: extraContext)
            completion(nil, false, responseError)
        }
    }
}
