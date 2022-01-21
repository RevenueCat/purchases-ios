//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostReceiptDataOperation.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

class PostReceiptDataOperation: NetworkOperation {

    struct PostData {

        let receiptData: Data
        let isRestore: Bool
        let productData: ProductRequestData?
        let presentedOfferingIdentifier: String?
        let observerMode: Bool
        let subscriberAttributesByKey: SubscriberAttributeDict?

    }

    private let postData: PostData
    private let configuration: AppUserConfiguration
    private let completion: BackendCustomerInfoResponseHandler
    private let subscriberAttributesMarshaller: SubscriberAttributesMarshaller
    private let customerInfoResponseHandler: CustomerInfoResponseHandler
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>

    init(configuration: UserSpecificConfiguration,
         postData: PostData,
         completion: @escaping BackendCustomerInfoResponseHandler,
         subscriberAttributesMarshaller: SubscriberAttributesMarshaller = SubscriberAttributesMarshaller(),
         customerInfoResponseHandler: CustomerInfoResponseHandler = CustomerInfoResponseHandler(),
         customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>) {
        self.subscriberAttributesMarshaller = subscriberAttributesMarshaller
        self.customerInfoResponseHandler = customerInfoResponseHandler
        self.customerInfoCallbackCache = customerInfoCallbackCache
        self.postData = postData
        self.configuration = configuration
        self.completion = completion

        super.init(configuration: configuration)
    }

    override func main() {
        if self.isCancelled {
            return
        }

        self.post(postData: self.postData, appUserID: self.configuration.appUserID, completion: self.completion)
    }

    func post(postData: PostData,
              appUserID: String,
              completion: @escaping BackendCustomerInfoResponseHandler) {
        let fetchToken = postData.receiptData.asFetchToken
        var body: [String: Any] = [
            "fetch_token": fetchToken,
            "app_user_id": appUserID,
            "is_restore": postData.isRestore,
            "observer_mode": postData.observerMode
        ]

        let cacheKey =
        """
        \(appUserID)-\(postData.isRestore)-\(fetchToken)-\(postData.productData?.cacheKey ?? "")
        -\(postData.presentedOfferingIdentifier ?? "")-\(postData.observerMode)
        -\(postData.subscriberAttributesByKey?.debugDescription ?? "")"
        """

        let callbackObject = CustomerInfoCallback(cacheKey: cacheKey, completion: completion)
        if customerInfoCallbackCache.add(callback: callbackObject) == .addedToExistingInFlightList {
            return
        }

        if let productData = postData.productData {
            do {
                body += try productData.asDictionary()
            } catch {
                completion(nil, error)
                return
            }
        }

        if let subscriberAttributesByKey = postData.subscriberAttributesByKey {
            let attributesInBackendFormat = self.subscriberAttributesMarshaller
                .subscriberAttributesToDict(subscriberAttributes: subscriberAttributesByKey)
            body["attributes"] = attributesInBackendFormat
        }

        if let offeringIdentifier = postData.presentedOfferingIdentifier {
            body["presented_offering_identifier"] = offeringIdentifier
        }

        httpClient.performPOSTRequest(serially: true,
                                      path: "/receipts",
                                      requestBody: body,
                                      headers: authHeaders) { statusCode, response, error in
            self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withKey: cacheKey) { callbackObject in
                self.customerInfoResponseHandler.handle(customerInfoResponse: response,
                                                        statusCode: statusCode,
                                                        maybeError: error,
                                                        completion: callbackObject.completion)
            }
        }
    }

}
