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

class BackendPostReceiptDataTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        return self.createClient(#file)
    }

    func testPostsReceiptDataCorrectly() throws {
        let path: HTTPRequest.Path = .postReceiptData

        httpClient.mock(
            requestPath: path,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var completionCalled = false

        let isRestore = false
        let observerMode = true

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled = true
        })

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(completionCalled).toEventually(beTrue())
    }

    func testPostsReceiptDataWithProductDataCorrectly() throws {
        let path: HTTPRequest.Path = .postReceiptData

        httpClient.mock(
            requestPath: path,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var completionCalled = false

        let isRestore = false
        let observerMode = true
        let productData: ProductRequestData = .createMockProductData(currencyCode: "USD")

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled = true
        })

        expect(completionCalled).toEventually(beTrue())
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
                     subscriberAttributes: nil) { _ in
            completionCalled += 1
        }

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
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

        var completionCalled = false
        let productData: ProductRequestData = .createMockProductData(productIdentifier: productIdentifier,
                                                                     paymentMode: paymentMode,
                                                                     currencyCode: currencyCode,
                                                                     price: price,
                                                                     subscriptionGroup: group)

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: false,
                     productData: productData,
                     presentedOfferingIdentifier: offeringIdentifier,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled = true
        })

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(completionCalled).toEventually(beTrue())
    }

    func testIndividualParamsCanBeNil() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success,
                            response: Self.validCustomerResponse)
        )

        var completionCalled = false

        let productData: ProductRequestData = .createMockProductData()
        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: false,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled = true
        })

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(completionCalled).toEventually(beTrue())
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
            ]
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
            ]
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
            .postReceiptData,
            getCustomerInfoPath
        ]
    }

    func testPostingReceiptCreatesASubscriberInfoObject() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var customerInfo: CustomerInfo?

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { result in
            customerInfo = result.value
        })

        expect(customerInfo).toEventuallyNot(beNil())
        if customerInfo != nil {
            let expiration = customerInfo!.expirationDate(forProductIdentifier: "onemonth_freetrial")
            expect(expiration).toNot(beNil())
        }
    }

    func testErrorIsForwardedForCustomerInfoCalls() throws {
        let error: NetworkError = .networkError(NSError(domain: NSURLErrorDomain, code: -1009))

        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(error: error)
        )

        var receivedError: BackendError?
        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: true,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { result in
            receivedError = result.error
        })

        expect(receivedError).toEventuallyNot(beNil())
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
        var completionCalled = false
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

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: false,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled = true
        })

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(completionCalled).toEventually(beTrue())
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
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled += 1
        })

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(completionCalled).toEventually(equal(2))
    }

}

private extension BackendPostReceiptDataTests {

    static let receiptData = "an awesome receipt".data(using: String.Encoding.utf8)!
    static let receiptData2 = "an awesomeer receipt".data(using: String.Encoding.utf8)!

    func postPaymentMode(paymentMode: StoreProductDiscount.PaymentMode) {
        var completionCalled = false

        let productData: ProductRequestData = .createMockProductData(paymentMode: paymentMode)

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: false,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { _ in
            completionCalled = true
        })

        expect(completionCalled).toEventually(beTrue())
    }

}
