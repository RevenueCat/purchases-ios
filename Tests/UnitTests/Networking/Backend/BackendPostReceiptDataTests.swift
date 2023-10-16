//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostReceiptDataTests.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BaseBackendPostReceiptDataTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        return self.createClient(#file)
    }

}

class BackendPostReceiptDataTests: BaseBackendPostReceiptDataTests {

    func testPostsReceiptDataCorrectly() throws {
        let path: HTTPRequest.Path = .postReceiptData

        httpClient.mock(
            requestPath: path,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let isRestore = false
        let observerMode = true

        waitUntil { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: nil,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: isRestore, initiationSource: .queue)
                              ),
                              observerMode: observerMode,
                              completion: { _ in
                completed()
            })
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testPostsReceiptDataWithProductDataCorrectly() throws {
        let path: HTTPRequest.Path = .postReceiptData

        httpClient.mock(
            requestPath: path,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let isRestore = false
        let observerMode = true
        let productData: ProductRequestData = .createMockProductData(currencyCode: "USD")

        waitUntil { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: productData,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: isRestore, initiationSource: .purchase)
                              ),
                              observerMode: observerMode,
                              completion: { _ in
                completed()
            })
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testPostsReceiptDataWithTestReceiptIdentifier() throws {
        let identifier = try XCTUnwrap(UUID(uuidString: "12345678-1234-1234-1234-C2C35AE34D09")).uuidString

        self.createDependencies(
            SystemInfo(
                platformInfo: nil,
                finishTransactions: false,
                dangerousSettings: .init(
                    autoSyncPurchases: true,
                    internalSettings: DangerousSettings.Internal(testReceiptIdentifier: identifier)
                )
            )
        )

        let path: HTTPRequest.Path = .postReceiptData

        self.httpClient.mock(
            requestPath: path,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        waitUntil { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: .createMockProductData(),
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .purchase)
                              ),
                              observerMode: true,
                              completion: { _ in
                completed()
            })
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testCachesRequestsForSameReceipt() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let completionCalled: Atomic<Int> = .init(0)

