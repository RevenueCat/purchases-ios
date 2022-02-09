//
//  BackendTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Foundation
import Nimble
import SnapshotTesting
import XCTest

@testable import RevenueCat

class BackendTests: XCTestCase {
    struct HTTPRequest {
        let HTTPMethod: String
        let serially: Bool
        let path: String
        let body: [String: Any]?
        let headers: [String: String]
    }

    struct HTTPResponse {
        let statusCode: NSInteger
        let response: [String: Any]?
        let error: Error?
    }

    class MockHTTPClient: HTTPClient {

        var mocks: [String: HTTPResponse] = [:]
        var calls: [HTTPRequest] = []

        var shouldFinish = true

        override func performGETRequest(serially performSerially: Bool = false,
                                        path: String,
                                        headers authHeaders: [String: String],
                                        completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
            performRequest("GET",
                           performSerially: performSerially,
                           path: path,
                           requestBody: nil,
                           headers: authHeaders,
                           completionHandler: completionHandler)
        }

        override func performPOSTRequest(serially performSerially: Bool = false,
                                         path: String,
                                         requestBody: [String: Any],
                                         headers authHeaders: [String: String],
                                         completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
            performRequest("POST",
                           performSerially: performSerially,
                           path: path,
                           requestBody: requestBody,
                           headers: authHeaders,
                           completionHandler: completionHandler)
        }

