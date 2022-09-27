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

        let appUserID: String
        let receiptData: Data
        let isRestore: Bool
        let productData: ProductRequestData?
        let presentedOfferingIdentifier: String?
        let observerMode: Bool
        let subscriberAttributesByKey: SubscriberAttribute.Dictionary?

    }

    private let postData: PostData
    private let configuration: AppUserConfiguration
    private let customerInfoResponseHandler: CustomerInfoResponseHandler
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>

    init(configuration: UserSpecificConfiguration,
         postData: PostData,
         customerInfoResponseHandler: CustomerInfoResponseHandler = CustomerInfoResponseHandler(),
         customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>) {
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
        if Logger.logLevel == .debug {
            self.printReceiptData()
        }

        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(self.postData), path: .postReceiptData)

        httpClient.perform(request) { (response: HTTPResponse<CustomerInfoResponseHandler.Response>.Result) in
            self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.customerInfoResponseHandler.handle(customerInfoResponse: response,
                                                        completion: callbackObject.completion)
            }

            completion()
        }
    }

}

// MARK: - Private

private extension PostReceiptDataOperation {

    func printReceiptData() {
        do {
            self.log(Strings.receipt.posting_receipt(
                try ReceiptParser.default.parse(from: self.postData.receiptData)
            ))
        } catch {
            Logger.appleError(Strings.receipt.parse_receipt_locally_error(error: error))
        }
    }

}

// MARK: - Request Data

extension PostReceiptDataOperation.PostData: Encodable {

    private enum CodingKeys: String, CodingKey {

        case fetchToken
        case appUserID
        case isRestore
        case observerMode
        case attributes
        case presentedOfferingIdentifier

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.receiptData.asFetchToken, forKey: .fetchToken)
        try container.encode(self.appUserID, forKey: .appUserID)
        try container.encode(self.isRestore, forKey: .isRestore)
        try container.encode(self.observerMode, forKey: .observerMode)

        if let productData = self.productData {
            try productData.encode(to: encoder)
        }

        try container.encodeIfPresent(self.presentedOfferingIdentifier,
                                      forKey: .presentedOfferingIdentifier)

        try container.encodeIfPresent(
            self.subscriberAttributesByKey
                .map(SubscriberAttribute.map)
                .map(AnyEncodable.init),
            forKey: .attributes
        )
    }

}
