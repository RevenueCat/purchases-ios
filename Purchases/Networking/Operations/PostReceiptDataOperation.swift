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

    override func main() {
        if self.isCancelled {
            return
        }

        self.post()
    }

    func post() {
        let fetchToken = self.postData.receiptData.asFetchToken
        var body: [String: Any] = [
            "fetch_token": fetchToken,
            "app_user_id": self.configuration.appUserID,
            "is_restore": postData.isRestore,
            "observer_mode": postData.observerMode
        ]

        if let productData = postData.productData {
            do {
                body += try productData.asDictionary()
            } catch {
                self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                    callback.completion(nil, error)
                }
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
            self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.customerInfoResponseHandler.handle(customerInfoResponse: response,
                                                        statusCode: statusCode,
                                                        maybeError: error,
                                                        completion: callbackObject.completion)
            }
        }
    }

}
