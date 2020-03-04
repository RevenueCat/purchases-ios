//
// Created by RevenueCat on 2/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class BackendSubscriberAttributesTests: XCTestCase {
    let appUserID = "abc123"
    let now = Date()
    let receiptData = "an awesome receipt".data(using: String.Encoding.utf8)!

    var dateProvider: MockDateProvider!
    var subscriberAttribute1: RCSubscriberAttribute!
    var subscriberAttribute2: RCSubscriberAttribute!
    var mockHTTPClient: MockHTTPClient!
    var backend: RCBackend!

    override func setUp() {
        mockHTTPClient = MockHTTPClient(platformFlavor: "iPhone")
        guard let backend = RCBackend(httpClient: mockHTTPClient, apiKey: "key") else { fatalError() }
        self.backend = backend
        dateProvider = MockDateProvider(stubbedNow: now)
        subscriberAttribute1 = RCSubscriberAttribute(key: "a key",
                                                     value: "a value",
                                                     dateProvider: dateProvider)

        subscriberAttribute2 = RCSubscriberAttribute(key: "another key",
                                                     value: "another value",
                                                     dateProvider: dateProvider)
    }

    // MARK: PostSubscriberAttributes
    func testPostSubscriberAttributesSendsRightParameters() {

        backend.postSubscriberAttributes([
                                             subscriberAttribute1.key: subscriberAttribute1,
                                             subscriberAttribute2.key: subscriberAttribute2
                                         ],
                                         appUserID: appUserID,
                                         completion: { (error: Error!) in })

        expect(self.mockHTTPClient.invokedPerformRequest) == true
        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1

        guard let receivedParameters = mockHTTPClient.invokedPerformRequestParameters else {
            fatalError("no parameters sent!")
        }

        expect(receivedParameters.HTTPMethod) == "POST"
        expect(receivedParameters.path) == "/subscribers/abc123/attributes"

        let expectedBody: [String: [String: NSObject]] = [
            "attributes": [
                subscriberAttribute1.key: [
                    "updated_at_ms": (subscriberAttribute1.setTime as NSDate).millisecondsSince1970(),
                    "value": subscriberAttribute1.value
                ] as NSObject,
                subscriberAttribute2.key: [
                    "updated_at_ms": (subscriberAttribute2.setTime as NSDate).millisecondsSince1970(),
                    "value": subscriberAttribute2.value
                ] as NSObject,
            ]
        ]

        expect(receivedParameters.requestBody as? [String: [String: NSObject]]).to(equal(expectedBody))
        expect(receivedParameters.headers) == ["Authorization": "Bearer key"]
    }

    func testPostSubscriberAttributesCallsCompletionInSuccessCase() {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true

        backend.postSubscriberAttributes([
                                             subscriberAttribute1.key: subscriberAttribute1,
                                             subscriberAttribute2.key: subscriberAttribute2
                                         ],
                                         appUserID: appUserID,
                                         completion: { (error: Error!) in
                                             completionCallCount += 1
                                         })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1
        expect(completionCallCount).toEventually(equal(1))
    }

    func testPostSubscriberAttributesCallsCompletionInNetworkErrorCase() {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true
        let underlyingError = NSError(domain: "domain", code: 0, userInfo: nil)

        mockHTTPClient.stubbedCompletionError = Purchases.ErrorUtils.networkError(withUnderlyingError: underlyingError)

        var receivedError: Error? = nil
        backend.postSubscriberAttributes([
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

        expect(receivedNSError.code) == Purchases.ErrorCode.networkError.rawValue
        expect(receivedNSError.successfullySynced()) == false
    }

    func testPostSubscriberAttributesCallsCompletionWithErrorInBackendErrorCase() {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true
        mockHTTPClient.stubbedCompletionStatusCode = 503
        mockHTTPClient.stubbedCompletionError = nil

        var receivedError: Error? = nil
        backend.postSubscriberAttributes([
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
        expect(receivedNSError.code) == Purchases.ErrorCode.unknownBackendError.rawValue
        expect(receivedNSError.successfullySynced()) == false
        expect(receivedNSError.userInfo["successfullySynced"]).toNot(beNil())
        expect((receivedNSError.userInfo["successfullySynced"] as! NSNumber).boolValue) == false
    }


    func testPostSubscriberAttributesCallsCompletionWithErrorInBadRequestCase() {
        var completionCallCount = 0
        mockHTTPClient.shouldInvokeCompletion = true
        mockHTTPClient.stubbedCompletionStatusCode = 400
        mockHTTPClient.stubbedCompletionError = nil

        var receivedError: Error? = nil
        backend.postSubscriberAttributes([
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
        expect(receivedNSError.code) == Purchases.ErrorCode.unknownBackendError.rawValue
        expect(receivedNSError.successfullySynced()) == true
        expect(receivedNSError.userInfo["successfullySynced"]).toNot(beNil())
        expect((receivedNSError.userInfo["successfullySynced"] as! NSNumber).boolValue) == true
    }

    func testPostSubscriberAttributesNoOpIfAttributesAreEmpty() {
        var completionCallCount = 0
        backend.postSubscriberAttributes([:],
                                         appUserID: appUserID,
                                         completion: { (error: Error!) in
                                             completionCallCount += 1
                                         })
        expect(self.mockHTTPClient.invokedPerformRequestCount) == 0
    }
    
    // MARK: PostReceipt with subscriberAttributes

    func testPostReceiptWithSubscriberAttributesSendsThemCorrectly() {
        var completionCallCount = 0

        let subscriberAttributesByKey: [String: RCSubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]

        backend.postReceiptData(receiptData,
                                appUserID: appUserID,
                                isRestore: false,
                                productIdentifier: nil,
                                price: nil,
                                paymentMode: .none,
                                introductoryPrice: nil,
                                currencyCode: nil,
                                subscriptionGroup: nil,
                                discounts: nil,
                                presentedOfferingIdentifier: nil,
                                observerMode: false,
                                subscriberAttributes: subscriberAttributesByKey,
                                completion: { (purchaserInfo, error) in
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
                "updated_at_ms": (subscriberAttribute1.setTime as NSDate).millisecondsSince1970(),
                "value": subscriberAttribute1.value
            ] as NSObject,
            subscriberAttribute2.key: [
                "updated_at_ms": (subscriberAttribute2.setTime as NSDate).millisecondsSince1970(),
                "value": subscriberAttribute2.value
            ] as NSObject
        ]

        expect(requestBody["attributes"] as? [String: NSObject]) == expectedBody
    }

    func testPostReceiptWithoutSubscriberAttributesSkipsThem() {
        var completionCallCount = 0

        backend.postReceiptData(receiptData,
                                appUserID: appUserID,
                                isRestore: false,
                                productIdentifier: nil,
                                price: nil,
                                paymentMode: .none,
                                introductoryPrice: nil,
                                currencyCode: nil,
                                subscriptionGroup: nil,
                                discounts: nil,
                                presentedOfferingIdentifier: nil,
                                observerMode: false,
                                subscriberAttributes: nil,
                                completion: { (purchaserInfo, error) in
                                    completionCallCount += 1
                                })

        expect(self.mockHTTPClient.invokedPerformRequestCount) == 1

        guard let receivedParameters = mockHTTPClient.invokedPerformRequestParameters,
            let requestBody = receivedParameters.requestBody else {
            fatalError("parameters or request body missing!")
        }

        expect(requestBody["attributes"]).to(beNil())
    }
}
