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

@_spi(Internal) @testable import RevenueCat

class PostReceiptDataOperationFactoryTests: TestCase {

    let appUserID = "abc123"
    let receipt = EncodedAppleReceipt.receipt("an awesome receipt".data(using: String.Encoding.utf8)!)

    private func createConfig() -> NetworkOperation.UserSpecificConfiguration {
        let systemInfo = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            storefrontProvider: MockStorefrontProvider(),
            storeKitVersion: .default,
            apiKey: "test_key",
            responseVerificationMode: .disabled,
            isAppBackgrounded: false,
            preferredLocalesProvider: .mock()
        )
        let httpClient = MockHTTPClient(
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
                presentedOfferingContext: nil,
                unsyncedAttributes: [attribute1.key: attribute1],
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: [attribute2.key: attribute2],
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
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
                presentedOfferingContext: nil,
                unsyncedAttributes: [attribute1.key: attribute1],
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: [attribute2.key: attribute2],
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
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

    func testCacheKeyDifferenceWhenTransactionIdChangesAndContainsAttributionData() {
        let config = self.createConfig()

        let purchaseCompletedBy: PurchasesAreCompletedBy = .revenueCat
        let observerMode = purchaseCompletedBy.observerMode

        let postData1 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: "transaction_id_1",
            containsAttributionData: true
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: "transaction_id_2",
            containsAttributionData: true
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

        // Cache keys should be different when transaction IDs differ and containsAttributionData is true
        expect(factory1.cacheKey) != factory2.cacheKey
    }

    func testCacheKeySameWhenTransactionIdChangesButDoesNotContainAttributionData() {
        let config = self.createConfig()

        let purchaseCompletedBy: PurchasesAreCompletedBy = .revenueCat
        let observerMode = purchaseCompletedBy.observerMode

        let postData1 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: "transaction_id_1",
            containsAttributionData: false
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: "transaction_id_2",
            containsAttributionData: false
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

        // Cache keys should be the same when containsAttributionData is false, regardless of transaction ID
        expect(factory1.cacheKey) == factory2.cacheKey
    }

    func testCacheKeyDifferenceForSameTransactionIdWhenContainsAttributionDataDiffers() {
        let config = self.createConfig()

        let purchaseCompletedBy: PurchasesAreCompletedBy = .revenueCat
        let observerMode = purchaseCompletedBy.observerMode
        let transactionId = "same_transaction_id"

        let postData1 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: transactionId,
            containsAttributionData: true
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: transactionId,
            containsAttributionData: false
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

        // Cache keys should be different when containsAttributionData differs for the same transaction ID
        // This ensures purchases (with attribution data) are not deduplicated with renewals (without attribution data)
        expect(factory1.cacheKey) != factory2.cacheKey
    }

    func testCacheKeySameWhenTransactionIdIsNil() {
        let config = self.createConfig()

        let purchaseCompletedBy: PurchasesAreCompletedBy = .revenueCat
        let observerMode = purchaseCompletedBy.observerMode

        let postData1 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
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

        // Cache keys should be the same when both transaction IDs are nil
        expect(factory1.cacheKey) == factory2.cacheKey
    }

    func testPresentedWorkflowIdAndStepIdAreAtTopLevelWhenPaywallHasWorkflowData() throws {
        let paywallData = PaywallEvent.Data(
            paywallIdentifier: "paywall-abc",
            offeringIdentifier: "offering-1",
            paywallRevision: 1,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            workflowId: "workflow-xyz",
            stepId: "step-123"
        )

        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: nil,
            presentedPaywall: .impression(.init(), paywallData),
            unsyncedAttributes: nil,
            storeCountry: nil
        )

        let postData = PostReceiptDataOperation.PostData(
            transactionData: transactionData,
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(postData)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        // presented_workflow_id and presented_step_id must be top-level
        expect(json["presented_workflow_id"] as? String) == "workflow-xyz"
        expect(json["presented_step_id"] as? String) == "step-123"

        // They must NOT leak into the nested paywall object
        let paywall = try XCTUnwrap(json["paywall"] as? [String: Any])
        expect(paywall["workflow_id"]).to(beNil())
        expect(paywall["step_id"]).to(beNil())
    }

    func testPresentedWorkflowIdAndStepIdAreAbsentWhenNoPaywall() throws {
        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: nil,
            presentedPaywall: nil,
            unsyncedAttributes: nil,
            storeCountry: nil
        )

        let postData = PostReceiptDataOperation.PostData(
            transactionData: transactionData,
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(postData)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        expect(json["presented_workflow_id"]).to(beNil())
        expect(json["presented_step_id"]).to(beNil())
        expect(json["paywall"]).to(beNil())
    }

    func testPresentedWorkflowIdAndStepIdAreAbsentWhenPaywallHasNoWorkflowData() throws {
        let paywallData = PaywallEvent.Data(
            paywallIdentifier: "paywall-abc",
            offeringIdentifier: "offering-1",
            paywallRevision: 1,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false
            // workflowId and stepId intentionally omitted (nil)
        )

        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: nil,
            presentedPaywall: .impression(.init(), paywallData),
            unsyncedAttributes: nil,
            storeCountry: nil
        )

        let postData = PostReceiptDataOperation.PostData(
            transactionData: transactionData,
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(postData)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        expect(json["presented_workflow_id"]).to(beNil())
        expect(json["presented_step_id"]).to(beNil())
    }

    func testCacheKeyIsUnchangedByWorkflowIdAndStepId() {
        let paywallDataWithWorkflow = PaywallEvent.Data(
            paywallIdentifier: "paywall-abc",
            offeringIdentifier: "offering-1",
            paywallRevision: 1,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            workflowId: "workflow-xyz",
            stepId: "step-123"
        )

        let config = self.createConfig()

        let postDataWithoutWorkflow = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let postDataWithWorkflow = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                presentedPaywall: .impression(.init(), paywallDataWithWorkflow),
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let factory1 = PostReceiptDataOperation.createFactory(
            configuration: config,
            postData: postDataWithoutWorkflow,
            customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>(),
            offlineCustomerInfoCreator: nil
        )

        let factory2 = PostReceiptDataOperation.createFactory(
            configuration: config,
            postData: postDataWithWorkflow,
            customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>(),
            offlineCustomerInfoCreator: nil
        )

        // workflowId/stepId are step-specific metadata; the cache is receipt-centric,
        // so two posts that differ only in workflow data should share a cache key.
        expect(factory1.cacheKey) == factory2.cacheKey
    }

    func testPresentedWorkflowIdIsEncodedAloneWhenStepIdIsNil() throws {
        let paywallData = PaywallEvent.Data(
            paywallIdentifier: "paywall-abc",
            offeringIdentifier: "offering-1",
            paywallRevision: 1,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            workflowId: "workflow-xyz"
            // stepId intentionally omitted (nil)
        )

        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: nil,
            presentedPaywall: .impression(.init(), paywallData),
            unsyncedAttributes: nil,
            storeCountry: nil
        )

        let postData = PostReceiptDataOperation.PostData(
            transactionData: transactionData,
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(postData)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        // workflowId is present but stepId is nil — each is encoded independently
        expect(json["presented_workflow_id"] as? String) == "workflow-xyz"
        expect(json["presented_step_id"]).to(beNil())
    }

    func testCacheKeyDifferenceWhenSdkOriginatedChanges() {
        let config = self.createConfig()

        let purchaseCompletedBy: PurchasesAreCompletedBy = .revenueCat
        let observerMode = purchaseCompletedBy.observerMode

        let postData1 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: "transaction_id",
            containsAttributionData: true,
            sdkOriginated: true
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                presentedOfferingContext: nil,
                unsyncedAttributes: nil,
                storeCountry: nil
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .queue),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: "transaction_id",
            containsAttributionData: true,
            sdkOriginated: false
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

        // Cache keys should be different when sdkOriginated differs, even with same transaction ID
        expect(factory1.cacheKey) != factory2.cacheKey
    }

