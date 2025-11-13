//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostReceiptDataOperationFactoryTests.swift
//
//  Created by Antonio Pallares on 13/11/25.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class PostReceiptDataOperationFactoryTests: TestCase {

    let appUserID = "abc123"
    let receipt = EncodedAppleReceipt.receipt("an awesome receipt".data(using: String.Encoding.utf8)!)

    private func createConfig() -> NetworkOperation.UserSpecificConfiguration {
        let systemInfo = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            storefrontProvider: MockStorefrontProvider(),
            storeKitVersion: .default,
            responseVerificationMode: .disabled,
            isAppBackgrounded: false,
            preferredLocalesProvider: .mock()
        )
        let httpClient = MockHTTPClient(
            apiKey: "test_key",
            systemInfo: systemInfo,
            eTagManager: MockETagManager(),
            diagnosticsTracker: nil
        )
        return NetworkOperation.UserSpecificConfiguration(
            httpClient: httpClient,
            appUserID: self.appUserID
        )
    }

    func testCacheKeyStabilityWhenOnlyAttributeTimestampChanges() {
        let time1 = Date(timeIntervalSince1970: 1000)
        let time2 = Date(timeIntervalSince1970: 2000)
        let dateProvider1 = MockDateProvider(stubbedNow: time1)
        let dateProvider2 = MockDateProvider(stubbedNow: time2)

        let attribute1 = SubscriberAttribute(
            withKey: "test_key",
            value: "test_value",
            dateProvider: dateProvider1,
            ignoreTimeInCacheIdentity: true
        )
        let attribute2 = SubscriberAttribute(
            withKey: "test_key",
            value: "test_value",
            dateProvider: dateProvider2,
            ignoreTimeInCacheIdentity: true
        )

        let config = self.createConfig()

        let postData1 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                appUserID: self.appUserID,
                presentedOfferingContext: nil,
                unsyncedAttributes: [attribute1.key: attribute1],
                storefront: nil,
                source: .init(isRestore: false, initiationSource: .queue)
            ),
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            testReceiptIdentifier: nil,
            appTransaction: nil
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                appUserID: self.appUserID,
                presentedOfferingContext: nil,
                unsyncedAttributes: [attribute2.key: attribute2],
                storefront: nil,
                source: .init(isRestore: false, initiationSource: .queue)
            ),
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            testReceiptIdentifier: nil,
            appTransaction: nil
        )

        let factory1 = PostReceiptDataOperation.createFactory(
            configuration: config,
            postData: postData1,
            customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>(),
            offlineCustomerInfoCreator: nil
        )

        let factory2 = PostReceiptDataOperation.createFactory(
            configuration: config,
            postData: postData2,
            customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>(),
            offlineCustomerInfoCreator: nil
        )

        // Cache keys should be the same even though timestamps differ when ignoreTimeInCacheIdentity is true
        expect(factory1.cacheKey) == factory2.cacheKey
    }

    func testCacheKeyDifferenceWhenOnlyAttributeTimestampChanges() {
        let time1 = Date(timeIntervalSince1970: 1000)
        let time2 = Date(timeIntervalSince1970: 2000)
        let dateProvider1 = MockDateProvider(stubbedNow: time1)
        let dateProvider2 = MockDateProvider(stubbedNow: time2)

        let attribute1 = SubscriberAttribute(
            withKey: "test_key",
            value: "test_value",
            dateProvider: dateProvider1,
            ignoreTimeInCacheIdentity: false
        )
        let attribute2 = SubscriberAttribute(
            withKey: "test_key",
            value: "test_value",
            dateProvider: dateProvider2,
            ignoreTimeInCacheIdentity: false
        )

        let config = self.createConfig()

        let postData1 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                appUserID: self.appUserID,
                presentedOfferingContext: nil,
                unsyncedAttributes: [attribute1.key: attribute1],
                storefront: nil,
                source: .init(isRestore: false, initiationSource: .queue)
            ),
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            testReceiptIdentifier: nil,
            appTransaction: nil
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                appUserID: self.appUserID,
                presentedOfferingContext: nil,
                unsyncedAttributes: [attribute2.key: attribute2],
                storefront: nil,
                source: .init(isRestore: false, initiationSource: .queue)
            ),
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            testReceiptIdentifier: nil,
            appTransaction: nil
        )

        let factory1 = PostReceiptDataOperation.createFactory(
            configuration: config,
            postData: postData1,
            customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>(),
            offlineCustomerInfoCreator: nil
        )

        let factory2 = PostReceiptDataOperation.createFactory(
            configuration: config,
            postData: postData2,
            customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>(),
            offlineCustomerInfoCreator: nil
        )

        // Cache keys should be different when timestamps differ and ignoreTimeInCacheIdentity is false
        expect(factory1.cacheKey) != factory2.cacheKey
    }

}

