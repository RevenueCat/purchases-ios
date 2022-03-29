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
                callback.completion(.failure(ErrorUtils.missingAppUserIDError()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .post(Body(appUserID: self.configuration.appUserID,
                                                     newAppUserID: newAppUserID)),
                                  path: .logIn)

        self.httpClient.perform(request, authHeaders: self.authHeaders) { response in
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleLogin(response, completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleLogin(_ result: Result<HTTPResponse, Error>,
                     completion: LogInResponseHandler) {
        let result: Result<(info: CustomerInfo, created: Bool), Error> = result
            .mapError { ErrorUtils.networkError(withUnderlyingError: $0) }
            .flatMap { response in
                let (statusCode, response) = (response.statusCode, response.jsonObject)

                if !statusCode.isSuccessfulResponse {
                    let backendCode = BackendErrorCode(code: response["code"])
                    let backendMessage = response["message"] as? String
                    let responseError = ErrorUtils.backendError(withBackendCode: backendCode,
                                                                backendMessage: backendMessage)
                    return .failure(ErrorUtils.networkError(withUnderlyingError: responseError))
                }

                do {
                    let customerInfo = try CustomerInfo.from(json: response)
                    let created = statusCode == .createdSuccess

                    return .success((customerInfo, created))
                } catch let customerInfoError {
                    Logger.error(Strings.backendError.customer_info_instantiation_error(response: response))

                    let extraContext = "statusCode: \(statusCode)"
                    let subErrorCode = UnexpectedBackendResponseSubErrorCode
                        .loginResponseDecoding
                        .addingUnderlyingError(customerInfoError)
                    let responseError = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode,
                                                                             extraContext: extraContext)
                    return .failure(responseError)
                }
            }

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
