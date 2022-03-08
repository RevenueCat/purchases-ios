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
    struct RequestCall {
        let request: HTTPRequest
        let headers: [String: String]
    }

    struct HTTPResponse {
        let statusCode: HTTPStatusCode
        let response: [String: Any]?
        let error: Error?
        init(statusCode: HTTPStatusCode, response: [String: Any]?, error: Error? = nil) {
            self.statusCode = statusCode
            self.response = response
            self.error = error
        }
    }

    class MockHTTPClient: HTTPClient {

        var mocks: [HTTPRequest.Path: HTTPResponse] = [:]
        var calls: [RequestCall] = []

        var shouldFinish = true

        override func perform(_ request: HTTPRequest,
                              authHeaders: [String: String],
                              completionHandler: Completion?) {
            DispatchQueue.main.async {
                assert(self.mocks[request.path] != nil, "Path '\(request.path.relativePath)' not mocked")
                let response = self.mocks[request.path]!

                if let body = request.requestBody {
                    assertSnapshot(matching: body, as: .formattedJson,
                                   file: #file, testName: CurrentTestCaseTracker.sanitizedTestName)
                }

                self.calls.append(RequestCall(request: request, headers: authHeaders))

                if self.shouldFinish, let completionHandler = completionHandler {
                    completionHandler(response.statusCode, response.response, response.error)
                }
            }
        }

        func mock(requestPath: HTTPRequest.Path, response: HTTPResponse) {
            self.mocks[requestPath] = response
        }
    }

    // swiftlint:disable:next force_try
    private let systemInfo = try! SystemInfo(platformInfo: nil, finishTransactions: true)
    private var httpClient: MockHTTPClient!
    private let bundleID = "com.bundle.id"
    private let userID = "user"
    private let receiptData = "an awesome receipt".data(using: String.Encoding.utf8)!
    private let receiptData2 = "an awesomeer receipt".data(using: String.Encoding.utf8)!

    private static let apiKey = "asharedsecret"

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
        backend = Backend.init(httpClient: httpClient, apiKey: Self.apiKey)
    }

    override class func setUp() {
        XCTestObservationCenter.shared.addTestObserver(CurrentTestCaseTracker.shared)
    }

    override class func tearDown() {
        XCTestObservationCenter.shared.removeTestObserver(CurrentTestCaseTracker.shared)
    }

    func testPostsReceiptDataCorrectly() throws {
        let path: HTTPRequest.Path = .postReceiptData

        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: path, response: response)

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

        let expectedCall = RequestCall(
            request: .init(method: .post([:]),
                           path: path),
            headers: HTTPClient.authorizationHeader(withAPIKey: Self.apiKey)
        )

        expect(self.httpClient.calls.count).toEventually(equal(1))
        if self.httpClient.calls.count > 0 {
            try self.httpClient.calls[0].expectToEqual(expectedCall)
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testCachesRequestsForSameReceipt() {
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: userID), response: response)

        backend.getCustomerInfo(appUserID: userID) { _, _ in }
        backend.getCustomerInfo(appUserID: userID) { _, _ in }

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testDoesntCacheSubscriberGetsForSameSubscriber() {
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: userID), response: response)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: userID2), response: response)

        backend.getCustomerInfo(appUserID: userID) { _, _ in }
        backend.getCustomerInfo(appUserID: userID2) { _, _ in }

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testPostsReceiptDataWithProductRequestDataCorrectly() throws {
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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

        let expectedCall = RequestCall(request: .init(method: .post([:]), path: .postReceiptData),
                                       headers: HTTPClient.authorizationHeader(withAPIKey: Self.apiKey))

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if self.httpClient.calls.count > 0 {
            try self.httpClient.calls[0].expectToEqual(expectedCall)
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testIndividualParamsCanBeNil() {
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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

    func testPayAsYouGoPostsCorrectly() throws {
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)
        postPaymentMode(paymentMode: .payAsYouGo)
    }

    func testPayUpFrontPostsCorrectly() throws {
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)
        postPaymentMode(paymentMode: .payUpFront)
    }

    func testFreeTrialPostsCorrectly() throws {
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)
        postPaymentMode(paymentMode: .freeTrial)
    }

    func testForwards500ErrorsCorrectlyForCustomerInfoCalls() {
        let response = HTTPResponse(statusCode: .internalServerError, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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
        let response = HTTPResponse(statusCode: .invalidRequest, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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

    func testGetSubscriberCallsBackendProperly() throws {
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: userID)

        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: path, response: response)

        backend.getCustomerInfo(appUserID: userID) { _, _ in }

        let expectedCall = RequestCall(request: .init(method: .get, path: path),
                                       headers: HTTPClient.authorizationHeader(withAPIKey: Self.apiKey))

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            try call.expectToEqual(expectedCall)
        }
    }

    func testGetsSubscriberInfo() {
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: userID), response: response)

        var subscriberInfo: CustomerInfo?

        backend.getCustomerInfo(appUserID: userID) { (newSubscriberInfo, _) in
            subscriberInfo = newSubscriberInfo
        }

        expect(subscriberInfo).toEventuallyNot(beNil())
    }

    func testEncodesSubscriberUserID() {
        let encodeableUserID = "userid with spaces"
        let encodedUserID = "userid%20with%20spaces"
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: encodedUserID), response: response)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: encodeableUserID),
                        response: HTTPResponse(statusCode: .notFoundError, response: nil, error: nil))

        var subscriberInfo: CustomerInfo?

        backend.getCustomerInfo(appUserID: encodeableUserID) { (newSubscriberInfo, _) in
            subscriberInfo = newSubscriberInfo
        }

        expect(subscriberInfo).toEventuallyNot(beNil())
    }

    func testHandlesGetSubscriberInfoErrors() {
        let response = HTTPResponse(statusCode: .notFoundError, response: nil, error: nil)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: userID), response: response)

        var error: NSError?

        backend.getCustomerInfo(appUserID: userID) { (_, newError) in
            error = newError as NSError?
        }

        expect(error).toEventuallyNot(beNil())
        expect(error?.domain).to(equal(RCPurchasesErrorCodeDomain))
        let underlyingError = (error?.userInfo[NSUnderlyingErrorKey]) as? NSError
        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError?.domain).to(equal("RevenueCat.BackendErrorCode"))
        expect(error?.userInfo["finishable"]).to(be(true))
    }

    func testHandlesInvalidJSON() {
        let response = HTTPResponse(statusCode: .success, response: ["sjkaljdklsjadkjs": ""], error: nil)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: userID), response: response)

        var error: NSError?

        backend.getCustomerInfo(appUserID: userID) { (_, newError) in
            error = newError as NSError?
        }

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

    func testPostsProductIdentifiers() throws {
        let response = HTTPResponse(statusCode: .success,
                                    response: ["producta": true, "productb": false, "productd": NSNull()],
                                    error: nil)
        httpClient.mock(requestPath: .getIntroEligibility(appUserID: userID), response: response)

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc", "productd"]
        backend.getIntroEligibility(appUserID: userID,
                                    receiptData: Data(1...3),
                                    productIdentifiers: products,
                                    completion: {(productEligibility, error) in
            expect(error).to(beNil())
            eligibility = productEligibility

        })

        let expectedCall = RequestCall(
            request: .init(method: .post([:]), path: .getIntroEligibility(appUserID: userID)),
            headers: HTTPClient.authorizationHeader(withAPIKey: Self.apiKey)
        )

        expect(self.httpClient.calls.count).toEventually(equal(1))
        if httpClient.calls.count > 0 {
            let call = httpClient.calls[0]

            try call.expectToEqual(expectedCall)
        }

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility?.keys).toEventually(contain(products))
        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.eligible))
        expect(eligibility!["productb"]!.status).toEventually(equal(IntroEligibilityStatus.ineligible))
        expect(eligibility!["productc"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eligibility!["productd"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
    }

    func testEligibilityUnknownIfError() {
        let response = HTTPResponse(statusCode: .invalidRequest, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: .getIntroEligibility(appUserID: userID), response: response)

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
        let response = HTTPResponse(statusCode: .notFoundError, response: nil, error: nil)
        httpClient.mock(requestPath: .getIntroEligibility(appUserID: ""), response: response)

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
        let response = HTTPResponse(statusCode: .success, response: serverErrorResponse, error: error)
        httpClient.mock(requestPath: .getIntroEligibility(appUserID: userID), response: response)

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
        let response = HTTPResponse(statusCode: .success, response: noOfferingsResponse as [String: Any], error: nil)
        httpClient.mock(requestPath: .getOfferings(appUserID: userID), response: response)

        var offeringsData: [String: Any]?

        backend.getOfferings(appUserID: userID, completion: { (responseFromBackend, _) in
            offeringsData = responseFromBackend
        })

        expect(self.httpClient.calls.count).toEventuallyNot(equal(0))
        expect(offeringsData).toEventuallyNot(beNil())
    }

    func testGetOfferingsCachesForSameUserID() {
        let response = HTTPResponse(statusCode: .success, response: noOfferingsResponse as [String: Any], error: nil)
        httpClient.mock(requestPath: .getOfferings(appUserID: userID), response: response)
        backend.getOfferings(appUserID: userID) { (_, _) in }
        backend.getOfferings(appUserID: userID) { (_, _) in }

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testGetEntitlementsDoesntCacheForMultipleUserID() {
        let response = HTTPResponse(statusCode: .success, response: noOfferingsResponse as [String: Any], error: nil)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: .getOfferings(appUserID: userID), response: response)
        httpClient.mock(requestPath: .getOfferings(appUserID: userID2), response: response)

        backend.getOfferings(appUserID: userID, completion: { (_, _) in })
        backend.getOfferings(appUserID: userID2, completion: { (_, _) in })

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testGetOfferingsOneOffering() {
        let response = HTTPResponse(statusCode: .success, response: oneOfferingResponse, error: nil)
        httpClient.mock(requestPath: .getOfferings(appUserID: userID), response: response)
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
        let response = HTTPResponse(statusCode: .internalServerError, response: oneOfferingResponse, error: nil)
        httpClient.mock(requestPath: .getOfferings(appUserID: userID), response: response)

        var offerings: [String: Any]?

        backend.getOfferings(appUserID: userID, completion: { (newOfferings, _) in
            offerings = newOfferings
        })

        expect(offerings).toEventually(beNil())
    }

    func testPostAttributesPutsDataInDataKey() throws {
        let response = HTTPResponse(statusCode: .success, response: nil, error: nil)
        httpClient.mock(requestPath: .postAttributionData(appUserID: userID), response: response)

        let data: [String: AnyObject] = ["a": "b" as NSString, "c": "d" as NSString]

        backend.post(attributionData: data,
                     network: AttributionNetwork.appleSearchAds,
                     appUserID: userID,
                     completion: nil)

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testAliasCallsBackendProperly() throws {
        var completionCalled = false

        let path: HTTPRequest.Path = .createAlias(appUserID: userID)

        let response = HTTPResponse(statusCode: .success, response: nil, error: nil)
        httpClient.mock(requestPath: path, response: response)

        backend.createAlias(appUserID: userID, newAppUserID: "new_alias", completion: { (_) in
            completionCalled = true
        })

        expect(completionCalled).toEventually(beTrue())
        expect(self.httpClient.calls.count).toEventually(equal(1))

        let call = self.httpClient.calls[0]

        expect(call.request.path) == path
        expect(call.headers) == HTTPClient.authorizationHeader(withAPIKey: Self.apiKey)
    }

    func testCreateAliasCachesForSameUserIDs() {
        let response = HTTPResponse(statusCode: .success, response: nil, error: nil)
        httpClient.mock(requestPath: .createAlias(appUserID: userID), response: response)

        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in }

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testCreateAliasDoesntCacheForDifferentNewUserID() {
        let response = HTTPResponse(statusCode: .success, response: nil, error: nil)
        httpClient.mock(requestPath: .createAlias(appUserID: userID), response: response)

        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: userID, newAppUserID: "another_new_alias") { _ in }

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testCreateAliasCachesWhenCallbackNil() {
        let response = HTTPResponse(statusCode: .success, response: nil, error: nil)
        httpClient.mock(requestPath: .createAlias(appUserID: userID), response: response)

        backend.createAlias(appUserID: userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: userID, newAppUserID: "new_alias", completion: { _ in })

        expect(self.httpClient.calls.count).toEventually(equal(1))
    }

    func testCreateAliasCallsAllCompletionBlocksInCache() {
        let response = HTTPResponse(statusCode: .success, response: nil, error: nil)
        httpClient.mock(requestPath: .createAlias(appUserID: userID), response: response)

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

        let response = HTTPResponse(statusCode: .success, response: nil, error: nil)

        httpClient.mock(requestPath: .createAlias(appUserID: currentAppUserID1), response: response)
        backend.createAlias(appUserID: currentAppUserID1, newAppUserID: newAppUserID) { _ in }

        httpClient.mock(requestPath: .createAlias(appUserID: currentAppUserID2), response: response)
        backend.createAlias(appUserID: currentAppUserID2, newAppUserID: newAppUserID) { _ in }

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testNetworkErrorIsForwardedForCustomerInfoCalls() {
        let response = HTTPResponse(statusCode: .success,
                                    response: nil,
                                    error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: .postReceiptData, response: response)
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
        let response = HTTPResponse(statusCode: .success,
                                    response: nil,
                                    error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: .createAlias(appUserID: userID), response: response)
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
        let response = HTTPResponse(statusCode: .internalServerError, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: .createAlias(appUserID: userID), response: response)

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
        let response = HTTPResponse(statusCode: .success,
                                    response: nil,
                                    error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: .getOfferings(appUserID: userID), response: response)

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
        let response = HTTPResponse(statusCode: .internalServerError, response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: .getOfferings(appUserID: userID), response: response)

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
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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
                                                currencyCode: "USD",
                                                price: 12,
                                                localizedPriceString: "$12.00",
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
    func testPostsReceiptDataWithDiscountInfoCorrectly() throws {
        let path: HTTPRequest.Path = .postReceiptData

        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: path, response: response)

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

        let headers = HTTPClient.authorizationHeader(withAPIKey: Self.apiKey)

        let expectedCall: RequestCall = .init(request: .init(method: .post([:]), path: path),
                                              headers: headers)

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]
            try call.expectToEqual(expectedCall)
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testOfferForSigningCorrectly() throws {
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

        let path: HTTPRequest.Path = .postOfferForSigning
        let response = HTTPResponse(statusCode: .success, response: validSigningResponse, error: nil)
        httpClient.mock(requestPath: path, response: response)

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

        let expectedCall = RequestCall(request: .init(method: .post([:]), path: path),
                                       headers: HTTPClient.authorizationHeader(withAPIKey: Self.apiKey))

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]
            try call.expectToEqual(expectedCall)
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testOfferForSigningNetworkError() {
        let response = HTTPResponse(statusCode: .success,
                                    response: nil,
                                    error: NSError(domain: NSURLErrorDomain, code: -1009))
        httpClient.mock(requestPath: .postOfferForSigning, response: response)

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

        let response = HTTPResponse(statusCode: .success, response: validSigningResponse, error: nil)
        httpClient.mock(requestPath: .postOfferForSigning, response: response)

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

        let response = HTTPResponse(statusCode: .success, response: validSigningResponse, error: nil)
        httpClient.mock(requestPath: .postOfferForSigning, response: response)

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

        let response = HTTPResponse(statusCode: .success, response: validSigningResponse, error: nil)
        httpClient.mock(requestPath: .postOfferForSigning, response: response)

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
        let response = HTTPResponse(statusCode: .other(501), response: serverErrorResponse, error: nil)
        httpClient.mock(requestPath: .postOfferForSigning, response: response)
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
        let response = HTTPResponse(statusCode: .success, response: validSubscriberResponse, error: nil)
        httpClient.mock(requestPath: .postReceiptData, response: response)

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
        let requestPath = self.mockLoginRequest(appUserID: currentAppUserID)
        var completionCalled = false

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _, _, _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.httpClient.calls).toNot(beEmpty())
        expect(self.httpClient.calls.count) == 1

        let receivedCall = self.httpClient.calls[0]
        expect(receivedCall.request.path) == requestPath
        expect(receivedCall.request.methodType) == .post
        expect(receivedCall.headers) == HTTPClient.authorizationHeader(withAPIKey: Self.apiKey)
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
        _ = self.mockLoginRequest(appUserID: currentAppUserID, error: stubbedError)

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
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .other(431),
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
        _ = self.mockLoginRequest(appUserID: currentAppUserID, statusCode: .createdSuccess, response: [:])

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
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
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
        expect(receivedCreated) == true
        expect(receivedCustomerInfo) == CustomerInfo(testData: mockCustomerInfoDict)
        expect(receivedError).to(beNil())
    }

    func testLoginCallsCompletionWithCustomerInfoAndCreatedFalseIf200() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .success,
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
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: mockCustomerInfoDict)

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
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: mockCustomerInfoDict)

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
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: mockCustomerInfoDict)

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _, _, _  in }
        backend.logIn(currentAppUserID: currentAppUserID2,
                      newAppUserID: newAppUserID) { _, _, _  in }

        expect(self.httpClient.calls.count).toEventually(equal(2))
    }

    func testLoginCallsAllCompletionBlocksInCache() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: mockCustomerInfoDict)

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

    func testGetSubscriberInfoDoesNotMakeTwoRequests() {
        let subscriberResponse: [String: Any] = [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "user",
                "subscriptions": []
            ]
        ]
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: userID)
        let customerInfoResponse = HTTPResponse(statusCode: .success, response: subscriberResponse)
        httpClient.mock(requestPath: path, response: customerInfoResponse)

        var firstCustomerInfo: CustomerInfo?
        var secondCustomerInfo: CustomerInfo?

        backend.getCustomerInfo(appUserID: userID, completion: { (customerInfo, _) in
            firstCustomerInfo = customerInfo
        })

        backend.getCustomerInfo(appUserID: userID, completion: { (customerInfo, _) in
            secondCustomerInfo = customerInfo
        })

        expect(firstCustomerInfo).toEventuallyNot(beNil())

        expect(secondCustomerInfo) == firstCustomerInfo
        expect(self.httpClient.calls.map { $0.request.path }) == [path]
    }

    func testGetsUpdatedSubscriberInfoAfterPost() {
        var dateComponent = DateComponents()
        dateComponent.month = 1
        let futureDateString = ISO8601DateFormatter()
            .string(from: Calendar.current.date(byAdding: dateComponent, to: Date())!)

        let getCustomerInfoPath: HTTPRequest.Path = .getCustomerInfo(appUserID: self.userID)

        let validSubscriberResponse: [String: Any] = [
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

        let validUpdatedSubscriberResponse: [String: Any] = [
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
        let initialCustomerInfoResponse = HTTPResponse(statusCode: .success, response: validSubscriberResponse)
        let updatedCustomerInfoResponse = HTTPResponse(statusCode: .success, response: validUpdatedSubscriberResponse)
        let postResponse = HTTPResponse(statusCode: .success, response: validUpdatedSubscriberResponse)
        httpClient.mock(requestPath: .postReceiptData, response: postResponse)
        httpClient.mock(requestPath: getCustomerInfoPath, response: initialCustomerInfoResponse)

        var originalSubscriberInfo: CustomerInfo?
        var updatedSubscriberInfo: CustomerInfo?
        var postSubscriberInfo: CustomerInfo?

        var callOrder: (initialGet: Bool,
                        postResponse: Bool,
                        updatedGet: Bool) = (false, false, false)
        backend.getCustomerInfo(appUserID: userID, completion: { (customerInfo, _) in
            originalSubscriberInfo = customerInfo
            callOrder.initialGet = true

            self.httpClient.mocks.removeValue(forKey: getCustomerInfoPath)
        })

        backend.post(receiptData: receiptData,
                     appUserID: userID,
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

        backend.getCustomerInfo(appUserID: userID, completion: { (newSubscriberInfo, _) in
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

}

// MARK: - Extensions

private extension BackendTests {

    func mockLoginRequest(appUserID: String,
                          statusCode: HTTPStatusCode = .success,
                          response: [String: Any]? = [:],
                          error: Error? = nil) -> HTTPRequest.Path {
        let path: HTTPRequest.Path = .logIn
        let response = HTTPResponse(statusCode: statusCode, response: response, error: error)

        self.httpClient.mock(requestPath: path, response: response)

        return path
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

private extension BackendTests.RequestCall {

    // fixme: use SnapshotTesting to compare the whole `HTTPRequest` instead of only `requestBody`.
    func expectToEqual(_ other: BackendTests.RequestCall, file: FileString = #file, line: UInt = #line) throws {

        // Body comparison is done by SnapshotTesting
        if other.request.requestBody == nil {
            expect(file: file, line: line, self.request.requestBody).to(beNil())
        } else {
            expect(file: file, line: line, self.request.requestBody).toNot(beNil())
        }

        expect(file: file, line: line, self.request.path) == other.request.path
        expect(file: file, line: line, self.request.methodType) == other.request.methodType
        expect(file: file, line: line, self.headers) == other.headers
    }

}
