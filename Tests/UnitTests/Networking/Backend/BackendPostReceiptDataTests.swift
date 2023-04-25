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
            self.backend.post(receiptData: Self.receiptData,
                              appUserID: Self.userID,
                              isRestore: isRestore,
                              productData: nil,
                              presentedOfferingIdentifier: nil,
                              observerMode: observerMode,
                              initiationSource: .queue,
                              subscriberAttributes: nil,
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
            self.backend.post(receiptData: Self.receiptData,
                              appUserID: Self.userID,
                              isRestore: isRestore,
                              productData: productData,
                              presentedOfferingIdentifier: nil,
                              observerMode: observerMode,
                              initiationSource: .purchase,
                              subscriberAttributes: nil,
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

        var completionCalled = 0

        let isRestore = true
        let observerMode = false

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .purchase,
                     subscriberAttributes: nil) { _ in
            completionCalled += 1
        }

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(completionCalled).toEventually(equal(2))
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testDoesntCacheForDifferentRestore() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var completionCalled = 0

        let isRestore = false
        let observerMode = false

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .purchase,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: !isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentReceipts() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var completionCalled = 0

        let isRestore = true
        let observerMode = true

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        backend.post(receiptData: Self.receiptData2,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentCurrency() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var completionCalled = 0

        let isRestore = false
        let observerMode = true

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .purchase,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })
        let productData: ProductRequestData = .createMockProductData(currencyCode: "USD")

        backend.post(receiptData: Self.receiptData2,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .purchase,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentOffering() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var completionCalled = 0

        let isRestore = true
        let observerMode = false

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: "offering_a",
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        backend.post(receiptData: Self.receiptData2,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: "offering_b",
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled).toEventually(equal(2))
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
            self.backend.post(receiptData: Self.receiptData,
                              appUserID: Self.userID,
                              isRestore: false,
                              productData: productData,
                              presentedOfferingIdentifier: offeringIdentifier,
                              observerMode: false,
                              initiationSource: .purchase,
                              subscriberAttributes: nil,
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
            self.backend.post(receiptData: Self.receiptData,
                              appUserID: Self.userID,
                              isRestore: false,
                              productData: productData,
                              presentedOfferingIdentifier: nil,
                              observerMode: false,
                              initiationSource: .queue,
                              subscriberAttributes: nil,
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

        var originalSubscriberInfo: CustomerInfo?
        var updatedSubscriberInfo: CustomerInfo?
        var postSubscriberInfo: CustomerInfo?

        var callOrder: (initialGet: Bool,
                        postResponse: Bool,
                        updatedGet: Bool) = (false, false, false)
        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) { result in
            originalSubscriberInfo = result.value
            callOrder.initialGet = true

            self.httpClient.mocks.removeValue(forKey: getCustomerInfoPath)
        }

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: true,
                     initiationSource: .queue,
                     subscriberAttributes: nil) { result in
            self.httpClient.mock(requestPath: getCustomerInfoPath, response: updatedCustomerInfoResponse)
            callOrder.postResponse = true
            postSubscriberInfo = result.value
        }

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) { result in
            expect(callOrder) == (true, true, false)
            updatedSubscriberInfo = result.value
            callOrder.updatedGet = true
        }

        expect(callOrder).toEventually(equal((true, true, true)))

        expect(updatedSubscriberInfo).toNot(beNil())
        expect(updatedSubscriberInfo).to(equal(postSubscriberInfo))
        expect(updatedSubscriberInfo).toNot(equal(originalSubscriberInfo))

        expect(self.httpClient.calls.map { $0.request.path }) == [
            getCustomerInfoPath,
            .postReceiptData
        ]
    }

    func testPostingReceiptCreatesASubscriberInfoObject() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let customerInfo = waitUntilValue { completed in
            self.backend.post(receiptData: Self.receiptData,
                              appUserID: Self.userID,
                              isRestore: false,
                              productData: nil,
                              presentedOfferingIdentifier: nil,
                              observerMode: false,
                              initiationSource: .purchase,
                              subscriberAttributes: nil,
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
            self.backend.post(receiptData: Self.receiptData,
                              appUserID: Self.userID,
                              isRestore: true,
                              productData: nil,
                              presentedOfferingIdentifier: nil,
                              observerMode: false,
                              initiationSource: .queue,
                              subscriberAttributes: nil,
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

        var completionCalled = 0
        let isRestore = true
        let observerMode = false

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
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
        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled).toEventually(equal(2))
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
            self.backend.post(receiptData: Self.receiptData,
                              appUserID: Self.userID,
                              isRestore: false,
                              productData: productData,
                              presentedOfferingIdentifier: nil,
                              observerMode: false,
                              initiationSource: .queue,
                              subscriberAttributes: nil,
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

        var completionCalled = 0
        let isRestore = false
        let observerMode = true

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: "offering_a",
                     observerMode: observerMode,
                     initiationSource: .queue,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled).toEventually(equal(2))
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
            self.backend.post(receiptData: Self.receiptData,
                              appUserID: Self.userID,
                              isRestore: false,
                              productData: nil,
                              presentedOfferingIdentifier: nil,
                              observerMode: false,
                              initiationSource: .queue,
                              subscriberAttributes: nil,
                              completion: { _ in
                completed()
            })
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

}

private extension BaseBackendPostReceiptDataTests {

    static let receiptData = "an awesome receipt".data(using: String.Encoding.utf8)!
    static let receiptData2 = "an awesomeer receipt".data(using: String.Encoding.utf8)!

    func postPaymentMode(paymentMode: StoreProductDiscount.PaymentMode) {
        let productData: ProductRequestData = .createMockProductData(paymentMode: paymentMode)

        waitUntil { completed in
            self.backend.post(receiptData: Self.receiptData,
                              appUserID: Self.userID,
                              isRestore: false,
                              productData: productData,
                              presentedOfferingIdentifier: nil,
                              observerMode: false,
                              initiationSource: .queue,
                              subscriberAttributes: nil,
                              completion: { _ in
                completed()
            })
        }
    }

}