        // swiftlint:disable:next function_parameter_count
        private func performRequest(_ httpMethod: String,
                                    performSerially: Bool,
                                    path: String,
                                    requestBody: [String: Any]?,
                                    headers: [String: String],
                                    completionHandler: ((Int, [String: Any]?, Error?) -> Void)?,
                                    file: StaticString = #file) {
            assert(mocks[path] != nil, "Path " + path + " not mocked")
            let response = mocks[path]!

            if let body = requestBody {
                assertSnapshot(matching: body, as: .json,
                               file: file, testName: CurrentTestCaseTracker.sanitizedTestName)
            }

            calls.append(HTTPRequest(HTTPMethod: httpMethod,
                                     serially: performSerially,
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

        func mock(requestPath: String, response: HTTPResponse) {
            mocks[requestPath] = response
        }
    }

    // swiftlint:disable:next force_try
    let systemInfo = try! SystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
    var httpClient: MockHTTPClient!
    let apiKey = "asharedsecret"
    let bundleID = "com.bundle.id"
    let userID = "user"
    let receiptData = "an awesome receipt".data(using: String.Encoding.utf8)!
    let receiptData2 = "an awesomeer receipt".data(using: String.Encoding.utf8)!

    private let noOfferingsResponse: [String: Any?] = [
        "offerings": [],
        "current_offering_id": nil
    ]

    private let oneOfferingResponse: [String: Any] = [
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
    ]

    private let validSubscriberResponse: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2017-08-30T02:40:36Z"
                ]
            ]
        ]
    ]

    private let serverErrorResponse = [
        "code": "7225",
        "message": "something is bad up in the cloud"
    ]

    var backend: Backend!

    override func setUp() {
        super.setUp()

        let eTagManager = MockETagManager(userDefaults: MockUserDefaults())
        httpClient = MockHTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        backend = Backend.init(httpClient: httpClient, apiKey: apiKey)
    }

    override class func setUp() {
        XCTestObservationCenter.shared.addTestObserver(CurrentTestCaseTracker.shared)
    }

    func testPostsReceiptDataCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = false

        let isRestore = false
        let observerMode = true

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled = true
        })

        let expectedCall = HTTPRequest(HTTPMethod: "POST",
                                       serially: true,
                                       path: "/receipts",
                                       body: ["app_user_id": userID,
                                              "fetch_token": receiptData.base64EncodedString(),
                                              "is_restore": isRestore,
                                              "observer_mode": observerMode],
                                       headers: ["Authorization": "Bearer " + apiKey])
        expect(self.httpClient.calls.count).toEventually(equal(1))
        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            expect(call.path).to(equal(expectedCall.path))
            expect(call.HTTPMethod).to(equal(expectedCall.HTTPMethod))
            XCTAssertEqual(call.body!.keys, expectedCall.body!.keys)
            expect(call.headers["Authorization"]).toNot(beNil())
            expect(call.headers["Authorization"]).to(equal(expectedCall.headers["Authorization"]))
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testCachesRequestsForSameReceipt() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = true
        let observerMode = false

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil) { (_, _) in
            completionCalled += 1
        }

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).toEventually(equal(1))
        expect(completionCalled).toEventually(equal(2))

    }

    func testDoesntCacheForDifferentRestore() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = false
        let observerMode = false

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: !isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).toEventually(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentReceipts() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = true
        let observerMode = true

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        backend.post(receiptData: receiptData2,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).toEventually(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentCurrency() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = false
        let observerMode = true

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })
        let productData: ProductRequestData = .createMockProductData(currencyCode: "USD")

        backend.post(receiptData: receiptData2,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).toEventually(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testDoesntCacheForDifferentOffering() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0

        let isRestore = true
        let observerMode = false

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: "offering_a",
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        backend.post(receiptData: receiptData2,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: "offering_b",
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).toEventually(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testCachesSubscriberGetsForSameSubscriber() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        backend.getSubscriberData(appUserID: userID) { _, _ in }
        backend.getSubscriberData(appUserID: userID) { _, _ in }

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testDoesntCacheSubscriberGetsForSameSubscriber() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)
        httpClient.mock(requestPath: "/subscribers/" + userID2, response: response)

        backend.getSubscriberData(appUserID: userID) { _, _ in }

        backend.getSubscriberData(appUserID: userID2) { _, _ in }

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testPostsReceiptDataWithProductRequestDataCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

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

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: false,
                     productData: productData,
                     presentedOfferingIdentifier: offeringIdentifier,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
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

        let expectedCall = HTTPRequest(HTTPMethod: "POST",
                                       serially: true,
                                       path: "/receipts",
                                       body: body,
                                       headers: ["Authorization": "Bearer " + apiKey])

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            expect(call.path).to(equal(expectedCall.path))
            expect(call.HTTPMethod).to(equal(expectedCall.HTTPMethod))
            expect(call.body!.keys) == expectedCall.body!.keys

            expect(call.headers["Authorization"]).toNot(beNil())
            expect(call.headers["Authorization"]).to(equal(expectedCall.headers["Authorization"]))
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testIndividualParamsCanBeNil() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = false

        let productData: ProductRequestData = .createMockProductData()
        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: false,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled = true
        })

        expect(self.httpClient.calls.count).toEventually(equal(1))
        expect(completionCalled).toEventually(beTrue())

        let call = self.httpClient.calls[0]
        expect(call.body!["price"]).toNot(beNil())
    }

    func postPaymentMode(paymentMode: StoreProductDiscount.PaymentMode) {
        var completionCalled = false

        let productData: ProductRequestData = .createMockProductData(paymentMode: paymentMode)

        backend.post(receiptData: receiptData,
                     appUserID: userID,
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

    func testForwards500ErrorsCorrectlyForCustomerInfoCalls() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: NSError?
        var underlyingError: NSError?
        backend.post(receiptData: receiptData,
                     appUserID: userID,
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
        expect(underlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testForwards400ErrorsCorrectly() {
        let response = HTTPResponse(statusCode: 400, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: Error?
        var underlyingError: Error?

        backend.post(receiptData: receiptData,
                     appUserID: userID,
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
        expect(underlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testPostingReceiptCreatesASubscriberInfoObject() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var customerInfo: CustomerInfo?

        backend.post(receiptData: receiptData,
                     appUserID: userID,
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

    func testGetSubscriberCallsBackendProperly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        backend.getSubscriberData(appUserID: userID) { _, _ in }

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            XCTAssertEqual(call.path, "/subscribers/" + userID)
            XCTAssertEqual(call.HTTPMethod, "GET")
            XCTAssertNil(call.body)
            XCTAssertNotNil(call.headers["Authorization"])
            XCTAssertEqual(call.headers["Authorization"], "Bearer " + apiKey)
        }
    }

    func testGetsSubscriberInfo() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var subscriberInfo: CustomerInfo?

        backend.getSubscriberData(appUserID: userID, completion: { (newSubscriberInfo, _) in
            subscriberInfo = newSubscriberInfo
        })

        expect(subscriberInfo).toEventuallyNot(beNil())
    }

    func testEncodesSubscriberUserID() {
        let encodeableUserID = "userid with spaces"
        let encodedUserID = "userid%20with%20spaces"
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + encodedUserID, response: response)
        httpClient.mock(requestPath: "/subscribers/" + encodeableUserID,
                        response: HTTPResponse(statusCode: 404, response: nil, error: nil))

        var subscriberInfo: CustomerInfo?

        backend.getSubscriberData(appUserID: encodeableUserID, completion: { (newSubscriberInfo, _) in
            subscriberInfo = newSubscriberInfo
        })

        expect(subscriberInfo).toEventuallyNot(beNil())
    }

    func testHandlesGetSubscriberInfoErrors() {
        let response = HTTPResponse(statusCode: 404, response: nil, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var error: NSError?

        backend.getSubscriberData(appUserID: userID, completion: { (_, newError) in
            error = newError as NSError?
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.domain).to(equal(RCPurchasesErrorCodeDomain))
        let underlyingError = (error?.userInfo[NSUnderlyingErrorKey]) as? NSError
        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError?.domain).to(equal("RevenueCat.BackendErrorCode"))
        expect(error?.userInfo["finishable"]).to(be(true))
    }

    func testHandlesInvalidJSON() {
        let response = HTTPResponse(statusCode: 200, response: ["sjkaljdklsjadkjs": ""], error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var error: NSError?

        backend.getSubscriberData(appUserID: userID, completion: { (_, newError) in
            error = newError as NSError?
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.domain).to(equal(RCPurchasesErrorCodeDomain))
        expect(error?.code).to(equal(ErrorCode.unexpectedBackendResponseError.rawValue))
    }

    func testEmptyEligibilityCheckDoesNothing() {
        backend.getIntroEligibility(appUserID: userID,
                                    receiptData: Data(),
                                    productIdentifiers: [],
                                    completion: { _, error in
            expect(error).to(beNil())
        })
        expect(self.httpClient.calls.count).to(equal(0))

    }

    func testPostsProductIdentifiers() {
        let response = HTTPResponse(statusCode: 200,
                                    response: ["producta": true, "productb": false, "productd": NSNull()],
                                    error: nil)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc", "productd"]
        backend.getIntroEligibility(appUserID: userID,
                                    receiptData: Data(1...3),
                                    productIdentifiers: products,
                                    completion: {(productEligibility, error) in
            expect(error).to(beNil())
            eligibility = productEligibility

        })

        expect(self.httpClient.calls.count).toEventually(equal(1))
        if httpClient.calls.count > 0 {
            let call = httpClient.calls[0]

            expect(path).to(equal("/subscribers/" + userID + "/intro_eligibility"))
            expect(call.HTTPMethod).to(equal("POST"))
            expect(call.headers["Authorization"]).toNot(beNil())
            expect(call.headers["Authorization"]).to(equal("Bearer " + apiKey))

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
        backend.getIntroEligibility(appUserID: userID,
                                    receiptData: Data.init(1...2),
                                    productIdentifiers: products,
                                    completion: {(productEligibility, error) in
            expect(error).to(beNil())
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productb"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productc"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
    }

    func testEligibilityUnknownIfMissingAppUserID() {
        // Set us up for a 404 because if the input sanitizing code fails, it will execute and we'd get a 404.
        let response = HTTPResponse(statusCode: 404, response: nil, error: nil)
        let path = "/subscribers//intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: IntroEligibility]?
        let products = ["producta"]
        var eventualError: NSError?
        backend.getIntroEligibility(appUserID: "",
                                    receiptData: Data.init(1...2),
                                    productIdentifiers: products,
                                    completion: {(productEligibility, error) in
            eventualError = error as NSError?
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eventualError).toEventuallyNot(beNil())
        expect(eventualError?.domain).to(equal(RCPurchasesErrorCodeDomain))
        expect(eventualError?.localizedDescription).to(equal(ErrorUtils.missingAppUserIDError().localizedDescription))

        var errorComingFromBackend = (eventualError?.userInfo[NSUnderlyingErrorKey]) as? NSError
        var wasRequestSent = errorComingFromBackend != nil
        expect(wasRequestSent) == false

        backend.getIntroEligibility(appUserID: "   ",
                                    receiptData: Data.init(1...2),
                                    productIdentifiers: products,
                                    completion: {(productEligibility, error) in
            eventualError = error as NSError?
            eligibility = productEligibility
        })

        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eventualError).toEventuallyNot(beNil())
        expect(eventualError?.domain).to(equal(RCPurchasesErrorCodeDomain))
        expect(eventualError?.localizedDescription).to(equal(ErrorUtils.missingAppUserIDError().localizedDescription))

        errorComingFromBackend = (eventualError?.userInfo[NSUnderlyingErrorKey]) as? NSError
        wasRequestSent = errorComingFromBackend != nil
        expect(wasRequestSent) == false

    }

    func testPostingWithNoSubscriberAttributesProducesAnError() {
        var eventuallyError: ErrorCode?
        backend.post(subscriberAttributes: [:], appUserID: "testUserID", completion: { error in
            eventuallyError = error as? ErrorCode
        })

        expect(eventuallyError?.codeName).toEventually(equal(ErrorCode.emptySubscriberAttributes.codeName))
    }

    func testEligibilityUnknownIfUnknownError() {
        let error = NSError(domain: "myhouse", code: 12, userInfo: nil) as Error
        let response = HTTPResponse(statusCode: 200, response: serverErrorResponse, error: error)
        let path = "/subscribers/" + userID + "/intro_eligibility"
        httpClient.mock(requestPath: path, response: response)

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend.getIntroEligibility(appUserID: userID,
                                    receiptData: Data.init(1...2),
                                    productIdentifiers: products,
                                    completion: {(productEligbility, error) in
            expect(error).to(beNil())
            eligibility = productEligbility
        })

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productb"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productc"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
    }

    func testGetOfferingsCallsHTTPMethod() {
        let response = HTTPResponse(statusCode: 200, response: noOfferingsResponse as [String: Any], error: nil)
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)

        var offeringsData: [String: Any]?

        backend.getOfferings(appUserID: userID, completion: { (responseFromBackend, _) in
            offeringsData = responseFromBackend
        })

        expect(self.httpClient.calls.count).toEventuallyNot(equal(0))
        expect(offeringsData).toEventuallyNot(beNil())
    }

    func testGetOfferingsCallsHTTPMethodSerially() {
        let response = HTTPResponse(statusCode: 200, response: noOfferingsResponse as [String: Any], error: nil)
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)

        backend.getOfferings(appUserID: userID) { _, _ in }

        expect(self.httpClient.calls.count).toEventually(equal(1))
        expect(self.httpClient.calls[0].serially).to(beTrue())
    }

    func testGetOfferingsCachesForSameUserID() {
        let response = HTTPResponse(statusCode: 200, response: noOfferingsResponse as [String: Any], error: nil)
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)
        backend.getOfferings(appUserID: userID) { (_, _) in }
        backend.getOfferings(appUserID: userID) { (_, _) in }

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testGetEntitlementsDoesntCacheForMultipleUserID() {
        let response = HTTPResponse(statusCode: 200, response: noOfferingsResponse as [String: Any], error: nil)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: "/subscribers/" + userID + "/offerings", response: response)
        httpClient.mock(requestPath: "/subscribers/" + userID2 + "/offerings", response: response)

        backend.getOfferings(appUserID: userID, completion: { (_, _) in })
        backend.getOfferings(appUserID: userID2, completion: { (_, _) in })

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testGetOfferingsOneOffering() {
        let response = HTTPResponse(statusCode: 200, response: oneOfferingResponse, error: nil)
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)
        var responseReceived: [String: Any]?
        var offerings: [[String: Any]]?
        var offeringA: [String: Any]?
        var packageA: [String: String]?
        var packageB: [String: String]?
        backend.getOfferings(appUserID: userID, completion: { (response, _) in
            offerings = response?["offerings"] as? [[String: Any]]
            offeringA = offerings?[0]
            let packages = offeringA?["packages"] as? [[String: String]]
            packageA = packages?[0]
            packageB = packages?[1]
            responseReceived = response
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

        backend.getOfferings(appUserID: userID, completion: { (newOfferings, _) in
            offerings = newOfferings
        })

        expect(offerings).toEventually(beNil())
    }

    func testPostAttributesPutsDataInDataKey() throws {
        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)
        let path = "/subscribers/" + userID + "/attribution"
        httpClient.mock(requestPath: path, response: response)

        let data: [String: AnyObject] = ["a": "b" as NSString, "c": "d" as NSString]

        backend.post(attributionData: data,
                     network: AttributionNetwork.appleSearchAds,
                     appUserID: userID,
                     completion: nil)

        expect(self.httpClient.calls.count).toEventually(equal(1))
        if self.httpClient.calls.count == 0 {
            return
        }

        let call = self.httpClient.calls[0]
        expect(call.body?.keys).to(contain("data"))
        expect(call.body?.keys).to(contain("network"))

        let postedData = try XCTUnwrap(call.body?["data"] as? [String: AnyObject])
        expect(postedData.keys).to(equal(data.keys))
    }

    func testAliasCallsBackendProperly() throws {
        var completionCalled = false

        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID + "/alias", response: response)

        backend.createAlias(appUserID: userID, newAppUserID: "new_alias", completion: { (_) in
            completionCalled = true
        })

        expect(self.httpClient.calls.count).toEventually(equal(1))

        let call = self.httpClient.calls[0]

        XCTAssertEqual(call.path, "/subscribers/" + userID + "/alias")
        XCTAssertEqual(call.HTTPMethod, "POST")
        XCTAssertNotNil(call.headers["Authorization"])
        XCTAssertEqual(call.headers["Authorization"], "Bearer " + apiKey)

        expect(call.body?.keys).to(contain("new_app_user_id"))

        let postedData = try XCTUnwrap(call.body?["new_app_user_id"] as? String)
        XCTAssertEqual(postedData, "new_alias")
        expect(completionCalled).toEventually(beTrue())
    }

    func testCreateAliasCachesForSameUserIDs() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID + "/alias", response: response)

        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in }

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testCreateAliasDoesntCacheForDifferentNewUserID() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID + "/alias", response: response)

        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in }

        backend.createAlias(appUserID: userID, newAppUserID: "another_new_alias") { _ in }

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testCreateAliasCachesWhenCallbackNil() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID + "/alias", response: response)

        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: userID, newAppUserID: "new_alias", completion: { _ in })

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testCreateAliasCallsAllCompletionBlocksInCache() {
        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID + "/alias", response: response)

        var completion1Called = false
        var completion2Called = false

        backend.createAlias(appUserID: userID, newAppUserID: "new_alias", completion: nil)
        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in
            completion1Called = true
        }
        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in
            completion2Called = true
        }

        expect(completion2Called).toEventually(beTrue())
        expect(completion1Called).toEventually(beTrue())
        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testCreateAliasDoesntCacheForDifferentCurrentUserID() {
        let newAppUserID = "new_alias"
        let currentAppUserID1 = userID
        let currentAppUserID2 = userID + "2"

        let response = HTTPResponse(statusCode: 200, response: nil, error: nil)

        httpClient.mock(requestPath: "/subscribers/" + currentAppUserID1 + "/alias", response: response)
        backend.createAlias(appUserID: currentAppUserID1, newAppUserID: newAppUserID) { _ in }

        httpClient.mock(requestPath: "/subscribers/" + currentAppUserID2 + "/alias", response: response)
        backend.createAlias(appUserID: currentAppUserID2, newAppUserID: newAppUserID) { _ in }

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testNetworkErrorIsForwardedForCustomerInfoCalls() {
        let response = HTTPResponse(statusCode: 200,
                                    response: nil,
                                    error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: "/receipts", response: response)
        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend.post(receiptData: receiptData,
                     appUserID: userID,
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

    func testNetworkErrorIsForwarded() {
        let response = HTTPResponse(statusCode: 200,
                                    response: nil,
                                    error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: "/subscribers/"+userID+"/alias", response: response)
        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend.createAlias(appUserID: userID, newAppUserID: "new", completion: { error in
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

    func testForwards500ErrorsCorrectly() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/subscribers/"+userID+"/alias", response: response)

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.createAlias(appUserID: userID, newAppUserID: "new", completion: { error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code).toEventually(be(ErrorCode.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testEligibilityUnknownIfNoReceipt() {
        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend.getIntroEligibility(appUserID: userID,
                                    receiptData: Data(),
                                    productIdentifiers: products,
                                    completion: {(productEligibility, error) in
            expect(error).to(beNil())
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility?["producta"]?.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility?["productb"]?.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility?["productc"]?.status).toEventually(equal(IntroEligibilityStatus.unknown))
    }

    func testGetOfferingsNetworkErrorSendsNilAndError() {
        let response = HTTPResponse(statusCode: 200,
                                    response: nil,
                                    error: NSError(domain: NSURLErrorDomain, code: -1009))
        let path = "/subscribers/" + userID + "/offerings"
        httpClient.mock(requestPath: path, response: response)

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend.getOfferings(appUserID: userID, completion: { (_, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(ErrorCode._nsErrorDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.networkError.rawValue))
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
        backend.getOfferings(appUserID: userID, completion: { (_, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code).toEventually(be(ErrorCode.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testGetOfferingsSkipsBackendCallIfAppUserIDIsEmpty() {
        var completionCalled = false

        backend.getOfferings(appUserID: "", completion: { (_, _) in
            completionCalled = true
        })

        expect(completionCalled).toEventually(beTrue())
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetOfferingsCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        var completionCalled = false
        var receivedError: Error?

        backend.getOfferings(appUserID: "", completion: { (_, error) in
            completionCalled = true
            receivedError = error
        })

        expect(completionCalled).toEventually(beTrue())
        expect((receivedError! as NSError).code) == ErrorCode.invalidAppUserIdError.rawValue
    }

    @available(iOS 11.2, *)
    func testDoesntCacheForDifferentDiscounts() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0
        let isRestore = true
        let observerMode = false

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        let discount = MockStoreProductDiscount(offerIdentifier: "offerid",
                                                price: 12,
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: .init(value: 10, unit: .month),
                                                type: .promotional)
        let productData: ProductRequestData = .createMockProductData(discounts: [discount])
        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).toEventually(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    @available(iOS 11.2, *)
    func testPostsReceiptDataWithDiscountInfoCorrectly() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        let productIdentifier = "a_great_product"
        let price: Decimal = 15.99
        let group = "sub_group"
        let currencyCode = "BFD"
        let paymentMode: StoreProductDiscount.PaymentMode? = nil
        var completionCalled = false
        let discount = MockStoreProductDiscount(offerIdentifier: "offerid",
                                                price: 12.1,
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: .init(value: 1, unit: .year),
                                                type: .promotional)
        let productData: ProductRequestData = .createMockProductData(productIdentifier: productIdentifier,
                                                                     paymentMode: paymentMode,
                                                                     currencyCode: currencyCode,
                                                                     price: price,
                                                                     subscriptionGroup: group,
                                                                     discounts: [discount])

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: false,
                     productData: productData,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
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
        ])

        var expectedCall: HTTPRequest
        if #available(iOS 12.2, macOS 10.14.4, *) {
            expectedCall = HTTPRequest(HTTPMethod: "POST",
                                       serially: true,
                                       path: "/receipts",
                                       body: bodyWithOffers,
                                       headers: ["Authorization": "Bearer " + apiKey])
        } else {
            expectedCall = HTTPRequest(HTTPMethod: "POST",
                                       serially: true,
                                       path: "/receipts",
                                       body: body,
                                       headers: ["Authorization": "Bearer " + apiKey])
        }

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            expect(call.path).to(equal(expectedCall.path))
            expect(call.HTTPMethod).to(equal(expectedCall.HTTPMethod))

            expect(call.headers["Authorization"]).toNot(beNil())
            expect(call.headers["Authorization"]).to(equal(expectedCall.headers["Authorization"]))

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

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: userID) { _, _, _, _, _ in
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

        let expectedCall = HTTPRequest(HTTPMethod: "POST",
                                       serially: true,
                                       path: "/offers",
                                       body: body,
                                       headers: ["Authorization": "Bearer " + apiKey])

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            expect(call.path).to(equal(expectedCall.path))
            expect(call.HTTPMethod).to(equal(expectedCall.HTTPMethod))
            XCTAssert(call.body!.keys == expectedCall.body!.keys)

            expect(call.headers["Authorization"]).toNot(beNil())
            expect(call.headers["Authorization"]).to(equal(expectedCall.headers["Authorization"]))
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testOfferForSigningNetworkError() {
        let response = HTTPResponse(statusCode: 200,
                                    response: nil,
                                    error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: "/offers", response: response)

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!
        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: userID) { _, _, _, _, error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.networkError.rawValue))
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

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: userID) { _, _, _, _, error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(
            equal(ErrorCode.unexpectedBackendResponseError.rawValue))
        expect(receivedUnderlyingError?.code).toEventually(
            equal(UnexpectedBackendResponseSubErrorCode.postOfferIdMissingOffersInResponse.rawValue))
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

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: userID) { _, _, _, _, error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(
            equal(ErrorCode.invalidAppleSubscriptionKeyError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.code).toEventually(equal(7234))
        expect(receivedUnderlyingError?.domain).toEventually(equal("RevenueCat.BackendErrorCode"))
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

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: userID) { _, _, _, _, error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(
            equal(ErrorCode.unexpectedBackendResponseError.rawValue))
        expect(receivedUnderlyingError?.code).toEventually(
            equal(UnexpectedBackendResponseSubErrorCode.postOfferIdSignature.rawValue))

    }

    func testOfferForSigning501Response() {
        let response = HTTPResponse(statusCode: 501, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: "/offers", response: response)
        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: userID) { _, _, _, _, error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code).toEventually(equal(ErrorCode.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription).to(equal(serverErrorResponse["message"]))
    }

    func testDoesntCacheForDifferentOfferings() {
        let response = HTTPResponse(statusCode: 200, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var completionCalled = 0
        let isRestore = false
        let observerMode = true

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: observerMode,
                     subscriberAttributes: nil, completion: { (_, _) in
            completionCalled += 1
        })

        backend.post(receiptData: receiptData,
                     appUserID: userID,
                     isRestore: isRestore,
                     productData: nil,
                     presentedOfferingIdentifier: "offering_a",
                     observerMode: observerMode,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCalled += 1
        })

        expect(self.httpClient.calls.count).toEventually(equal(2))
        expect(completionCalled).toEventually(equal(2))
    }

    func testLoginMakesRightCalls() {
        let newAppUserID = "new id"
        let currentAppUserID = "old id"
        let requestPath = mockLoginRequest(appUserID: currentAppUserID)
        var completionCalled = false

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _, _, _ in
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

    func testLoginPassesNetworkErrorIfCouldntCommunicate() throws {
        let newAppUserID = "new id"

        let errorCode = 123465
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [:])
        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, error: stubbedError)

        var completionCalled = false
        var receivedError: Error?
        var receivedCustomerInfo: CustomerInfo?
        var receivedCreated: Bool?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { customerInfo, created, error in
            completionCalled = true
            receivedError = error
            receivedCustomerInfo = customerInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCreated) == false
        expect(receivedCustomerInfo).to(beNil())

        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == ErrorCode.networkError.rawValue
        let expectedUserInfoError = try XCTUnwrap(receivedNSError.userInfo[NSUnderlyingErrorKey] as? NSError)
        expect(expectedUserInfoError) == stubbedError
    }

    func testLoginPassesErrors() throws {
        let newAppUserID = "new id"

        let errorCode = 123465
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: errorCode,
                                   userInfo: [:])
        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, error: stubbedError)

        var completionCalled = false
        var receivedError: Error?
        var receivedCustomerInfo: CustomerInfo?
        var receivedCreated: Bool?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { customerInfo, created, error in
            completionCalled = true
            receivedError = error
            receivedCustomerInfo = customerInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCreated) == false
        expect(receivedCustomerInfo).to(beNil())

        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == ErrorCode.networkError.rawValue
        let expectedUserInfoError = try XCTUnwrap(receivedNSError.userInfo[NSUnderlyingErrorKey] as? NSError)
        expect(expectedUserInfoError) == stubbedError
    }

    func testLoginConsidersErrorStatusCodesAsErrors() {
        let newAppUserID = "new id"
        let currentAppUserID = "old id"
        let underlyingErrorMessage = "header fields too large"
        let underlyingErrorCode = BackendErrorCode.cannotTransferPurchase.rawValue
        _ = mockLoginRequest(appUserID: currentAppUserID,
                             statusCode: 431,
                             response: ["code": underlyingErrorCode, "message": underlyingErrorMessage])

        var completionCalled = false
        var receivedError: Error?
        var receivedCustomerInfo: CustomerInfo?
        var receivedCreated: Bool?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { customerInfo, created, error in
            completionCalled = true
            receivedError = error
            receivedCustomerInfo = customerInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCreated) == false
        expect(receivedCustomerInfo).to(beNil())

        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == ErrorCode.networkError.rawValue

        // custom errors get wrapped in a backendError
        let backendUnderlyingError = receivedNSError.userInfo[NSUnderlyingErrorKey] as? NSError
        expect(backendUnderlyingError).toNot(beNil())
        let underlyingError = backendUnderlyingError?.userInfo[NSUnderlyingErrorKey] as? NSError
        expect(underlyingError?.code) == underlyingErrorCode
        expect(underlyingError?.localizedDescription) == underlyingErrorMessage
    }

    func testLoginCallsCompletionWithErrorIfCustomerInfoNil() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, statusCode: 201, response: [:])

        var completionCalled = false
        var receivedError: Error?
        var receivedCustomerInfo: CustomerInfo?
        var receivedCreated: Bool?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { customerInfo, created, error in
            completionCalled = true
            receivedError = error
            receivedCustomerInfo = customerInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCreated) == false
        expect(receivedCustomerInfo).to(beNil())

        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == ErrorCode.unexpectedBackendResponseError.rawValue
    }

    func testLoginCallsCompletionWithCustomerInfoAndCreatedFalseIf201() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, statusCode: 201, response: mockCustomerInfoDict)

        var completionCalled = false
        var receivedError: Error?
        var receivedCustomerInfo: CustomerInfo?
        var receivedCreated: Bool?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { customerInfo, created, error in
            completionCalled = true
            receivedError = error
            receivedCustomerInfo = customerInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCreated) == true
        expect(receivedCustomerInfo) == CustomerInfo(testData: mockCustomerInfoDict)
        expect(receivedError).to(beNil())
    }

    func testLoginCallsCompletionWithCustomerInfoAndCreatedFalseIf200() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID,
                             statusCode: 200,
                             response: mockCustomerInfoDict)

        var completionCalled = false
        var receivedError: Error?
        var receivedCustomerInfo: CustomerInfo?
        var receivedCreated: Bool?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { customerInfo, created, error in
            completionCalled = true
            receivedError = error
            receivedCustomerInfo = customerInfo
            receivedCreated = created
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == false
        expect(receivedCustomerInfo) == CustomerInfo(testData: mockCustomerInfoDict)
        expect(receivedError).to(beNil())
    }

    func testLoginCachesForSameUserIDs() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, statusCode: 201, response: mockCustomerInfoDict)

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _, _, _  in }
        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _, _, _  in }

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testLoginDoesntCacheForDifferentNewUserID() {
        let newAppUserID = "new id"
        let secondNewAppUserID = "new id 2"

        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, statusCode: 201, response: mockCustomerInfoDict)

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _, _, _  in }
        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: secondNewAppUserID) { _, _, _  in }

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testLoginDoesntCacheForDifferentCurrentUserID() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        let currentAppUserID2 = "old id 2"
        _ = mockLoginRequest(appUserID: currentAppUserID, statusCode: 201, response: mockCustomerInfoDict)

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _, _, _  in }
        backend.logIn(currentAppUserID: currentAppUserID2,
                      newAppUserID: newAppUserID) { _, _, _  in }

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testLoginCallsAllCompletionBlocksInCache() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, statusCode: 201, response: mockCustomerInfoDict)

        var completion1Called = false
        var completion2Called = false

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _, _, _  in
            completion1Called = true
        }
        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _, _, _  in
            completion2Called = true
        }

        expect(self.httpClient.calls.count).toEventually(equal(1))
        expect(completion1Called).toEventually(beTrue())
        expect(completion2Called).toEventually(beTrue())
    }
}

private extension BackendTests {

    func mockLoginRequest(appUserID: String,
                          statusCode: Int = 200,
                          response: [String: Any]? = [:],
                          error: Error? = nil) -> String {
        let response = HTTPResponse(statusCode: statusCode, response: response, error: error)
        let requestPath = ("/subscribers/identify")
        httpClient.mock(requestPath: requestPath, response: response)
        return requestPath
    }

    var mockCustomerInfoDict: [String: Any] { [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "subscriptions": [],
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "other_purchases": [:]
        ]
    ]}
}
