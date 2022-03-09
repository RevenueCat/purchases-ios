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
                                          response: Result<[String: Any], Error>,
                                          completion: SimpleResponseHandler) {
        let error = response
            .mapError { ErrorUtils.networkError(withUnderlyingError: $0) } // TODO: remove
            .error

        completion(error)
    }

}
