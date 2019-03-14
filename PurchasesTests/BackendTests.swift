//
//  BackendTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
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
                DispatchQueue.main.async {
                    if completionHandler != nil {
                        completionHandler!(response.statusCode, response.response, response.error)
                    }
                }
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
    let receiptData2 = "an awesomeer receipt".data(using: String.Encoding.utf8)!

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
        "code": "7225",
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

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, error) in
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


    func testCachesRequestsForSameReceipt() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).to(equal(1))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentRestore() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: !isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).to(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentReceipts() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        backend?.postReceiptData(receiptData2, appUserID: userID, isRestore: isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).to(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentCurrency() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        backend?.postReceiptData(receiptData2, appUserID: userID, isRestore: isRestore, productIdentifier: nil, price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: "USD", subscriptionGroup: nil, completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).to(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }
    
    func testCachesSubscriberGetsForSameSubscriber() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)
        
        backend?.getSubscriberData(withAppUserID: userID, completion: { (newPurchaserInfo, newError) in
        })
        
        backend?.getSubscriberData(withAppUserID: userID, completion: { (newPurchaserInfo, newError) in
        })
        
        expect(self.httpClient.calls.count).to(equal(1))
    }
    
    func testDoesntCacheSubscriberGetsForSameSubscriber() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)
        httpClient.mock(requestPath: "/subscribers/" + userID2, response: response)
        
        backend?.getSubscriberData(withAppUserID: userID, completion: { (newPurchaserInfo, newError) in
        })
        
        backend?.getSubscriberData(withAppUserID: userID2, completion: { (newPurchaserInfo, newError) in
        })
        
        expect(self.httpClient.calls.count).to(equal(2))
    }

    func testPostsReceiptDataWithProductInfoCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        let productIdentifier = "a_great_product"
        let price = 4.99 as NSDecimalNumber
        let group = "sub_group"

        let currencyCode = "BFD"

        let paymentMode = RCPaymentMode.none

        var completionCalled = false

        backend?.postReceiptData(receiptData, appUserID: userID,
                                 isRestore: false,
                                 productIdentifier: productIdentifier,
                                 price: price, paymentMode: paymentMode,
                                 introductoryPrice: nil,
                                 currencyCode: currencyCode,
                                 subscriptionGroup: group,
                                 completion: { (purchaserInfo, error) in
            completionCalled = true
        })

        let body: [String: Any] = [
            "app_user_id": userID,
            "fetch_token": receiptData.base64EncodedString(),
            "is_restore": false,
            "product_id": productIdentifier,
            "price": price,
            "currency": currencyCode,
            "subscription_group_id": group
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

    func testIndividualParamsCanBeNil() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = false

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: false, productIdentifier: "product_id", price: 9.99, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, error) in
            completionCalled = true
        })

        expect(self.httpClient.calls.count).to(equal(1))
        expect(completionCalled).toEventually(beTrue())

        let call = self.httpClient.calls[0]
        expect(call.body!["price"]).toNot(beNil())
    }

    func postPaymentMode(paymentMode: RCPaymentMode) {
        var completionCalled = false

        backend?.postReceiptData(receiptData, appUserID: userID,
                                 isRestore: false,
                                 productIdentifier: "product",
                                 price: 2.99, paymentMode: paymentMode,
                                 introductoryPrice: 1.99,
                                 currencyCode: "USD",
                                 subscriptionGroup: "group",
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

    func testForwards500ErrorsCorrectlyForPurchaserInfoCalls() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: NSError?
        var underlyingError: NSError?
        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: false, productIdentifier: nil,
                                 price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil,
                                 completion: { (purchaserInfo, newError) in
            error = newError as NSError?
            underlyingError = error?.userInfo[NSUnderlyingErrorKey] as! NSError?
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.code).toEventually(be(PurchasesErrorCode.invalidCredentialsError.rawValue))
        expect(error?.userInfo["finishable"]).to(be(false))

        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testForwards400ErrorsCorrectly() {
        let response = HTTPResponse(statusCode: 400, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: Error?
        var underlyingError: Error?

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: false, productIdentifier: nil,
                                 price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil, completion: { (purchaserInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect((error as NSError?)?.code).toEventually(be(PurchasesErrorCode.invalidCredentialsError.rawValue))
        expect((error as NSError?)?.userInfo["finishable"]).to(be(true))

        underlyingError = (error as NSError?)?.userInfo[NSUnderlyingErrorKey] as? Error
        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testPostingReceiptCreatesASubscriberInfoObject() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var purchaserInfo: PurchaserInfo?

        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: false, productIdentifier: nil,
                                 price: nil, paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil,
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

        var subscriberInfo: PurchaserInfo?

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

        var subscriberInfo: PurchaserInfo?

        backend?.getSubscriberData(withAppUserID: encodeableUserID, completion: { (newSubscriberInfo, newError) in
            subscriberInfo = newSubscriberInfo
        })

        expect(subscriberInfo).toEventuallyNot(beNil())
    }

    func testHandlesGetSubscriberInfoErrors() {
        let response = HTTPResponse(statusCode: 404, response: nil, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var error: NSError?

        backend?.getSubscriberData(withAppUserID: userID, completion: { (newSubscriberInfo, newError) in
            error = newError as NSError?
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.domain).to(equal(PurchasesErrorDomain))
        let underlyingError = (error?.userInfo[NSUnderlyingErrorKey]) as! NSError
        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError.domain).to(equal(RevenueCatBackendErrorDomain))
        expect(error?.userInfo["finishable"]).to(be(true))
    }

    func testHandlesInvalidJSON() {
        let response = HTTPResponse(statusCode: 200, response: ["sjkaljdklsjadkjs": ""], error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var error: NSError?

        backend?.getSubscriberData(withAppUserID: userID, completion: { (newSubscriberInfo, newError) in
            error = newError as NSError?
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.domain).to(equal(PurchasesErrorDomain))
        expect(error?.code).to(be(PurchasesErrorCode.unexpectedBackendResponseError.rawValue))
    }

    func testEmptyEligibilityCheckDoesNothing() {
        backend?.getIntroEligibility(forAppUserID: userID, receiptData: Data(), productIdentifiers: [], completion: { (eligibilities) in

        })
        expect(self.httpClient.calls.count).to(equal(0))
    }

    func testPostsProductIdentifiers() {
        let response = HTTPResponse(statusCode: 200, response: ["producta": true, "productb": false, "productd": NSNull()], error: nil)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: RCIntroEligibility]?

        let products = ["producta", "productb", "productc", "productd"]
        backend?.getIntroEligibility(forAppUserID: userID, receiptData: Data(1...3), productIdentifiers: products, completion: {(productEligibility) in
            eligibility = productEligibility
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
        expect(eligibility!["producta"]!.status).toEventually(equal(RCIntroEligibilityStatus.eligible))
        expect(eligibility!["productb"]!.status).toEventually(equal(RCIntroEligibilityStatus.ineligible))
        expect(eligibility!["productc"]!.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
        expect(eligibility!["productd"]!.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
    }

    func testEligibilityUnknownIfError() {
        let response = HTTPResponse(statusCode: 499, response: serverErrorResponse, error: nil)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: RCIntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend?.getIntroEligibility(forAppUserID: userID, receiptData: Data.init(1...2), productIdentifiers: products, completion: {(productEligibility) in
            eligibility = productEligibility
        })

        expect(eligibility!["producta"]!.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
        expect(eligibility!["productb"]!.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
        expect(eligibility!["productc"]!.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
    }

    func testEligibilityUnknownIfUnknownError() {
        let error = NSError(domain: "myhouse", code: 12, userInfo: nil) as Error
        let response = HTTPResponse(statusCode: 200, response: serverErrorResponse, error: error)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: RCIntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend?.getIntroEligibility(forAppUserID: userID, receiptData: Data.init(1...2), productIdentifiers: products, completion: {(productEligbility) in
            eligibility = productEligbility
        })

        expect(eligibility!["producta"]!.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
        expect(eligibility!["productb"]!.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
        expect(eligibility!["productc"]!.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
    }

    let noEntitlementsResponse = Dictionary<String, String>()

    func testGetEntitlementsCallsHTTPMethod() {
        let response = HTTPResponse(statusCode: 200, response: noEntitlementsResponse, error: nil)
        let path = "/subscribers/" + userID + "/products"
        httpClient.mock(requestPath: path, response: response)

        var entitlements: [String : Entitlement]?

        backend?.getEntitlementsForAppUserID(userID, completion: { (newEntitlements, error) in
            entitlements = newEntitlements
        })

        expect(self.httpClient.calls.count).toNot(equal(0))
        expect(entitlements).toEventuallyNot(beNil())
        expect(entitlements?.count).toEventually(equal(0))
    }
    
    func testGetEntitlementsCachesForSameUserID() {
        let response = HTTPResponse(statusCode: 200, response: noEntitlementsResponse, error: nil)
        let path = "/subscribers/" + userID + "/products"
        httpClient.mock(requestPath: path, response: response)
        
        backend?.getEntitlementsForAppUserID(userID, completion: { (newEntitlements, error) in })
        backend?.getEntitlementsForAppUserID(userID, completion: { (newEntitlements, error) in })
        
        expect(self.httpClient.calls.count).to(equal(1))
    }
    
    func testGetEntitlementsDoesntCacheForMultipleUserID() {
        let response = HTTPResponse(statusCode: 200, response: noEntitlementsResponse, error: nil)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: "/subscribers/" + userID + "/products", response: response)
        httpClient.mock(requestPath: "/subscribers/" + userID2 + "/products", response: response)
        
        backend?.getEntitlementsForAppUserID(userID, completion: { (newEntitlements, error) in })
        backend?.getEntitlementsForAppUserID(userID2, completion: { (newEntitlements, error) in })
        
        expect(self.httpClient.calls.count).to(equal(2))
    }

    let oneEntitlementResponse = [
        "entitlements" : [
            "pro" : [
                "offerings" : [
                    "monthly" : [
                        "active_product_identifier" : "monthly_freetrial"
                    ],
                    "annual" : [
                        "active_product_identifier" : "annual_freetrial"
                    ]
                ]
            ]
        ]
    ]

    func testGetEntitlementsBasicEntitlement() {
        let response = HTTPResponse(statusCode: 200, response: oneEntitlementResponse, error: nil)
        let path = "/subscribers/" + userID + "/products"
        httpClient.mock(requestPath: path, response: response)

        var entitlements: [String : Entitlement]?

        backend?.getEntitlementsForAppUserID(userID, completion: { (newEntitlements, error) in
            entitlements = newEntitlements
        })

        expect(entitlements?.count).toEventually(equal(1))
        expect(entitlements?.keys).toEventually(contain("pro"))
        expect(entitlements!["pro"]?.offerings.count).toEventually(equal(2))
        expect(entitlements!["pro"]?.offerings["monthly"]).toEventuallyNot(beNil())
        expect(entitlements!["pro"]?.offerings["annual"]).toEventuallyNot(beNil())
        expect(entitlements!["pro"]?.offerings["annual"]?.activeProduct).toEventually(beNil())
        expect(entitlements!["pro"]?.offerings["annual"]?.activeProductIdentifier).toEventually(equal("annual_freetrial"))
    }

    func testGetEntitlementsFailSendsNil() {
        let response = HTTPResponse(statusCode: 500, response: oneEntitlementResponse, error: nil)
        let path = "/subscribers/" + userID + "/products"
        httpClient.mock(requestPath: path, response: response)

        var entitlements: [String : Entitlement]?

        backend?.getEntitlementsForAppUserID(userID, completion: { (newEntitlements, error) in
            entitlements = newEntitlements
        })

        expect(entitlements).toEventually(beNil());
    }

    func testPostAttributesPutsDataInDataKey() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)
        let path = "/subscribers/" + userID + "/attribution"
        httpClient.mock(requestPath: path, response: response)

        let data = ["a" : "b", "c" : "d"];

        backend?.postAttributionData(data, from: RCAttributionNetwork.appleSearchAds, forAppUserID: userID)

        expect(self.httpClient.calls.count).to(equal(1))
        if (self.httpClient.calls.count == 0) {
            return
        }

        let call = self.httpClient.calls[0];
        expect(call.body?.keys).to(contain("data"))
        expect(call.body?.keys).to(contain("network"))

        let postedData = call.body?["data"] as! [ String : String ];
        expect(postedData.keys).to(equal(data.keys))
    }

    func testAliasCallsBackendProperly() {
        var completionCalled = false

        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID + "/alias", response: response)

        backend?.createAlias(forAppUserID: userID, withNewAppUserID: "new_alias", completion: { (error) in
            completionCalled = true
        })

        expect(self.httpClient.calls.count).to(equal(1))
    
        let call = self.httpClient.calls[0]

        XCTAssertEqual(call.path, "/subscribers/" + userID + "/alias")
        XCTAssertEqual(call.HTTPMethod, "POST")
        XCTAssertNotNil(call.headers?["Authorization"])
        XCTAssertEqual(call.headers?["Authorization"], "Basic " + apiKey)
        
        expect(call.body?.keys).to(contain("new_app_user_id"))

        let postedData = call.body?["new_app_user_id"] as! String ;
        XCTAssertEqual(postedData, "new_alias")
        expect(completionCalled).toEventually(beTrue())
    }

    func testNetworkErrorIsForwardedForPurchaserInfoCalls() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: "/receipts", response: response)
        var receivedError : NSError?
        var receivedUnderlyingError : NSError?
        backend?.postReceiptData(receiptData, appUserID: userID, isRestore: true, productIdentifier: nil, price: nil,
                paymentMode: RCPaymentMode.none, introductoryPrice: nil, currencyCode: nil, subscriptionGroup: nil,
                completion: { (purchaserInfo, error) in
                    receivedError = error as NSError?
                    receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
                })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(PurchasesErrorDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesErrorCode.networkError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.domain).toEventually(equal(NSURLErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(-1009))
    }

    func testNetworkErrorIsForwarded() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: "/subscribers/"+userID+"/alias", response: response)
        var receivedError : NSError?
        var receivedUnderlyingError : NSError?
        backend?.createAlias(forAppUserID: userID, withNewAppUserID: "new", completion: { error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(PurchasesErrorDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesErrorCode.networkError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.domain).toEventually(equal(NSURLErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(-1009))
    }

    func testForwards500ErrorsCorrectly() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/"+userID+"/alias", response: response)

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend?.createAlias(forAppUserID: userID, withNewAppUserID: "new", completion: { error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code).toEventually(be(PurchasesErrorCode.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testEligibilityUnknownIfNoReceipt() {
        var eligibility: [String: RCIntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend?.getIntroEligibility(forAppUserID: userID, receiptData: Data(), productIdentifiers: products, completion: {(productEligibility) in
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility?["producta"]?.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
        expect(eligibility?["productb"]?.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
        expect(eligibility?["productc"]?.status).toEventually(equal(RCIntroEligibilityStatus.unknown))
    }

    func testGetEntitlementsNetworkErrorSendsNilAndError() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: NSError(domain: NSURLErrorDomain, code: -1009))
        let path = "/subscribers/" + userID + "/products"
        httpClient.mock(requestPath: path, response: response)

        var receivedError : NSError?
        var receivedUnderlyingError : NSError?
        backend?.getEntitlementsForAppUserID(userID, completion: { (newEntitlements, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(PurchasesErrorDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesErrorCode.networkError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.domain).toEventually(equal(NSURLErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(-1009))
    }

    func test500GetEntitlementsUnexpectedResponse() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        let path = "/subscribers/" + userID + "/products"
        httpClient.mock(requestPath: path, response: response)

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend?.getEntitlementsForAppUserID(userID, completion: { (newEntitlements, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code).toEventually(be(PurchasesErrorCode.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

}