    func testTransferBehaviorIsEncoded() throws {
        let postData = PostReceiptDataOperation.PostData(
            transactionData: .init(
                transferBehavior: TransferBehavior(rawValue: "transfer_to_new_app_user_id")
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let encodedPostData = try JSONEncoder.default.encode(postData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encodedPostData) as? [String: Any])

        expect(json["transfer_behavior"] as? String) == "transfer_to_new_app_user_id"
    }

    func testTransferBehaviorIsNotEncodedWhenNil() throws {
        let postData = PostReceiptDataOperation.PostData(
            transactionData: .init(),
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: false,
            purchaseCompletedBy: .revenueCat,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let encodedPostData = try JSONEncoder.default.encode(postData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encodedPostData) as? [String: Any])

        expect(json.keys).toNot(contain("transfer_behavior"))
    }

    func testCacheKeyDifferenceWhenTransferBehaviorChanges() {
        let config = self.createConfig()
        let purchaseCompletedBy: PurchasesAreCompletedBy = .revenueCat
        let observerMode = purchaseCompletedBy.observerMode

        let postData1 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                transferBehavior: TransferBehavior(rawValue: "transfer_to_new_app_user_id")
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
        )

        let postData2 = PostReceiptDataOperation.PostData(
            transactionData: .init(
                transferBehavior: TransferBehavior(rawValue: "keep_with_original_app_user_id")
            ),
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase),
            appUserID: self.appUserID,
            productData: nil,
            receipt: self.receipt,
            observerMode: observerMode,
            purchaseCompletedBy: purchaseCompletedBy,
            testReceiptIdentifier: nil,
            appTransaction: nil,
            transactionId: nil,
            containsAttributionData: false
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

        expect(factory1.cacheKey) != factory2.cacheKey
    }

}
