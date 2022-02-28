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

    let userInfoAttributeParser: UserInfoAttributeParser

    init(userInfoAttributeParser: UserInfoAttributeParser = UserInfoAttributeParser()) {
        self.userInfoAttributeParser = userInfoAttributeParser
    }

    // swiftlint:disable:next function_body_length
    func handle(customerInfoResponse response: [String: Any]?,
                statusCode: Int,
                error: Error?,
                file: String = #fileID,
                function: String = #function,
                line: UInt = #line,
                completion: BackendCustomerInfoResponseHandler) {
        if let error = error {
            completion(nil, ErrorUtils.networkError(withUnderlyingError: error,
                                                    fileName: file, functionName: function, line: line))
            return
        }
        let isErrorStatusCode = statusCode >= HTTPStatusCode.redirect.rawValue

        let customerInfoError: Error?
        let customerInfo: CustomerInfo?

        if !isErrorStatusCode {
            // Only attempt to parse a response if we don't have an error status code from the backend.
            do {
                customerInfo = try CustomerInfo.from(json: response)
                customerInfoError = nil
            } catch let error {
                customerInfo = nil
                customerInfoError = error
            }
        } else {
            customerInfoError = nil
            customerInfo = nil
        }

        if !isErrorStatusCode && customerInfo == nil {
            let extraContext = "statusCode: \(statusCode), json:\(response.debugDescription)"
            completion(nil, ErrorUtils.unexpectedBackendResponse(withSubError: customerInfoError,
                                                                 extraContext: extraContext,
                                                                 fileName: file, functionName: function, line: line))
            return
        }

        let subscriberAttributesErrorInfo = self.userInfoAttributeParser
            .attributesUserInfoFromResponse(response: response ?? [:], statusCode: statusCode)

        let hasError = (isErrorStatusCode
                        || subscriberAttributesErrorInfo[Backend.RCAttributeErrorsKey] != nil
                        || customerInfoError != nil)

        guard !hasError else {
            let finishable = statusCode < HTTPStatusCode.internalServerError.rawValue
            var extraUserInfo = [ErrorDetails.finishableKey: finishable] as [String: Any]
            extraUserInfo.merge(subscriberAttributesErrorInfo) { _, new in new }
            let backendErrorCode = BackendErrorCode(code: response?["code"])
            let message = response?["message"] as? String
            var responseError = ErrorUtils.backendError(withBackendCode: backendErrorCode,
                                                        backendMessage: message,
                                                        extraUserInfo: extraUserInfo as [NSError.UserInfoKey: Any])
            if let customerInfoError = customerInfoError {
                responseError = customerInfoError
                    .addingUnderlyingError(responseError, extraContext: response?.stringRepresentation)
            }

            completion(customerInfo, responseError)
            return
        }

        completion(customerInfo, nil)
    }

}
