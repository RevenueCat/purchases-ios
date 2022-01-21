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

    func handleSubscriberAttributesResult(statusCode: Int,
                                          maybeResponse: [String: Any]?,
                                          maybeError: Error?,
                                          maybeCompletion: PostRequestResponseHandler?) {
        guard let completion = maybeCompletion else {
            return
        }

        if let error = maybeError {
            completion(ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        let responseError: Error?

        if let response = maybeResponse, statusCode > HTTPStatusCodes.redirect.rawValue {
            let extraUserInfo = self.userInfoAttributeParser
                .attributesUserInfoFromResponse(response: response, statusCode: statusCode)
            let backendErrorCode = BackendErrorCode(maybeCode: response["code"])
            responseError = ErrorUtils.backendError(withBackendCode: backendErrorCode,
                                                    backendMessage: response["message"] as? String,
                                                    extraUserInfo: extraUserInfo as [NSError.UserInfoKey: Any])
        } else {
            responseError = nil
        }

        completion(responseError)
    }

}
