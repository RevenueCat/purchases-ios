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

    override func setUp() {
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
        let mockHTTPClient = MockHTTPClient(platformFlavor: "iPhone")
        guard let backend = RCBackend(httpClient: mockHTTPClient, apiKey: "key") else { fatalError() }

        backend.postSubscriberAttributes([
                                             subscriberAttribute1.key: subscriberAttribute1,
                                             subscriberAttribute2.key: subscriberAttribute2
                                         ],
                                         appUserID: appUserID,
                                         completion: { (error: Error!) in })

        expect(mockHTTPClient.invokedPerformRequest) == true
        expect(mockHTTPClient.invokedPerformRequestCount) == 1

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
    }

    func testPostSubscriberAttributesCallsCompletionInNetworkErrorCase() {
    }

    func testPostSubscriberAttributesCallsCompletionInBackendErrorCase() {
    }

    func testPostSubscriberAttributesNoOpIfAttributesAreEmpty() {
    }
}
