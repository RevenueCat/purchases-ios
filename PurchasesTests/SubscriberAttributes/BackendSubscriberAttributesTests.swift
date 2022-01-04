//
// Created by RevenueCat on 2/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class BackendSubscriberAttributesTests: XCTestCase {

    let appUserID = "abc123"
    let now = Date()
    let receiptData = "an awesome receipt".data(using: String.Encoding.utf8)!

    var dateProvider: MockDateProvider!
    var subscriberAttribute1: SubscriberAttribute!
    var subscriberAttribute2: SubscriberAttribute!
    var mockHTTPClient: MockHTTPClient!
    var mockETagManager: MockETagManager!
    var backend: Backend!

    let validSubscriberResponse: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "app_user_id",
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2017-08-30T02:40:36Z"
                ]
            ]
        ]
    ]

    // swiftlint:disable:next force_try
    let systemInfo = try! SystemInfo(platformFlavor: "Unity", platformFlavorVersion: "2.3.3", finishTransactions: true)

    override func setUp() {
        mockETagManager = MockETagManager(userDefaults: MockUserDefaults())
        mockHTTPClient = MockHTTPClient(systemInfo: systemInfo, eTagManager: mockETagManager)
        self.backend = Backend(httpClient: mockHTTPClient, apiKey: "key")
        dateProvider = MockDateProvider(stubbedNow: now)
        subscriberAttribute1 = SubscriberAttribute(withKey: "a key",
                                                   value: "a value",
                                                   dateProvider: dateProvider)

        subscriberAttribute2 = SubscriberAttribute(withKey: "another key",
                                                   value: "another value",
                                                   dateProvider: dateProvider)
    }

    // MARK: PostSubscriberAttributes
    func testPostSubscriberAttributesSendsRightParameters() {

        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (_: Error!) in })

        expect(self.mockHTTPClient.invokedPerformRequest) == true
        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1

        guard let receivedParameters = mockHTTPClient.invokedPerformRequestParameters else {
            fatalError("no parameters sent!")
        }

        expect(receivedParameters.httpMethod) == "POST"
        expect(receivedParameters.path) == "/subscribers/abc123/attributes"

        let expectedBody: [String: [String: NSObject]] = [
            "attributes": [
                subscriberAttribute1.key: [
                    "updated_at_ms": (subscriberAttribute1.setTime as NSDate).millisecondsSince1970AsUInt64(),
                    "value": subscriberAttribute1.value
                ] as NSObject,
                subscriberAttribute2.key: [
                    "updated_at_ms": (subscriberAttribute2.setTime as NSDate).millisecondsSince1970AsUInt64(),
                    "value": subscriberAttribute2.value
                ] as NSObject
            ]
        ]

        expect(receivedParameters.requestBody as? [String: [String: NSObject]]).to(equal(expectedBody))
        expect(receivedParameters.headers) == ["Authorization": "Bearer key"]
    }

    func testPostSubscriberAttributesCallsCompletionInSuccessCase() {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true

        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (_: Error!) in
            completionCallCount += 1
        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1
        expect(completionCallCount).toEventually(equal(1))
    }

    func testPostSubscriberAttributesCallsCompletionInNetworkErrorCase() {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true
        let underlyingError = NSError(domain: "domain", code: 0, userInfo: nil)

        mockHTTPClient.stubbedCompletionError = ErrorUtils.networkError(withUnderlyingError: underlyingError)

        var receivedError: Error?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (error: Error!) in
            completionCallCount += 1
            receivedError = error
        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1
        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toNot(beNil())
        expect(receivedError).to(beAKindOf(Error.self))
        let receivedNSError = receivedError! as NSError

        expect(receivedNSError.code) == ErrorCode.networkError.rawValue
        expect(receivedNSError.successfullySynced) == false
    }

    func testPostSubscriberAttributesCallsCompletionWithErrorInBackendErrorCase() throws {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true
        mockHTTPClient.stubbedCompletionStatusCode = 503
        mockHTTPClient.stubbedCompletionError = nil

        var receivedError: Error?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (error: Error!) in
            completionCallCount += 1
            receivedError = error
        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1
        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toNot(beNil())
        expect(receivedError).to(beAKindOf(Error.self))

        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == ErrorCode.unknownBackendError.rawValue
        expect(receivedNSError.successfullySynced) == false
        let successfulSyncedKey = try XCTUnwrap(receivedNSError.userInfo[Backend.RCSuccessfullySyncedKey as String])
        let successfulSyncedKeyBoolValue = try XCTUnwrap((successfulSyncedKey as? NSNumber)?.boolValue)

        expect(successfulSyncedKeyBoolValue) == false
    }

    func testPostSubscriberAttributesSendsAttributesErrorsIfAny() {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true
        mockHTTPClient.stubbedCompletionStatusCode = 503
        mockHTTPClient.stubbedCompletionError = nil
        let attributeErrors = [Backend.RCAttributeErrorsKey: ["some_attribute": "wasn't valid"]]
        mockHTTPClient.stubbedCompletionResponse = attributeErrors

        var receivedError: Error?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (error: Error!) in
            completionCallCount += 1
            receivedError = error
        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1
        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toNot(beNil())
        expect(receivedError).to(beAKindOf(Error.self))

        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == ErrorCode.unknownBackendError.rawValue
        expect(receivedNSError.userInfo[Backend.RCAttributeErrorsKey]).toNot(beNil())

        let maybeReceivedAttributeErrors = receivedNSError.userInfo[Backend.RCAttributeErrorsKey]
        guard let receivedAttributeErrors = maybeReceivedAttributeErrors as? [String: String] else {
            fail("received attribute errors are not of type [String: String]")
            return
        }
        expect(receivedAttributeErrors) == ["some_attribute": "wasn't valid"]
    }

    func testPostSubscriberAttributesCallsCompletionWithErrorInBadRequestCase() throws {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true
        mockHTTPClient.stubbedCompletionStatusCode = 400
        mockHTTPClient.stubbedCompletionError = nil

        var receivedError: Error?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (error: Error!) in
            completionCallCount += 1
            receivedError = error

        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1
        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toNot(beNil())
        expect(receivedError).to(beAKindOf(Error.self))

        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == ErrorCode.unknownBackendError.rawValue
        expect(receivedNSError.successfullySynced) == true

        let successfulSyncedKey = try XCTUnwrap(receivedNSError.userInfo[Backend.RCSuccessfullySyncedKey as String])
        let successfulSyncedKeyBoolValue = try XCTUnwrap((successfulSyncedKey as? NSNumber)?.boolValue)

        expect(successfulSyncedKeyBoolValue) == true
    }

    func testPostSubscriberAttributesNoOpIfAttributesAreEmpty() {
        var completionCallCount = 0
        backend.post(subscriberAttributes: [:],
                     appUserID: appUserID,
                     completion: { (_: Error!) in
            completionCallCount += 1

        })
        expect(self.mockHTTPClient.invokedPerformRequestCount) == 0
    }

    func testPostSubscriberAttributesCallsCompletionWithErrorInNotFoundCase() throws {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true
        mockHTTPClient.stubbedCompletionStatusCode = 404
        mockHTTPClient.stubbedCompletionError = nil

        var receivedError: Error?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { error in
            completionCallCount += 1
            receivedError = error
        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1
        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toNot(beNil())
        expect(receivedError).to(beAKindOf(Error.self))

        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == ErrorCode.unknownBackendError.rawValue
        expect(receivedNSError.successfullySynced) == false

        let successfulSyncedKey = try XCTUnwrap(receivedNSError.userInfo[Backend.RCSuccessfullySyncedKey as String])
        let successfulSyncedKeyBoolValue = try XCTUnwrap((successfulSyncedKey as? NSNumber)?.boolValue)

        expect(successfulSyncedKeyBoolValue) == false
    }

    // MARK: PostReceipt with subscriberAttributes

    func testPostReceiptWithSubscriberAttributesSendsThemCorrectly() {
        var completionCallCount = 0

        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]

        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: subscriberAttributesByKey,
                     completion: { (_, _) in
            completionCallCount += 1
        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1

        guard let receivedParameters = mockHTTPClient.invokedPerformRequestParameters,
              let requestBody = receivedParameters.requestBody else {
                  fatalError("parameters or request body missing!")
              }

        expect(requestBody["attributes"]).toNot(beNil())

        let expectedBody: [String: NSObject] = [
            subscriberAttribute1.key: [
                "updated_at_ms": (subscriberAttribute1.setTime as NSDate).millisecondsSince1970AsUInt64(),
                "value": subscriberAttribute1.value
            ] as NSObject,
            subscriberAttribute2.key: [
                "updated_at_ms": (subscriberAttribute2.setTime as NSDate).millisecondsSince1970AsUInt64(),
                "value": subscriberAttribute2.value
            ] as NSObject
        ]

        expect(requestBody["attributes"] as? [String: NSObject]) == expectedBody
    }

    func testPostReceiptWithSubscriberAttributesReturnsBadJson() {
        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]

        var maybeReceivedError: Error?
        var maybeCustomerInfo: CustomerInfo?
        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: subscriberAttributesByKey,
                     completion: { (customerInfo, error) in
            maybeReceivedError = error
            maybeCustomerInfo = customerInfo
        })

        expect(maybeCustomerInfo).toEventually(beNil())

        guard let nsError = maybeReceivedError as NSError? else {
            fail("receivedError is nil")
            return
        }

        expect(nsError.domain) == RevenueCat.ErrorCode._nsErrorDomain
        expect(nsError.code) == ErrorCode.unexpectedBackendResponseError.rawValue

        guard let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError else {
            fail("Underlying error missing")
            return
        }

        expect(underlyingError.domain) == "RevenueCat.UnexpectedBackendResponseSubErrorCode"
        expect(underlyingError.code) == UnexpectedBackendResponseSubErrorCode.customerInfoResponseParsing.rawValue

        guard let parsingError = underlyingError.userInfo[NSUnderlyingErrorKey] as? NSError else {
            fail("Additional error details missing")
            return
        }

        expect(parsingError.domain) == "RevenueCat.CustomerInfoError"
        expect(parsingError.code) == CustomerInfoError.missingJsonObject.rawValue
    }

    func testPostReceiptWithoutSubscriberAttributesSkipsThem() {
        var completionCallCount = 0

        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil,
                     completion: { (_, _) in
            completionCallCount += 1
        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1

        guard let receivedParameters = mockHTTPClient.invokedPerformRequestParameters,
              let requestBody = receivedParameters.requestBody else {
                  fatalError("parameters or request body missing!")
              }

        expect(requestBody["attributes"]).to(beNil())
    }

    func testPostReceiptWithSubscriberAttributesPassesErrorsToCallbackIfStatusCodeIsError() {
        var completionCallCount = 0

        self.mockHTTPClient.stubbedCompletionStatusCode = 400
        let attributeErrors = [
            Backend.RCAttributeErrorsKey: ["$email": "email is not in valid format"]
        ]
        let attributesErrorsResponse = [
            Backend.RCAttributeErrorsResponseKey: attributeErrors
        ]
        self.mockHTTPClient.stubbedCompletionResponse = attributesErrorsResponse

        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]
        var receivedError: NSError?
        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: subscriberAttributesByKey,
                     completion: { (_, error) in
            completionCallCount += 1
            receivedError = error as NSError?
        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1
        expect(receivedError).toNot(beNil())
        guard let nonNilReceivedError = receivedError else {
            fail("missing receivedError")
            return
        }
        expect(nonNilReceivedError.successfullySynced) == true
        expect(nonNilReceivedError.subscriberAttributesErrors) == attributeErrors[Backend.RCAttributeErrorsKey]

        guard let underlyingError = (nonNilReceivedError as NSError).userInfo[NSUnderlyingErrorKey] as? NSError else {
            fail("Missing underlying error")
            return
        }

        expect(underlyingError.userInfo[NSUnderlyingErrorKey]).to(beNil())
    }

    func testPostReceiptWithSubscriberAttributesPassesErrorsToCallbackIfStatusCodeIsSuccess() {
        var completionCallCount = 0

        self.mockHTTPClient.stubbedCompletionStatusCode = 200
        let attributeErrors = [
            Backend.RCAttributeErrorsKey: ["$email": "email is not in valid format"]
        ]
        var response: [String: Any] = validSubscriberResponse
        response[Backend.RCAttributeErrorsResponseKey] = attributeErrors
        self.mockHTTPClient.stubbedCompletionResponse = response

        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]
        var receivedError: NSError?
        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: subscriberAttributesByKey,
                     completion: { (_, error) in
            completionCallCount += 1
            receivedError = error as NSError?
        })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1

        expect(receivedError).toNot(beNil())
        guard let nonNilReceivedError = receivedError else { fatalError() }
        expect(nonNilReceivedError.successfullySynced) == true
        expect(nonNilReceivedError.subscriberAttributesErrors)
        == attributeErrors[Backend.RCAttributeErrorsKey]
    }

}
