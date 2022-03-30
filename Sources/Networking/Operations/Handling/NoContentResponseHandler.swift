//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NoContentResponseHandler.swift
//
//  Created by Joshua Liebowitz on 11/30/21.

import Foundation

class NoContentResponseHandler {

    func handle(_ response: Result<HTTPResponse, Error>,
                completion: SimpleResponseHandler) {
        switch response {
        case let .success(response):
            guard response.statusCode.isSuccessfulResponse else {
                completion(
                    ErrorResponse
                        .from(response.jsonObject)
                        .asBackendError(with: response.statusCode)
                )

                return
            }

            completion(nil)

        case let .failure(error):
            completion(ErrorUtils.networkError(withUnderlyingError: error))
        }
    }

}