        let isRestore = true
        let observerMode = false

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .purchase)
                     ),
                     observerMode: observerMode) { _ in
            completionCalled.value += 1
        }

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(completionCalled.value).toEventually(equal(2))
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testDoesntCacheForDifferentRestore() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let completionCalled: Atomic<Int> = .init(0)

        let isRestore = false
        let observerMode = false

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .purchase)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: !isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled.value).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentReceipts() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let completionCalled: Atomic<Int> = .init(0)

        let isRestore = true
        let observerMode = true

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        backend.post(receipt: Self.receipt2,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2), timeout: defaultTimeout)
        expect(completionCalled.value).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentCurrency() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let completionCalled: Atomic<Int> = .init(0)

        let isRestore = false
        let observerMode = true

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .purchase)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })
        let productData: ProductRequestData = .createMockProductData(currencyCode: "USD")

        backend.post(receipt: Self.receipt2,
                     productData: productData,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .purchase)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled.value).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentOffering() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let completionCalled: Atomic<Int> = .init(0)

        let isRestore = true
        let observerMode = false

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: "offering_a",
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        backend.post(receipt: Self.receipt2,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: "offering_b",
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled.value).toEventually(equal(2))
    }

    func testPostsReceiptDataWithProductRequestDataCorrectly() throws {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let productIdentifier = "a_great_product"
        let offeringIdentifier = "a_offering"
        let price: Decimal = 10.98
        let group = "sub_group"

        let currencyCode = "BFD"

        let paymentMode: StoreProductDiscount.PaymentMode? = nil

        let productData: ProductRequestData = .createMockProductData(productIdentifier: productIdentifier,
                                                                     paymentMode: paymentMode,
                                                                     currencyCode: currencyCode,
                                                                     price: price,
                                                                     subscriptionGroup: group)

        waitUntil { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: productData,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: offeringIdentifier,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .purchase)
                              ),
                              observerMode: false,
                              completion: { _ in
                completed()
            })
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testPostsReceiptDataWithPresentedPaywall() throws {
        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let productIdentifier = "a_great_product"
        let offeringIdentifier = "a_offering"
        let price: Decimal = 10.98
        let group = "sub_group"

        let currencyCode = "BFD"

        let paywallEventData: PaywallEvent.Data = .init(
            offeringIdentifier: offeringIdentifier,
            paywallRevision: 5,
            sessionID: .init(uuidString: "73616D70-6C65-2073-7472-696E67000000")!,
            displayMode: .condensedFooter,
            localeIdentifier: "en_US",
            darkMode: true,
            date: .init(timeIntervalSince1970: 1694029328)
        )

        let productData: ProductRequestData = .createMockProductData(productIdentifier: productIdentifier,
                                                                     paymentMode: nil,
                                                                     currencyCode: currencyCode,
                                                                     price: price,
                                                                     subscriptionGroup: group)

        waitUntil { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: productData,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: offeringIdentifier,
                                 presentedPaywall: paywallEventData,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .purchase)
                              ),
                              observerMode: false,
                              completion: { _ in
                completed()
            })
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testIndividualParamsCanBeNil() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success,
                            response: Self.validCustomerResponse)
        )

        let productData: ProductRequestData = .createMockProductData()

        waitUntil { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: productData,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .queue)
                              ),
                              observerMode: false,
                              completion: { _ in
                completed()
            })
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testPayAsYouGoPostsCorrectly() throws {
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)
        httpClient.mock(requestPath: .postReceiptData, response: response)
        self.postPaymentMode(paymentMode: .payAsYouGo)
    }

    func testPayUpFrontPostsCorrectly() throws {
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)
        httpClient.mock(requestPath: .postReceiptData, response: response)
        self.postPaymentMode(paymentMode: .payUpFront)
    }

    func testFreeTrialPostsCorrectly() throws {
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)
        httpClient.mock(requestPath: .postReceiptData, response: response)
        self.postPaymentMode(paymentMode: .freeTrial)
    }

    func testGetsUpdatedSubscriberInfoAfterPost() {
        var dateComponent = DateComponents()
        dateComponent.month = 1
        let futureDateString = ISO8601DateFormatter()
            .string(from: Calendar.current.date(byAdding: dateComponent, to: Date())!)

        let getCustomerInfoPath: HTTPRequest.Path = .getCustomerInfo(appUserID: Self.userID)

        let validCustomerResponse: [String: Any] = [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "ORIGINAL",
                "subscriptions": [
                    "onemonth_freetrial": [
                        "expires_date": futureDateString
                    ]
                ]
            ] as [String: Any]
        ]

        let validUpdatedCustomerResponse: [String: Any] = [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "UPDATED",
                "subscriptions": [
                    "onemonth_freetrial": [
                        "expires_date": futureDateString
                    ],
                    "twomonth_awesome": [
                        "expires_date": futureDateString
                    ]
                ]
            ] as [String: Any]
        ]
        let initialCustomerInfoResponse = MockHTTPClient.Response(statusCode: .success,
                                                                  response: validCustomerResponse)
        let updatedCustomerInfoResponse = MockHTTPClient.Response(statusCode: .success,
                                                                  response: validUpdatedCustomerResponse)
        let postResponse = MockHTTPClient.Response(statusCode: .success,
                                                   response: validUpdatedCustomerResponse)

        self.httpClient.mock(requestPath: .postReceiptData, response: postResponse)
        self.httpClient.mock(requestPath: getCustomerInfoPath, response: initialCustomerInfoResponse)

        let originalSubscriberInfo: Atomic<CustomerInfo?> = nil
        let updatedSubscriberInfo: Atomic<CustomerInfo?> = nil
        let postSubscriberInfo: Atomic<CustomerInfo?> = nil

        let callOrder: Atomic<(initialGet: Bool,
                               postResponse: Bool,
                               updatedGet: Bool)> = .init((false, false, false))
        self.backend.getCustomerInfo(appUserID: Self.userID, isAppBackgrounded: false) { result in
            originalSubscriberInfo.value = result.value
            callOrder.value.initialGet = true

            self.httpClient.mocks.removeValue(forKey: getCustomerInfoPath.url!)
        }

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: false, initiationSource: .queue)
                     ),
                     observerMode: true) { result in
            self.httpClient.mock(requestPath: getCustomerInfoPath, response: updatedCustomerInfoResponse)
            callOrder.value.postResponse = true
            postSubscriberInfo.value = result.value
        }

        backend.getCustomerInfo(appUserID: Self.userID, isAppBackgrounded: false) { result in
            expect(callOrder.value) == (true, true, false)
            updatedSubscriberInfo.value = result.value
            callOrder.value.updatedGet = true
        }

        expect(callOrder.value).toEventually(equal((true, true, true)))

        expect(updatedSubscriberInfo.value).toNot(beNil())
        expect(updatedSubscriberInfo.value) == postSubscriberInfo.value
        expect(updatedSubscriberInfo.value) != originalSubscriberInfo.value

        expect(self.httpClient.calls.map { $0.request.path as? HTTPRequest.Path }) == [
            getCustomerInfoPath,
            .postReceiptData
        ]
    }

    func testPostingReceiptCreatesACustomerInfoObject() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let customerInfo = waitUntilValue { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: nil,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .purchase)
                              ),
                              observerMode: false,
                              completion: { result in
                completed(result.value)
            })
        }

        expect(customerInfo?.expirationDate(forProductIdentifier: "onemonth_freetrial")).toNot(beNil())
    }

    func testErrorIsForwardedForCustomerInfoCalls() throws {
        let error: NetworkError = .networkError(NSError(domain: NSURLErrorDomain, code: -1009))

        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(error: error)
        )

        let receivedError = waitUntilValue { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: nil,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: true, initiationSource: .queue)
                              ),
                              observerMode: false,
                              completion: { result in
                completed(result.error)
            })
        }

        expect(receivedError) == .networkError(error)
    }

    @available(iOS 11.2, *)
    func testDoesntCacheForDifferentDiscounts() {
        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let completionCalled: Atomic<Int> = .init(0)
        let isRestore = true
        let observerMode = false

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        let discount = MockStoreProductDiscount(offerIdentifier: "offerid",
                                                currencyCode: "USD",
                                                price: 12,
                                                localizedPriceString: "$12.00",
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: .init(value: 10, unit: .month),
                                                numberOfPeriods: 1,
                                                type: .promotional)
        let productData: ProductRequestData = .createMockProductData(discounts: [discount])
        backend.post(receipt: Self.receipt,
                     productData: productData,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2), timeout: defaultTimeout)
        expect(completionCalled.value).toEventually(equal(2))
    }

    @available(iOS 11.2, *)
    func testPostsReceiptDataWithDiscountInfoCorrectly() throws {
        let path: HTTPRequest.Path = .postReceiptData
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)

        self.httpClient.mock(requestPath: path, response: response)

        let productIdentifier = "a_great_product"
        let price: Decimal = 15.99
        let group = "sub_group"
        let currencyCode = "BFD"
        let paymentMode: StoreProductDiscount.PaymentMode? = nil
        let discount = MockStoreProductDiscount(offerIdentifier: "offerid",
                                                currencyCode: currencyCode,
                                                price: 12.1,
                                                localizedPriceString: "$12.10",
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: .init(value: 1, unit: .year),
                                                numberOfPeriods: 2,
                                                type: .promotional)
        let productData: ProductRequestData = .createMockProductData(productIdentifier: productIdentifier,
                                                                     paymentMode: paymentMode,
                                                                     currencyCode: currencyCode,
                                                                     price: price,
                                                                     subscriptionGroup: group,
                                                                     discounts: [discount])

        waitUntil { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: productData,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .queue)
                              ),
                              observerMode: false,
                              completion: { _ in
                completed()
            })
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testDoesntCacheForDifferentOfferings() {
        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let completionCalled: Atomic<Int> = .init(0)
        let isRestore = false
        let observerMode = true

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        backend.post(receipt: Self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: Self.userID,
                        presentedOfferingID: "offering_a",
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: isRestore, initiationSource: .queue)
                     ),
                     observerMode: observerMode,
                     completion: { _ in
            completionCalled.value += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled.value).toEventually(equal(2))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPostingReceiptWithNoProductDataAndServerErrorComputesOfflineUser() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let customerInfo = try CustomerInfo(data: Self.validCustomerResponse)

        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(error: .serverDown())
        )
        self.mockOfflineCustomerInfoCreator.stubbedCreatedResult = .success(customerInfo)

        let result = waitUntilValue { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: nil,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .purchase)
                              ),
                              observerMode: false,
                              completion: { result in
                completed(result)
            })
        }

        expect(result).to(beSuccess())
        expect(result?.value) === customerInfo

        expect(self.mockOfflineCustomerInfoCreator.createRequested) == true
        expect(self.mockOfflineCustomerInfoCreator.createRequestCount) == 1
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPostingReceiptForSubscriptionAndServerErrorComputesOfflineUser() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let customerInfo = try CustomerInfo(data: Self.validCustomerResponse)

        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(error: .serverDown())
        )
        self.mockOfflineCustomerInfoCreator.stubbedCreatedResult = .success(customerInfo)

        let result = waitUntilValue { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: .createMockProductData(),
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .purchase)
                              ),
                              observerMode: false,
                              completion: { result in
                completed(result)
            })
        }

        expect(result).to(beSuccess())
        expect(result?.value) === customerInfo

        expect(self.mockOfflineCustomerInfoCreator.createRequested) == true
        expect(self.mockOfflineCustomerInfoCreator.createRequestCount) == 1
    }

}

