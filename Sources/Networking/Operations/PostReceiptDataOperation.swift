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

class PostReceiptDataOperation: CacheableNetworkOperation {

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
    private let subscriberAttributesMarshaller: SubscriberAttributesMarshaller
    private let customerInfoResponseHandler: CustomerInfoResponseHandler
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>

    init(configuration: UserSpecificConfiguration,
         postData: PostData,
         subscriberAttributesMarshaller: SubscriberAttributesMarshaller = SubscriberAttributesMarshaller(),
         customerInfoResponseHandler: CustomerInfoResponseHandler = CustomerInfoResponseHandler(),
         customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>) {
        self.subscriberAttributesMarshaller = subscriberAttributesMarshaller
        self.customerInfoResponseHandler = customerInfoResponseHandler
        self.customerInfoCallbackCache = customerInfoCallbackCache
        self.postData = postData
        self.configuration = configuration

        let cacheKey =
        """
        \(configuration.appUserID)-\(postData.isRestore)-\(postData.receiptData.asFetchToken)
        -\(postData.productData?.cacheKey ?? "")
        -\(postData.presentedOfferingIdentifier ?? "")-\(postData.observerMode)
        -\(postData.subscriberAttributesByKey?.debugDescription ?? "")"
        """

        super.init(configuration: configuration, individualizedCacheKeyPart: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        let fetchToken = self.postData.receiptData.asFetchToken
        var body: [String: Any] = [
            "fetch_token": fetchToken,
            "app_user_id": self.configuration.appUserID,
            "is_restore": self.postData.isRestore,
            "observer_mode": self.postData.observerMode
        ]

        if let productData = self.postData.productData {
            do {
                body += try productData.asDictionary()
            } catch {
                self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                    callback.completion(nil, error)
                }

                completion()
                return
            }
        }

        if let subscriberAttributesByKey = self.postData.subscriberAttributesByKey {
            let attributesInBackendFormat = self.subscriberAttributesMarshaller
                .map(subscriberAttributes: subscriberAttributesByKey)
            body["attributes"] = attributesInBackendFormat
        }

        if let offeringIdentifier = self.postData.presentedOfferingIdentifier {
            body["presented_offering_identifier"] = offeringIdentifier
        }

        let request = HTTPRequest(method: .post(body: body), path: .postReceiptData)

        httpClient.perform(request, authHeaders: self.authHeaders) { statusCode, response, error in
            self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.customerInfoResponseHandler.handle(customerInfoResponse: response,
                                                        statusCode: statusCode,
                                                        error: error,
                                                        completion: callbackObject.completion)
            }

            completion()
        }
    }

}
