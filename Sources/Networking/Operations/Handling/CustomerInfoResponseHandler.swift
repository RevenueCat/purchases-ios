//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoResponseHandler.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

class CustomerInfoResponseHandler {

    init() { }

    func handle(customerInfoResponse response: Result<HTTPResponse, Error>,
                file: String = #fileID,
                function: String = #function,
                line: UInt = #line,
                completion: BackendCustomerInfoResponseHandler) {
        switch response {
        case let .failure(error):
            completion(.failure(
                ErrorUtils.networkError(withUnderlyingError: error,
                                        fileName: file, functionName: function, line: line)
            ))

        case let .success(response):
            let (statusCode, response) = (response.statusCode, response.jsonObject)
            let isErrorStatusCode = !statusCode.isSuccessfulResponse

            let errorResponse = ErrorResponse.from(response)

            var result: Result<CustomerInfo, Error> = {
                // Only attempt to parse a response if we don't have an error status code from the backend.
                if !isErrorStatusCode {
                    return Result { try CustomerInfo.from(json: response) }
                } else {
                    return .failure(errorResponse.asBackendError(with: statusCode))
                }
            }()

            let hasError = (isErrorStatusCode
                            || !errorResponse.attributeErrors.isEmpty
                            || result.error != nil)

            if hasError {
                result = .failure({
                    let responseError = errorResponse.asBackendError(with: statusCode)

                    if !isErrorStatusCode {
                        return responseError
                            .addingUnderlyingError(result.error, extraContext: response.stringRepresentation)
                    } else {
                        return responseError
                    }
                }())
            }

            completion(result)
        }
    }

}
