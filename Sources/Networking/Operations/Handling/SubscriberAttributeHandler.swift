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

    init() { }

    func handleSubscriberAttributesResult(_ response: Result<HTTPResponse, Error>,
                                          completion: SimpleResponseHandler) {
        let result: Result<[String: Any], Error> = response
            .mapError {
                ErrorUtils.networkError(withUnderlyingError: $0)
            }
            .flatMap { response in
                let (statusCode, response) = (response.statusCode, response.jsonObject)

                if !statusCode.isSuccessfulResponse {
                    return .failure(
                        ErrorResponse
                            .from(response)
                            .asBackendError(with: statusCode)
                    )
                } else {
                    return .success(response)
                }
            }

        completion(result.error)
    }

}
