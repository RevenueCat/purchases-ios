//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetOfferingsOperation.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

class GetOfferingsOperation: NetworkOperation {

    private let offeringsCallbackCache: CallbackCache<OfferingsCallback>
    private let configuration: AppUserConfiguration
    private let completion: OfferingsResponseHandler

    init(configuration: UserSpecificConfiguration,
         completion: @escaping OfferingsResponseHandler,
         offeringsCallbackCache: CallbackCache<OfferingsCallback>) {
        self.configuration = configuration
        self.completion = completion
        self.offeringsCallbackCache = offeringsCallbackCache

        super.init(configuration: configuration)
    }

    override func main() {
        if self.isCancelled {
            return
        }

        self.getOfferings(appUserID: self.configuration.appUserID, completion: self.completion)
    }

    func getOfferings(appUserID: String, completion: @escaping OfferingsResponseHandler) {
        guard let appUserID = try? appUserID.escapedOrError() else {
            completion(nil, ErrorUtils.missingAppUserIDError())
            return
        }

        let path = "/subscribers/\(appUserID)/offerings"
        let offeringsCallback = OfferingsCallback(key: path, callback: completion)
        if self.offeringsCallbackCache.add(callback: offeringsCallback) == .addedToExistingInFlightList {
            return
        }

        httpClient.performGETRequest(serially: true,
                                     path: path,
                                     headers: authHeaders) { statusCode, maybeResponse, maybeError in
            if maybeError == nil && statusCode < HTTPStatusCodes.redirect.rawValue {
                self.offeringsCallbackCache.performOnAllItemsAndRemoveFromCache(withKey: path) { callbackObject in
                    callbackObject.callback(maybeResponse, nil)
                }
                return
            }

            let errorForCallbacks: Error
            if let error = maybeError {
                errorForCallbacks = ErrorUtils.networkError(withUnderlyingError: error)
            } else if statusCode >= HTTPStatusCodes.redirect.rawValue {
                let backendCode = BackendErrorCode(maybeCode: maybeResponse?["code"])
                let backendMessage = maybeResponse?["message"] as? String
                errorForCallbacks = ErrorUtils.backendError(withBackendCode: backendCode,
                                                            backendMessage: backendMessage)
            } else {
                let subErrorCode = UnexpectedBackendResponseSubErrorCode.getOfferUnexpectedResponse
                errorForCallbacks = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
            }

            let responseString = maybeResponse?.debugDescription
            Logger.error(Strings.backendError.unknown_get_offerings_error(statusCode: statusCode,
                                                                          maybeResponseString: responseString))
            self.offeringsCallbackCache.performOnAllItemsAndRemoveFromCache(withKey: path) { callbackObject in
                callbackObject.callback(nil, errorForCallbacks)
            }
        }
    }

}
