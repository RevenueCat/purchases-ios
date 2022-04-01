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
                completion: BackendCustomerInfoResponseHandler) {
        let errorResponse = ErrorResponse.from(response.value?.jsonObject ?? [:])

        let result: Result<CustomerInfo, Error> = response
            .flatMap { response in
                Result {
                    (
                        response: response,
                        info: try CustomerInfo.from(json: response.jsonObject)
                    )
                }
                .mapError {
                    errorResponse
                        .asBackendError(with: response.statusCode)
                        .addingUnderlyingError($0)
                }
            }
            .flatMap { response, info in
                if !errorResponse.attributeErrors.isEmpty {
                    return .failure(errorResponse.asBackendError(with: response.statusCode))
                } else {
                    return .success(info)
                }
            }

        completion(result)
    }

}
