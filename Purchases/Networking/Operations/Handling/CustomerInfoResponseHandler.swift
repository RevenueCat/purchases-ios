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
    func handle(customerInfoResponse maybeResponse: [String: Any]?,
                statusCode: Int,
                maybeError: Error?,
                file: String = #fileID,
                function: String = #function,
                line: UInt = #line,
                completion: BackendCustomerInfoResponseHandler) {
        if let error = maybeError {
            completion(nil, ErrorUtils.networkError(withUnderlyingError: error,
                                                    fileName: file, functionName: function, line: line))
            return
        }
        let isErrorStatusCode = statusCode >= HTTPStatusCodes.redirect.rawValue

        let maybeCustomerInfoError: Error?
        let maybeCustomerInfo: CustomerInfo?

        if !isErrorStatusCode {
            // Only attempt to parse a response if we don't have an error status code from the backend.
            do {
                maybeCustomerInfo = try CustomerInfo.from(json: maybeResponse)
                maybeCustomerInfoError = nil
            } catch let customerInfoError {
                maybeCustomerInfo = nil
                maybeCustomerInfoError = customerInfoError
            }
        } else {
            maybeCustomerInfoError = nil
            maybeCustomerInfo = nil
        }

        if !isErrorStatusCode && maybeCustomerInfo == nil {
            let extraContext = "statusCode: \(statusCode), json:\(maybeResponse.debugDescription)"
            completion(nil, ErrorUtils.unexpectedBackendResponse(withSubError: maybeCustomerInfoError,
                                                                 extraContext: extraContext,
                                                                 fileName: file, functionName: function, line: line))
            return
        }

        let subscriberAttributesErrorInfo = self.userInfoAttributeParser
            .attributesUserInfoFromResponse(response: maybeResponse ?? [:], statusCode: statusCode)

        let hasError = (isErrorStatusCode
                        || subscriberAttributesErrorInfo[Backend.RCAttributeErrorsKey] != nil
                        || maybeCustomerInfoError != nil)

        guard !hasError else {
            let finishable = statusCode < HTTPStatusCodes.internalServerError.rawValue
            var extraUserInfo = [ErrorDetails.finishableKey: finishable] as [String: Any]
            extraUserInfo.merge(subscriberAttributesErrorInfo) { _, new in new }
            let backendErrorCode = BackendErrorCode(maybeCode: maybeResponse?["code"])
            let message = maybeResponse?["message"] as? String
            var responseError = ErrorUtils.backendError(withBackendCode: backendErrorCode,
                                                        backendMessage: message,
                                                        extraUserInfo: extraUserInfo as [NSError.UserInfoKey: Any])
            if let maybeCustomerInfoError = maybeCustomerInfoError {
                responseError = maybeCustomerInfoError
                    .addingUnderlyingError(responseError, extraContext: maybeResponse?.stringRepresentation)
            }

            completion(maybeCustomerInfo, responseError)
            return
        }

        completion(maybeCustomerInfo, nil)
    }

}
