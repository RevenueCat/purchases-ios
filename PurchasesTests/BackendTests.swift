//
//  BackendTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2017 Purchases. All rights reserved.
//

import Foundation
import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class BackendTests: XCTestCase {
    struct HTTPRequest {
        let HTTPMethod: String
        let path: String
        let body: [AnyHashable : Any]?
        let headers: [String: String]?
    }

    struct HTTPResponse {
        let statusCode: NSInteger
        let response: [AnyHashable : Any]?
        let error: Error?
    }

    class MockHTTPClient: RCHTTPClient {

        var mocks: [String: HTTPResponse] = [:]
        var calls: [HTTPRequest] = []

        var shouldFinish = true

        override func performRequest(_ HTTPMethod: String, path: String, body requestBody: [AnyHashable : Any]?, headers: [String : String]?, completionHandler: RCHTTPClientResponseHandler? = nil) {
            assert(mocks[path] != nil, "Path " + path + " not mocked")
            let response = mocks[path]!

            calls.append(HTTPRequest(HTTPMethod: HTTPMethod, path: path, body: requestBody, headers: headers))

            if shouldFinish {
                completionHandler!(response.statusCode, response.response, response.error)
            }
        }

        func mock(requestPath: String, response:HTTPResponse) {
            mocks[requestPath] = response
        }
    }

    let httpClient = MockHTTPClient()
    let apiKey = "asharedsecret"
    let bundleID = "com.bundle.id"
    let userID = "user"
    let receiptData = "an awesome receipt".data(using: String.Encoding.utf8)!

    let validSubscriberResponse = [
        "subscriber": [
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2017-08-30T02:40:36Z"
                ]
            ]
        ]
    ]

    let serverErrorResponse = [
        "message": "something is bad up in the cloud"
    ]

    var backend: RCBackend?

    override func setUp() {
        backend = RCBackend.init(httpClient: httpClient,
                                 apiKey: apiKey)
    }

    func testPostsReceiptDataCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = false

        let isRestore = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, completion: { (purchaserInfo, error) in
            completionCalled = true
        })

        let expectedCall = HTTPRequest(HTTPMethod: "POST", path: "/receipts", body: [
            "app_user_id": userID,
            "fetch_token": receiptData.base64EncodedString(),
            "is_restore": isRestore
            ], headers: ["Authorization": "Basic " + apiKey])

        expect(self.httpClient.calls.count).to(equal(1))
        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            expect(call.path).to(equal(expectedCall.path))
            expect(call.HTTPMethod).to(equal(expectedCall.HTTPMethod))
            XCTAssertEqual(call.body!.keys, expectedCall.body!.keys)
            expect(call.headers?["Authorization"]).toNot(beNil())
            expect(call.headers?["Authorization"]).to(equal(expectedCall.headers?["Authorization"]))
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testPostsReceiptDataWithProductInfoCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        let productIdentifier = "a_great_product"
        let price = 4.99 as NSDecimalNumber

        let currencyCode = "BFD"

        let introPrice = 2.99 as NSDecimalNumber
        let paymentMode = RCPaymentMode.none

        var completionCalled = false

        backend?.postReceiptData(receiptData, appUserID: userID,
                                 isRestore: false,
                                 productIdentifier: productIdentifier,
                                 price: price, paymentMode: paymentMode,
                                 introductoryPrice: introPrice,
                                 currencyCode: currencyCode,
                                 completion: { (purchaserInfo, error) in
            completionCalled = true
        })

        let body: [String: Any] = [
            "app_user_id": userID,
            "fetch_token": receiptData.base64EncodedString(),
            "is_restore": false,
            "product_id": productIdentifier,
            "price": price,
            "currency": currencyCode
        ]

        let expectedCall = HTTPRequest(HTTPMethod: "POST", path: "/receipts",
                                       body: body , headers: ["Authorization": "Basic " + apiKey])

        expect(self.httpClient.calls.count).to(equal(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            expect(call.path).to(equal(expectedCall.path))
            expect(call.HTTPMethod).to(equal(expectedCall.HTTPMethod))
            XCTAssert(call.body!.keys == expectedCall.body!.keys)

            expect(call.headers?["Authorization"]).toNot(beNil())
            expect(call.headers?["Authorization"]).to(equal(expectedCall.headers?["Authorization"]))
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func postPaymentMode(paymentMode: RCPaymentMode) {
        var completionCalled = false

        backend?.postReceiptData(receiptData, appUserID: userID,
                                 isRestore: false,
                                 productIdentifier: "product",
                                 price: 2.99, paymentMode: paymentMode,
                                 introductoryPrice: 1.99,
                                 currencyCode: "USD",
                                 completion: { (purchaserInfo, error) in
                                    completionCalled = true
        })

        expect(completionCalled).toEventually(beTrue())
    }

    func checkCall(expectedValue: Int) {
        let call = self.httpClient.calls.last!
        if let mode = call.body!["payment_mode"] as? Int {
            XCTAssertEqual(mode, expectedValue)
        } else {
            XCTFail("payment mode not in params")
        }
    }

    func testPayAsYouGoPostsCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        postPaymentMode(paymentMode: RCPaymentMode.payAsYouGo)
        checkCall(expectedValue: 0)
    }

    func testPayUpFrontPostsCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)
        postPaymentMode(paymentMode: RCPaymentMode.payUpFront)
        checkCall(expectedValue: 1)
    }

    func testFreeTrialPostsCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)
        postPaymentMode(paymentMode: RCPaymentMode.freeTrial)
        checkCall(expectedValue: 2)
    }

    func testForwards500ErrorsCorrectly() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: Error?

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: false, productIdentifier: nil,
                                 price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil,
                                 completion: { (purchaserInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.localizedDescription).to(equal(serverErrorResponse["message"]))
        expect((error as NSError?)?.code).to(equal(RCUnfinishableError))
    }

    func testForwards400ErrorsCorrectly() {
        let response = HTTPResponse(statusCode: 400, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: Error?

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: false, productIdentifier: nil,
                                 price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, completion: { (purchaserInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.localizedDescription).to(equal(serverErrorResponse["message"]))
        expect((error as NSError?)?.code).to(equal(RCFinishableError))
    }

    func testPostingReceiptCreatesASubscriberInfoObject() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var purchaserInfo: RCPurchaserInfo?

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: false, productIdentifier: nil,
                                 price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil,
                                 completion: { (newPurchaserInfo, newError) in
            purchaserInfo = newPurchaserInfo
        })

        expect(purchaserInfo).toEventuallyNot(beNil())
        if purchaserInfo != nil {
            let expiration = purchaserInfo!.expirationDate(forProductIdentifier: "onemonth_freetrial")
            expect(expiration).toNot(beNil())
        }
    }

    func testGetSubscriberCallsBackendProperly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        backend?.getSubscriberData(withAppUserID: userID, completion: { (newPurchaserInfo, newError) in
        })

        expect(self.httpClient.calls.count).to(equal(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            XCTAssertEqual(call.path, "/subscribers/" + userID)
            XCTAssertEqual(call.HTTPMethod, "GET")
            XCTAssertNil(call.body)
            XCTAssertNotNil(call.headers?["Authorization"])
            XCTAssertEqual(call.headers?["Authorization"], "Basic " + apiKey)
        }
    }

    func testGetsSubscriberInfo() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var subscriberInfo: RCPurchaserInfo?

        backend?.getSubscriberData(withAppUserID: userID, completion: { (newSubscriberInfo, newError) in
            subscriberInfo = newSubscriberInfo
        })

        expect(subscriberInfo).toEventuallyNot(beNil())
    }

    func testEncodesSubscriberUserID() {
        let encodeableUserID = "userid with spaces";
        let encodedUserID = "userid%20with%20spaces";
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + encodedUserID, response: response)
        httpClient.mock(requestPath: "/subscribers/" + encodeableUserID, response: HTTPResponse(statusCode: 404, response: nil, error: nil))

        var subscriberInfo: RCPurchaserInfo?

        backend?.getSubscriberData(withAppUserID: encodeableUserID, completion: { (newSubscriberInfo, newError) in
            subscriberInfo = newSubscriberInfo
        })

        expect(subscriberInfo).toEventuallyNot(beNil())
    }

    func testHandlesGetSubscriberInfoErrors() {
        let response = HTTPResponse(statusCode: 404, response: nil, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var error: Error?

        backend?.getSubscriberData(withAppUserID: userID, completion: { (newSubscriberInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect((error as NSError?)?.domain).to(equal(RCBackendErrorDomain))
        expect((error as NSError?)?.code).to(equal(RCFinishableError))
    }

    func testHandlesInvalidJSON() {
        let response = HTTPResponse(statusCode: 200, response: ["sjkaljdklsjadkjs": ""], error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var error: Error?

        backend?.getSubscriberData(withAppUserID: userID, completion: { (newSubscriberInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect((error as NSError?)?.domain).to(equal(RCBackendErrorDomain))
        expect((error as NSError?)?.code).to(equal(RCUnexpectedBackendResponse))
    }

    func testEmptyEligibiltyCheckDoesNothing() {
        backend?.getIntroElgibility(forAppUserID: userID, receiptData: Data(), productIdentifiers: [], completion: { (eligibilities) in

        })
        expect(self.httpClient.calls.count).to(equal(0))
    }

    func testPostsProductIdentifiers() {
        let response = HTTPResponse(statusCode: 200, response: ["producta": true, "productb": false], error: nil)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: RCIntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend?.getIntroElgibility(forAppUserID: userID, receiptData: Data(), productIdentifiers: products, completion: {(productEligbility) in
            eligibility = productEligbility
        })

        expect(self.httpClient.calls.count).to(equal(1))
        if httpClient.calls.count > 0 {
            let call = httpClient.calls[0]

            expect(path).to(equal("/subscribers/" + userID + "/intro_eligibility"))
            expect(call.HTTPMethod).to(equal("POST"))
            expect(call.headers!["Authorization"]).toNot(beNil())
            expect(call.headers!["Authorization"]).to(equal("Basic " + apiKey))

            expect(call.body).toNot(beNil())
            expect(call.body!["product_identifiers"] as? [String]).to(equal(products))
            expect(call.body!["fetch_token"]).toNot(beNil())
        }

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility?.keys).toEventually(contain(products))
        expect(eligibility!["producta"]!.status).toEventually(equal(RCIntroEligibityStatus.eligible))
        expect(eligibility!["productb"]!.status).toEventually(equal(RCIntroEligibityStatus.ineligible))
        expect(eligibility!["productc"]!.status).toEventually(equal(RCIntroEligibityStatus.unknown))
    }

    func testEligbilityUnknownIfError() {
        let response = HTTPResponse(statusCode: 499, response: serverErrorResponse, error: nil)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: RCIntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend?.getIntroElgibility(forAppUserID: userID, receiptData: Data(), productIdentifiers: products, completion: {(productEligbility) in
            eligibility = productEligbility
        })

        expect(eligibility!["producta"]!.status).toEventually(equal(RCIntroEligibityStatus.unknown))
        expect(eligibility!["productb"]!.status).toEventually(equal(RCIntroEligibityStatus.unknown))
        expect(eligibility!["productc"]!.status).toEventually(equal(RCIntroEligibityStatus.unknown))
    }

    func testEligbilityUnknownIfUnknownError() {
        let error = NSError(domain: "myhouse", code: 12, userInfo: nil) as Error
        let response = HTTPResponse(statusCode: 200, response: serverErrorResponse, error: error)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: RCIntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend?.getIntroElgibility(forAppUserID: userID, receiptData: Data(), productIdentifiers: products, completion: {(productEligbility) in
            eligibility = productEligbility
        })

        expect(eligibility!["producta"]!.status).toEventually(equal(RCIntroEligibityStatus.unknown))
        expect(eligibility!["productb"]!.status).toEventually(equal(RCIntroEligibityStatus.unknown))
        expect(eligibility!["productc"]!.status).toEventually(equal(RCIntroEligibityStatus.unknown))
    }
}
