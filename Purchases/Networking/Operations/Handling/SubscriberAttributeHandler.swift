//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttributeHandler.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

class SubscriberAttributeHandler {

    let userInfoAttributeParser: UserInfoAttributeParser

    init(userInfoAttributeParser: UserInfoAttributeParser = UserInfoAttributeParser()) {
        self.userInfoAttributeParser = userInfoAttributeParser
    }

    func handleSubscriberAttributesResult(statusCode: HTTPStatusCode,
                                          response: [String: Any]?,
                                          error: Error?,
                                          completion: SimpleResponseHandler) {
        if let error = error {
            completion(ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        let responseError: Error?

        if let response = response, !statusCode.isValidResponse {
            let extraUserInfo = self.userInfoAttributeParser
                .attributesUserInfoFromResponse(response: response, statusCode: statusCode)
            let backendErrorCode = BackendErrorCode(code: response["code"])
            responseError = ErrorUtils.backendError(withBackendCode: backendErrorCode,
                                                    backendMessage: response["message"] as? String,
                                                    extraUserInfo: extraUserInfo as [NSError.UserInfoKey: Any])
        } else {
            responseError = nil
        }

        completion(responseError)
    }

}
