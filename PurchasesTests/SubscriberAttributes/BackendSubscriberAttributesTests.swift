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
                                                     appUserID: appUserID,
                                                     dateProvider: dateProvider)

        subscriberAttribute2 = RCSubscriberAttribute(key: "another key",
                                                     value: "another value",
                                                     appUserID: appUserID,
                                                     dateProvider: dateProvider)
    }

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
                    "updated_at": subscriberAttribute1.setTime.timeIntervalSince1970,
                    "value": subscriberAttribute1.value
                ] as NSObject,
                subscriberAttribute2.key: [
                    "updated_at": subscriberAttribute2.setTime.timeIntervalSince1970,
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
        expect((receivedError! as NSError).code) == Purchases.ErrorCode.networkError.rawValue
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
        expect(receivedNSError.code) == Purchases.ErrorCode.networkError.rawValue
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
}
