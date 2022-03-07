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
        super.createClient(#file)
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
                     completion: { (_, _) in
            completionCalled = true
        })

        expect(self.httpClient.calls).toEventually(haveCount(1))
        if self.httpClient.calls.count > 0 {
            let expectedCall = MockHTTPClient.Call(
                request: .init(method: .post([:]),
                               path: path),
                headers: HTTPClient.authorizationHeader(withAPIKey: Self.apiKey)
            )

            try self.httpClient.calls[0].expectToEqual(expectedCall)
        }

        expect(completionCalled).toEventually(beTrue())
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
                     subscriberAttributes: nil) { (_, _) in
            completionCalled += 1
        }

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
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
                     completion: { (_, _) in
            completionCalled += 1
        })

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: !isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
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
                     completion: { (_, _) in
            completionCalled += 1
        })

        backend.post(receiptData: Self.receiptData2,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
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
                     completion: { (_, _) in
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
                     completion: { (_, _) in
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
                     completion: { (_, _) in
            completionCalled += 1
        })

        backend.post(receiptData: Self.receiptData2,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: "offering_b",
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
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
                     completion: { (_, _) in
            completionCalled = true
        })

        let expectedCall = MockHTTPClient.Call(request: .init(method: .post([:]), path: .postReceiptData),
                                               headers: HTTPClient.authorizationHeader(withAPIKey: Self.apiKey))

        expect(self.httpClient.calls).toEventually(haveCount(1))

        if self.httpClient.calls.count > 0 {
            try self.httpClient.calls[0].expectToEqual(expectedCall)
        }

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
                     completion: { (_, _) in
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
        backend.getCustomerInfo(appUserID: Self.userID, completion: { (customerInfo, _) in
            originalSubscriberInfo = customerInfo
            callOrder.initialGet = true

            self.httpClient.mocks.removeValue(forKey: getCustomerInfoPath)
        })

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: true,
                     subscriberAttributes: nil,
                     completion: { (customerInfo, _) in
            self.httpClient.mock(requestPath: getCustomerInfoPath, response: updatedCustomerInfoResponse)
            callOrder.postResponse = true
            postSubscriberInfo = customerInfo
        })

        backend.getCustomerInfo(appUserID: Self.userID, completion: { (newSubscriberInfo, _) in
            expect(callOrder) == (true, true, false)
            updatedSubscriberInfo = newSubscriberInfo
            callOrder.updatedGet = true
        })

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

    func testForwards500ErrorsCorrectlyForCustomerInfoCalls() {
        let response = MockHTTPClient.Response(statusCode: .internalServerError, response: Self.serverErrorResponse)
        httpClient.mock(requestPath: .postReceiptData, response: response)

        var error: NSError?
        var underlyingError: NSError?
        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { (_, newError) in
            error = newError as NSError?
            underlyingError = error?.userInfo[NSUnderlyingErrorKey] as? NSError
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.code).toEventually(equal(ErrorCode.invalidCredentialsError.rawValue))
        expect(error?.userInfo["finishable"]).to(be(false))

        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError?.localizedDescription).to(equal(Self.serverErrorResponse["message"]))
    }

    func testForwards400ErrorsCorrectly() {
        httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .invalidRequest, response: Self.serverErrorResponse)
        )

        var error: Error?
        var underlyingError: Error?

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { (_, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect((error as NSError?)?.code).toEventually(be(ErrorCode.invalidCredentialsError.rawValue))
        expect((error as NSError?)?.userInfo["finishable"]).to(be(true))

        underlyingError = (error as NSError?)?.userInfo[NSUnderlyingErrorKey] as? Error
        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError?.localizedDescription) == Self.serverErrorResponse["message"]
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
                     completion: { (newCustomerInfo, _) in
            customerInfo = newCustomerInfo
        })

        expect(customerInfo).toEventuallyNot(beNil())
        if customerInfo != nil {
            let expiration = customerInfo!.expirationDate(forProductIdentifier: "onemonth_freetrial")
            expect(expiration).toNot(beNil())
        }
    }

    func testNetworkErrorIsForwardedForCustomerInfoCalls() {
        self.httpClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success,
                            response: nil,
                            error: NSError(domain: NSURLErrorDomain, code: -1009))
        )

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: true,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { (_, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.networkError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.domain).toEventually(equal(NSURLErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(-1009))
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
                     completion: { (_, _) in
            completionCalled += 1
        })

        let discount = MockStoreProductDiscount(offerIdentifier: "offerid",
                                                currencyCode: "USD",
                                                price: 12,
                                                localizedPriceString: "$12.00",
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: .init(value: 10, unit: .month),
                                                type: .promotional)
        let productData: ProductRequestData = .createMockProductData(discounts: [discount])
        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
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
                     completion: { (_, _) in
            completionCalled = true
        })

        let headers = HTTPClient.authorizationHeader(withAPIKey: Self.apiKey)

        let expectedCall = MockHTTPClient.Call(request: .init(method: .post([:]), path: path),
                                               headers: headers)

        expect(self.httpClient.calls).toEventually(haveCount(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]
            try call.expectToEqual(expectedCall)
        }

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
                     subscriberAttributes: nil, completion: { (_, _) in
            completionCalled += 1
        })

        backend.post(receiptData: Self.receiptData,
                     appUserID: Self.userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: "offering_a",
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
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
                     completion: { (_, _) in
            completionCalled = true
        })

        expect(completionCalled).toEventually(beTrue())
    }

}