// swiftlint:disable:next type_name
class BackendPostReceiptWithSignatureVerificationTests: BaseBackendPostReceiptDataTests {

    override var verificationMode: Configuration.EntitlementVerificationMode { .informational }

    func testGetsEntitlementsWithVerifiedResponse() {
        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success,
                            response: Self.validCustomerResponse,
                            verificationResult: .verified)
        )

        let result = waitUntilValue { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: nil,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .purchase)
                              ),
                              observerMode: false,
                              completion: { result in
                completed(result)
            })
        }

        expect(result).to(beSuccess())

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            expect(result?.value?.entitlements.verification) == .verified
        }
    }

    func testGetsEntitlementsWithFailedVerification() {
        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success,
                            response: Self.validCustomerResponse,
                            verificationResult: .failed)
        )

        let result = waitUntilValue { completed in
            self.backend.post(receipt: Self.receipt2,
                              productData: nil,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .purchase)
                              ),
                              observerMode: false,
                              completion: { result in
                completed(result)
            })
        }

        expect(result).to(beSuccess())

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            expect(result?.value?.entitlements.verification) == .failed
        }
    }

}

// swiftlint:disable:next type_name
class BackendPostReceiptCustomEntitlementsTests: BaseBackendPostReceiptDataTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    override var dangerousSettings: DangerousSettings {
        return .init(autoSyncPurchases: true, customEntitlementComputation: true)
    }

    func testDoesNotPostConsentStatus() throws {
        let path: HTTPRequest.Path = .postReceiptData

        self.httpClient.mock(
            requestPath: path,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        waitUntil { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: nil,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .queue)
                              ),
                              observerMode: false,
                              completion: { _ in
                completed()
            })
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

}

private extension BaseBackendPostReceiptDataTests {

    static let receipt = EncodedAppleReceipt.receipt("an awesome receipt".asData)
    static let receipt2 = EncodedAppleReceipt.receipt("an awesomeer receipt".asData)

    func postPaymentMode(paymentMode: StoreProductDiscount.PaymentMode) {
        let productData: ProductRequestData = .createMockProductData(paymentMode: paymentMode)

        waitUntil { completed in
            self.backend.post(receipt: Self.receipt,
                              productData: productData,
                              transactionData: .init(
                                 appUserID: Self.userID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: nil,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .queue)
                              ),
                              observerMode: false,
                              completion: { _ in
                completed()
            })
        }
    }

}
