//
//  BackendTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Foundation
import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class BackendTests: XCTestCase {
    struct HTTPRequest {
        let HTTPMethod: String
        let serially: Bool
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

        override func performRequest(_ HTTPMethod: String,
                                     serially: Bool,
                                     path: String,
                                     body requestBody: [AnyHashable : Any]?,
                                     headers: [String : String]?,
                                     completionHandler: RCHTTPClientResponseHandler? = nil) {
            assert(mocks[path] != nil, "Path " + path + " not mocked")
            let response = mocks[path]!

            calls.append(HTTPRequest(HTTPMethod: HTTPMethod,
                                     serially: serially,
                                     path: path,
                                     body: requestBody,
                                     headers: headers))

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

    let systemInfo = try! SystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
    var httpClient: MockHTTPClient!
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
        let eTagManager = MockETagManager(userDefaults: MockUserDefaults())
        httpClient = MockHTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        backend = RCBackend.init(httpClient: httpClient,
                                 apiKey: apiKey)
    }

    func testPostsReceiptDataCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = false

        let isRestore = arc4random_uniform(2) == 0
        let observerMode = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled = true
        })

        let expectedCall = HTTPRequest(HTTPMethod: "POST", serially: true, path: "/receipts", body: [
            "app_user_id": userID,
            "fetch_token": receiptData.base64EncodedString(),
            "is_restore": isRestore,
            "observer_mode": observerMode
            ], headers: ["Authorization": "Bearer " + apiKey])

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
        let observerMode = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
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
        let observerMode = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: !isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
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
        let observerMode = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        backend?.postReceiptData(receiptData2,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
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
        let observerMode = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled += 1
        })
        let productInfo: ProductInfo = .createMockProductInfo(currencyCode: "USD")

        backend?.postReceiptData(receiptData2,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: productInfo,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).to(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentOffering() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = arc4random_uniform(2) == 0
        let observerMode = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: "offering_a", 
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        backend?.postReceiptData(receiptData2,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: "offering_b", 
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
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
        let offeringIdentifier = "a_offering"
        let price = 4.99 as NSDecimalNumber
        let group = "sub_group"

        let currencyCode = "BFD"

        let paymentMode: ProductInfo.PaymentMode = .none

        var completionCalled = false
        let productInfo: ProductInfo = .createMockProductInfo(productIdentifier: productIdentifier,
                                                                paymentMode: paymentMode,
                                                                currencyCode: currencyCode,
                                                                price: price,
                                                                subscriptionGroup: group)

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: false,
                                 productInfo: productInfo,
                                 presentedOfferingIdentifier: offeringIdentifier,
                                 observerMode: false,
                                 subscriberAttributes: nil,
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
            "subscription_group_id": group,
            "presented_offering_identifier": offeringIdentifier,
            "observer_mode": false
        ]

        let expectedCall = HTTPRequest(HTTPMethod: "POST", serially: true, path: "/receipts",
                                       body: body , headers: ["Authorization": "Bearer " + apiKey])

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

        let productInfo: ProductInfo = .createMockProductInfo()
        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: false,
                                 productInfo: productInfo,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: false,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled = true
        })

        expect(self.httpClient.calls.count).to(equal(1))
        expect(completionCalled).toEventually(beTrue())

        let call = self.httpClient.calls[0]
        expect(call.body!["price"]).toNot(beNil())
    }

    func postPaymentMode(paymentMode: ProductInfo.PaymentMode) {
        var completionCalled = false

        let productInfo: ProductInfo = .createMockProductInfo(paymentMode: paymentMode)

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: false,
                                 productInfo: productInfo,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: false,
                                 subscriberAttributes: nil,
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

        postPaymentMode(paymentMode: .payAsYouGo)
        checkCall(expectedValue: 0)
    }

    func testPayUpFrontPostsCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)
        postPaymentMode(paymentMode: .payUpFront)
        checkCall(expectedValue: 1)
    }

    func testFreeTrialPostsCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)
        postPaymentMode(paymentMode: .freeTrial)
        checkCall(expectedValue: 2)
    }

    func testForwards500ErrorsCorrectlyForPurchaserInfoCalls() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: NSError?
        var underlyingError: NSError?
        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: false,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil, observerMode:
                                 false, subscriberAttributes:
                                 nil, completion:
                                 { (purchaserInfo, newError) in
            error = newError as NSError?
            underlyingError = error?.userInfo[NSUnderlyingErrorKey] as! NSError?
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.code).toEventually(be(PurchasesCoreSwift.ErrorCodes.invalidCredentialsError.rawValue))
        expect(error?.userInfo["finishable"]).to(be(false))

        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testForwards400ErrorsCorrectly() {
        let response = HTTPResponse(statusCode: 400, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: Error?
        var underlyingError: Error?

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: false,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil, observerMode:
                                 false, subscriberAttributes:
                                 nil, completion:
                                 { (purchaserInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect((error as NSError?)?.code).toEventually(be(PurchasesCoreSwift.ErrorCodes.invalidCredentialsError.rawValue))
        expect((error as NSError?)?.userInfo["finishable"]).to(be(true))

        underlyingError = (error as NSError?)?.userInfo[NSUnderlyingErrorKey] as? Error
        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testPostingReceiptCreatesASubscriberInfoObject() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var purchaserInfo: PurchaserInfo?

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: false,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil, observerMode:
                                 false, subscriberAttributes:
                                 nil, completion:
                                 { (newPurchaserInfo, newError) in
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
            XCTAssertEqual(call.headers?["Authorization"], "Bearer " + apiKey)
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
        expect(error?.domain).to(equal(RCPurchasesErrorCodeDomain))
        let underlyingError = (error?.userInfo[NSUnderlyingErrorKey]) as! NSError
        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError.domain).to(equal(RCBackendErrorCodeDomain))
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
        expect(error?.domain).to(equal(RCPurchasesErrorCodeDomain))
        expect(error?.code).to(be(ErrorCodes.unexpectedBackendResponseError.rawValue))
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

        var eligibility: [String: IntroEligibility]?

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
            expect(call.headers!["Authorization"]).to(equal("Bearer " + apiKey))

            expect(call.body).toNot(beNil())
            expect(call.body!["product_identifiers"] as? [String]).to(equal(products))
            expect(call.body!["fetch_token"]).toNot(beNil())
        }

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility?.keys).toEventually(contain(products))
        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.eligible))
        expect(eligibility!["productb"]!.status).toEventually(equal(IntroEligibilityStatus.ineligible))
        expect(eligibility!["productc"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productd"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
    }

    func testEligibilityUnknownIfError() {
        let response = HTTPResponse(statusCode: 499, response: serverErrorResponse, error: nil)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend?.getIntroEligibility(forAppUserID: userID, receiptData: Data.init(1...2), productIdentifiers: products, completion: {(productEligibility) in
            eligibility = productEligibility
        })

        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productb"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productc"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
    }

    func testEligibilityUnknownIfUnknownError() {
        let error = NSError(domain: "myhouse", code: 12, userInfo: nil) as Error
        let response = HTTPResponse(statusCode: 200, response: serverErrorResponse, error: error)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend?.getIntroEligibility(forAppUserID: userID, receiptData: Data.init(1...2), productIdentifiers: products, completion: {(productEligbility) in
            eligibility = productEligbility
        })

        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productb"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productc"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
    }

    let noOfferingsResponse: [String: Any?] = [
        "offerings": [],
        "current_offering_id": nil
    ]
    
    func testGetOfferingsCallsHTTPMethod() {
        let response = HTTPResponse(statusCode: 200, response: noOfferingsResponse as [AnyHashable : Any], error: nil)
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)

        var offeringsData: [String : Any]?

        backend?.getOfferingsForAppUserID(userID, completion: { (responseFromBackend, error) in
            offeringsData = (responseFromBackend as! [String : Any])
        })

        expect(self.httpClient.calls.count).toNot(equal(0))
        expect(offeringsData).toEventuallyNot(beNil())
    }
    
    func testGetOfferingsCachesForSameUserID() {
        let response = HTTPResponse(statusCode: 200, response: noOfferingsResponse as [AnyHashable : Any], error: nil)
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)

        backend?.getOfferingsForAppUserID(userID, completion: { (newOfferings, error) in })
        backend?.getOfferingsForAppUserID(userID, completion: { (newOfferings, error) in })

        expect(self.httpClient.calls.count).to(equal(1))
    }

    func testGetEntitlementsDoesntCacheForMultipleUserID() {
        let response = HTTPResponse(statusCode: 200, response: noOfferingsResponse as [AnyHashable : Any], error: nil)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: "/subscribers/" + userID + "/offerings", response: response)
        httpClient.mock(requestPath: "/subscribers/" + userID2 + "/offerings", response: response)

        backend?.getOfferingsForAppUserID(userID, completion: { (newOfferings, error) in })
        backend?.getOfferingsForAppUserID(userID2, completion: { (newOfferings, error) in })

        expect(self.httpClient.calls.count).to(equal(2))
    }

    let oneOfferingResponse = [
        "offerings": [
            [
                "identifier": "offering_a",
                "description": "This is the base offering",
                "packages": [
                    [
                        "identifier": "$rc_monthly",
                        "platform_product_identifier": "monthly_freetrial"
                    ],
                    [
                        "identifier": "$rc_annual",
                        "platform_product_identifier": "annual_freetrial"
                    ]
                ]
            ]
        ],
        "current_offering_id": "offering_a"
        ] as [String : Any]

    func testGetOfferingsOneOffering() {
        let response = HTTPResponse(statusCode: 200, response: oneOfferingResponse, error: nil)
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)
        var responseReceived: [String: Any]?
        var offerings: [[String: Any]]?
        var offeringA: [String: Any]?
        var packageA: [String: String]?
        var packageB: [String: String]?
        backend?.getOfferingsForAppUserID(userID, completion: { (response, error) in
            responseReceived = response as? [String : Any]
            offerings = responseReceived?["offerings"] as? [[String : Any]]
            offeringA = offerings?[0]
            let packages = offeringA?["packages"] as? [[String: String]]
            packageA = packages?[0]
            packageB = packages?[1]
        })

        expect(offerings?.count).toEventually(equal(1))
        expect(offeringA?["identifier"] as? String).toEventually(equal("offering_a"))
        expect(offeringA?["description"] as? String).toEventually(equal("This is the base offering"))
        expect(packageA?["identifier"]).toEventually(equal("$rc_monthly"))
        expect(packageA?["platform_product_identifier"]).toEventually(equal("monthly_freetrial"))
        expect(packageB?["identifier"]).toEventually(equal("$rc_annual"))
        expect(packageB?["platform_product_identifier"]).toEventually(equal("annual_freetrial"))
        expect(responseReceived?["current_offering_id"] as? String).toEventually(equal("offering_a"))
    }

    func testGetOfferingsFailSendsNil() {
        let response = HTTPResponse(statusCode: 500, response: oneOfferingResponse, error: nil)
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)

        var offerings: [String: Any]?

        backend?.getOfferingsForAppUserID(userID, completion: { (newOfferings, error) in
            offerings = newOfferings as? [String : Any]
        })

        expect(offerings).toEventually(beNil());
    }

    func testPostAttributesPutsDataInDataKey() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)
        let path = "/subscribers/" + userID + "/attribution"
        httpClient.mock(requestPath: path, response: response)

        let data = ["a" : "b", "c" : "d"];

        backend?.postAttributionData(data, from: AttributionNetwork.appleSearchAds, forAppUserID: userID)

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
        XCTAssertEqual(call.headers?["Authorization"], "Bearer " + apiKey)
        
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
        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: true,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil, observerMode:
                                 false, subscriberAttributes:
                                 nil, completion:
                                 { (purchaserInfo, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesCoreSwift.ErrorCodes.networkError.rawValue))
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
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesCoreSwift.ErrorCodes.networkError.rawValue))
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
        expect(receivedError?.code).toEventually(be(PurchasesCoreSwift.ErrorCodes.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testEligibilityUnknownIfNoReceipt() {
        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend?.getIntroEligibility(forAppUserID: userID, receiptData: Data(), productIdentifiers: products, completion: {(productEligibility) in
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility?["producta"]?.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility?["productb"]?.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility?["productc"]?.status).toEventually(equal(IntroEligibilityStatus.unknown))
    }

    func testGetOfferingsNetworkErrorSendsNilAndError() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: NSError(domain: NSURLErrorDomain, code: -1009))
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)

        var receivedError : NSError?
        var receivedUnderlyingError : NSError?
        backend?.getOfferingsForAppUserID(userID, completion: { (offeringsData, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(ErrorCodes._nsErrorDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesCoreSwift.ErrorCodes.networkError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.domain).toEventually(equal(NSURLErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(-1009))
    }

    func test500GetOfferingsUnexpectedResponse() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend?.getOfferingsForAppUserID(userID, completion: { (offeringsData, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code).toEventually(be(PurchasesCoreSwift.ErrorCodes.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testGetOfferingsSkipsBackendCallIfAppUserIDIsEmpty() {
        var completionCalled = false

        backend?.getOfferingsForAppUserID("", completion: { (offerings, error) in
            completionCalled = true
        })

        expect(completionCalled).toEventually(beTrue())
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetOfferingsCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        var completionCalled = false
        var receivedError: Error? = nil

        backend?.getOfferingsForAppUserID("", completion: { (offerings, error) in
            completionCalled = true
            receivedError = error
        })

        expect(completionCalled).toEventually(beTrue())
        expect((receivedError! as NSError).code) == PurchasesCoreSwift.ErrorCodes.invalidAppUserIdError.rawValue
    }

    @available(iOS 11.2, *)
    func testDoesntCacheForDifferentDiscounts() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)
        
        var completionCalled = 0
        
        let isRestore = arc4random_uniform(2) == 0
        let observerMode = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil, observerMode:
                                 observerMode, subscriberAttributes:
                                 nil, completion:
                                 { (purchaserInfo, error) in
            completionCalled += 1
        })

        let discount = PromotionalOffer(offerIdentifier: "offerid", price: 12, paymentMode: .payAsYouGo)
        let productInfo: ProductInfo = .createMockProductInfo(discounts: [discount])
        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: productInfo,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).to(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    @available(iOS 11.2, *)
    func testPostsReceiptDataWithDiscountInfoCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)
        
        let productIdentifier = "a_great_product"
        let price = 4.99 as NSDecimalNumber
        let group = "sub_group"
        
        let currencyCode = "BFD"
        
        let paymentMode: ProductInfo.PaymentMode = .none
        
        var completionCalled = false

        let discount = PromotionalOffer(offerIdentifier: "offerid", price: 12, paymentMode: .payAsYouGo)

        let productInfo: ProductInfo = .createMockProductInfo(productIdentifier: productIdentifier,
                                                                paymentMode: paymentMode,
                                                                currencyCode: currencyCode,
                                                                price: price,
                                                                subscriptionGroup: group,
                                                                discounts: [discount])

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: false,
                                 productInfo: productInfo,
                                 presentedOfferingIdentifier: nil,
                                 observerMode: false,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled = true
        })

        let body: [String: Any] = [
            "app_user_id": userID,
            "fetch_token": receiptData.base64EncodedString(),
            "is_restore": false,
            "observer_mode": false,
            "product_id": productIdentifier,
            "price": price,
            "currency": currencyCode,
            "subscription_group_id": group
        ]
        let bodyWithOffers = body.merging([
            "offers": [
                "offer_identifier": "offerid",
                "price": 12,
                "payment_mode": 0
            ]
        ]) { _, new in new }

        var expectedCall: HTTPRequest
        if #available(iOS 12.2, macOS 10.14.4, *) {
            expectedCall = HTTPRequest(HTTPMethod: "POST", serially: true, path: "/receipts",
                                       body: bodyWithOffers , headers: ["Authorization": "Bearer " + apiKey])
        } else {
            expectedCall = HTTPRequest(HTTPMethod: "POST", serially: true, path: "/receipts",
                                       body: body , headers: ["Authorization": "Bearer " + apiKey])
        }
        
        expect(self.httpClient.calls.count).to(equal(1))
        
        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]
            
            expect(call.path).to(equal(expectedCall.path))
            expect(call.HTTPMethod).to(equal(expectedCall.HTTPMethod))

            expect(call.headers?["Authorization"]).toNot(beNil())
            expect(call.headers?["Authorization"]).to(equal(expectedCall.headers?["Authorization"]))

            expect(call.body!.keys) == expectedCall.body!.keys
        }
        
        expect(completionCalled).toEventually(beTrue())
    }
    
    func testOfferForSigningCorrectly() {
        let validSigningResponse: [String: Any] = [
            "offers": [
                [
                    "offer_id": "PROMO_ID",
                    "product_id": "com.myapp.product_a",
                    "key_id": "STEAKANDEGGS",
                    "signature_data": [
                        "signature": "Base64 encoded signature",
                        "nonce": "A UUID",
                        "timestamp": Int64(123413232131)
                    ],
                    "signature_error": nil
                ]
            ]
        ]

        let response = HTTPResponse(statusCode: 200, response: validSigningResponse, error: nil)
        httpClient.mock(requestPath: "/offers", response: response)

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        var completionCalled = false
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        backend?.postOffer(
                forSigning: offerIdentifier,
                withProductIdentifier: productIdentifier,
                subscriptionGroup: group,
                receiptData: discountData,
                appUserID: userID) { signature, keyIdentifier, nonce, timestamp, error in
                    completionCalled = true
                }

        let body: [String: Any] = [
            "app_user_id": userID,
            "fetch_token": discountData.base64EncodedString(),
            "generate_offers": [
                "offer_id": offerIdentifier,
                "product_id": productIdentifier,
                "subscription_group": group
            ]
        ]

        let expectedCall = HTTPRequest(HTTPMethod: "POST", serially: true, path: "/offers",
                body: body, headers: ["Authorization": "Bearer " + apiKey])

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
    
    func testOfferForSigningNetworkError() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: "/offers", response: response)

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!
        var receivedError : NSError?
        var receivedUnderlyingError : NSError?
        
        backend?.postOffer(
                forSigning: offerIdentifier,
                withProductIdentifier: productIdentifier,
                subscriptionGroup: group,
                receiptData: discountData,
                appUserID: userID) { _, _, _, _, error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesCoreSwift.ErrorCodes.networkError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.domain).toEventually(equal(NSURLErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(-1009))
    }

    func testOfferForSigningEmptyOffersResponse() {
        let validSigningResponse: [String: Any] = [
            "offers": []
        ]

        let response = HTTPResponse(statusCode: 200, response: validSigningResponse, error: nil)
        httpClient.mock(requestPath: "/offers", response: response)

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        var receivedError : NSError?
        var receivedUnderlyingError : NSError?

        backend?.postOffer(
                forSigning: offerIdentifier,
                withProductIdentifier: productIdentifier,
                subscriptionGroup: group,
                receiptData: discountData,
                appUserID: userID) { signature, keyIdentifier, nonce, timestamp, error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesCoreSwift.ErrorCodes.unexpectedBackendResponseError.rawValue))
        expect(receivedUnderlyingError).toEventually(beNil())
    }
    
    func testOfferForSigningSignatureErrorResponse() {
        let validSigningResponse: [String: Any] = [
            "offers": [
                [
                    "offer_id": "PROMO_ID",
                    "product_id": "com.myapp.product_a",
                    "key_id": "STEAKANDEGGS",
                    "signature_data": nil,
                    "signature_error": [
                        "message": "Ineligible for some reason",
                        "code": 7234
                    ]
                ]
            ]
        ]

        let response = HTTPResponse(statusCode: 200, response: validSigningResponse, error: nil)
        httpClient.mock(requestPath: "/offers", response: response)
        
        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!
        
        var receivedError : NSError?
        var receivedUnderlyingError : NSError?
        
        backend?.postOffer(
            forSigning: offerIdentifier,
            withProductIdentifier: productIdentifier,
            subscriptionGroup: group,
            receiptData: discountData,
            appUserID: userID) { signature, keyIdentifier, nonce, timestamp, error in
                receivedError = error as NSError?
                receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        }
        
        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesCoreSwift.ErrorCodes.invalidAppleSubscriptionKeyError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.code).toEventually(equal(7234))
        expect(receivedUnderlyingError?.domain).toEventually(equal(RCBackendErrorCodeDomain))
        expect(receivedUnderlyingError?.localizedDescription).toEventually(equal("Ineligible for some reason"))
    }
    
    func testOfferForSigningNoDataAndNoSignatureErrorResponse() {
        let validSigningResponse: [String: Any] = [
            "offers": [
                [
                    "offer_id": "PROMO_ID",
                    "product_id": "com.myapp.product_a",
                    "key_id": "STEAKANDEGGS",
                    "signature_data": nil,
                    "signature_error": nil
                ]
            ]
        ]

        let response = HTTPResponse(statusCode: 200, response: validSigningResponse, error: nil)
        httpClient.mock(requestPath: "/offers", response: response)

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        var receivedError : NSError?
        var receivedUnderlyingError : NSError?

        backend?.postOffer(
                forSigning: offerIdentifier,
                withProductIdentifier: productIdentifier,
                subscriptionGroup: group,
                receiptData: discountData,
                appUserID: userID) { signature, keyIdentifier, nonce, timestamp, error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesCoreSwift.ErrorCodes.unexpectedBackendResponseError.rawValue))
        expect(receivedUnderlyingError).toEventually(beNil())

    }

    func testOfferForSigning501Response() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/offers", response: response)
        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        var receivedError : NSError?
        var receivedUnderlyingError : NSError?
        backend?.postOffer(
                forSigning: offerIdentifier,
                withProductIdentifier: productIdentifier,
                subscriptionGroup: group,
                receiptData: discountData,
                appUserID: userID) { signature, keyIdentifier, nonce, timestamp, error in
                    receivedError = error as NSError?
                    receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code).toEventually(be(PurchasesCoreSwift.ErrorCodes.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }
    
    func testDoesntCacheForDifferentOfferings() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)
        
        var completionCalled = 0
        
        let isRestore = arc4random_uniform(2) == 0
        let observerMode = arc4random_uniform(2) == 0

        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: nil, observerMode:
                                 observerMode, subscriberAttributes:
                                 nil, completion:
                                 { (purchaserInfo, error) in
            completionCalled += 1
        })

        _ = PromotionalOffer(offerIdentifier: "offerid", price: 12, paymentMode: .payAsYouGo)
        
        backend?.postReceiptData(receiptData,
                                 appUserID: userID,
                                 isRestore: isRestore,
                                 productInfo: nil,
                                 presentedOfferingIdentifier: "offering_a",
                                 observerMode: observerMode,
                                 subscriberAttributes: nil,
                                 completion: { (purchaserInfo, error) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).to(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testLoginMakesRightCalls() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        let requestPath = mockLoginRequest(appUserID: currentAppUserID)

        var completionCalled = false

        backend?.logIn(withCurrentAppUserID: currentAppUserID,
                       newAppUserID: newAppUserID) { (purchaserInfo: PurchaserInfo?,
                                                      created: Bool,
                                                      error: Error?) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.httpClient.calls).toNot(beEmpty())
        expect(self.httpClient.calls.count) == 1

        let receivedCall = self.httpClient.calls[0]
        expect(receivedCall.path) == requestPath
        expect(receivedCall.serially) == true
        expect(receivedCall.HTTPMethod) == "POST"
        expect(receivedCall.body as? [String: String]) == ["new_app_user_id": newAppUserID,
                                                           "app_user_id": currentAppUserID]
        expect(receivedCall.headers) == ["Authorization": "Bearer asharedsecret"]
    }

    func testLoginPassesNetworkErrorIfCouldntCommunicate() {
        let newAppUserID = "new id"

        let errorCode = 123465
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: errorCode,
                                   userInfo: [:])
        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, error: stubbedError)

        var completionCalled = false
        var receivedError: Error?
        var receivedPurchaserInfo: PurchaserInfo?
        var receivedCreated: Bool?

        backend?.logIn(withCurrentAppUserID: currentAppUserID,
                       newAppUserID: newAppUserID) { (purchaserInfo: PurchaserInfo?,
                                                      created: Bool,
                                                      error: Error?) in
            completionCalled = true
            receivedError = error
            receivedPurchaserInfo = purchaserInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCreated) == false
        expect(receivedPurchaserInfo).to(beNil())

        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == PurchasesCoreSwift.ErrorCodes.networkError.rawValue
        expect((receivedNSError.userInfo[NSUnderlyingErrorKey] as! NSError)) == stubbedError
    }

    func testLoginPassesErrors() {
        let newAppUserID = "new id"

        let errorCode = 123465
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: errorCode,
                                   userInfo: [:])
        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, error: stubbedError)

        var completionCalled = false
        var receivedError: Error?
        var receivedPurchaserInfo: PurchaserInfo?
        var receivedCreated: Bool?

        backend?.logIn(withCurrentAppUserID: currentAppUserID,
                       newAppUserID: newAppUserID) { (purchaserInfo: PurchaserInfo?,
                                                      created: Bool,
                                                      error: Error?) in
            completionCalled = true
            receivedError = error
            receivedPurchaserInfo = purchaserInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCreated) == false
        expect(receivedPurchaserInfo).to(beNil())

        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == PurchasesCoreSwift.ErrorCodes.networkError.rawValue
        expect((receivedNSError.userInfo[NSUnderlyingErrorKey] as! NSError)) == stubbedError
    }

    func testLoginConsidersErrorStatusCodesAsErrors() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        let underlyingErrorMessage = "header fields too large"
        let underlyingErrorCode = "123456"
        _ = mockLoginRequest(appUserID: currentAppUserID,
                             statusCode: 431,
                             response: ["code": underlyingErrorCode, "message": underlyingErrorMessage])

        var completionCalled = false
        var receivedError: Error?
        var receivedPurchaserInfo: PurchaserInfo?
        var receivedCreated: Bool?

        backend?.logIn(withCurrentAppUserID: currentAppUserID,
                       newAppUserID: newAppUserID) { (purchaserInfo: PurchaserInfo?,
                                                      created: Bool,
                                                      error: Error?) in
            completionCalled = true
            receivedError = error
            receivedPurchaserInfo = purchaserInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCreated) == false
        expect(receivedPurchaserInfo).to(beNil())

        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == PurchasesCoreSwift.ErrorCodes.networkError.rawValue

        // custom errors get wrapped in a backendError
        let backendUnderlyingError = receivedNSError.userInfo[NSUnderlyingErrorKey] as? NSError
        expect(backendUnderlyingError).toNot(beNil())
        let underlyingError = backendUnderlyingError?.userInfo[NSUnderlyingErrorKey] as? NSError
        expect(underlyingError?.code) == Int(underlyingErrorCode)
        expect(underlyingError?.localizedDescription) == underlyingErrorMessage
    }

    func testLoginCallsCompletionWithErrorIfPurchaserInfoNil() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, statusCode: 201, response: [:])

        var completionCalled = false
        var receivedError: Error?
        var receivedPurchaserInfo: PurchaserInfo?
        var receivedCreated: Bool?

        backend?.logIn(withCurrentAppUserID: currentAppUserID,
                       newAppUserID: newAppUserID) { (purchaserInfo: PurchaserInfo?,
                                                      created: Bool,
                                                      error: Error?) in
            completionCalled = true
            receivedError = error
            receivedPurchaserInfo = purchaserInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCreated) == false
        expect(receivedPurchaserInfo).to(beNil())

        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == PurchasesCoreSwift.ErrorCodes.unexpectedBackendResponseError.rawValue
    }

    func testLoginCallsCompletionWithPurchaserInfoAndCreatedFalseIf201() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        let _ = mockLoginRequest(appUserID: currentAppUserID,
                                 statusCode: 201,
                                 response: mockPurchaserInfoDict)

        var completionCalled = false
        var receivedError: Error?
        var receivedPurchaserInfo: PurchaserInfo?
        var receivedCreated: Bool?

        backend?.logIn(withCurrentAppUserID: currentAppUserID,
                       newAppUserID: newAppUserID) { (purchaserInfo: PurchaserInfo?,
                                                      created: Bool,
                                                      error: Error?) in
            completionCalled = true
            receivedError = error
            receivedPurchaserInfo = purchaserInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == true
        expect(receivedPurchaserInfo) == PurchaserInfo(data: mockPurchaserInfoDict)
        expect(receivedError).to(beNil())
    }

    func testLoginCallsCompletionWithPurchaserInfoAndCreatedFalseIf200() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        let _ = mockLoginRequest(appUserID: currentAppUserID,
                                 statusCode: 200,
                                 response: mockPurchaserInfoDict)

        var completionCalled = false
        var receivedError: Error?
        var receivedPurchaserInfo: PurchaserInfo?
        var receivedCreated: Bool?

        backend?.logIn(withCurrentAppUserID: currentAppUserID,
                       newAppUserID: newAppUserID) { (purchaserInfo: PurchaserInfo?,
                                                      created: Bool,
                                                      error: Error?) in
            completionCalled = true
            receivedError = error
            receivedPurchaserInfo = purchaserInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == false
        expect(receivedPurchaserInfo) == PurchaserInfo(data: mockPurchaserInfoDict)
        expect(receivedError).to(beNil())
    }
}

private extension BackendTests {

    func mockLoginRequest(appUserID: String,
                          statusCode: Int = 200,
                          response: [AnyHashable: Any]? = [:],
                          error: Error? = nil) -> String {
        let response = HTTPResponse(statusCode: statusCode, response: response, error: error)
        let requestPath = ("/subscribers/identify")
        httpClient.mock(requestPath: requestPath, response: response)
        return requestPath
    }

    var mockPurchaserInfoDict: [String: Any] { [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": NSNull()
            ]
        ]
    }
}
