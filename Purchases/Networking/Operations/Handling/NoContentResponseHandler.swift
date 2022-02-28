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

    func handle(response: [String: Any]?,
                statusCode: HTTPStatusCode,
                error: Error?,
                completion: SimpleResponseHandler) {
        if let error = error {
            completion(ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        guard statusCode.isValidResponse else {
            let backendErrorCode = BackendErrorCode(code: response?["code"])
            let message = response?["message"] as? String
            let responseError = ErrorUtils.backendError(withBackendCode: backendErrorCode, backendMessage: message)
            completion(responseError)
            return
        }

        completion(nil)
    }

}
