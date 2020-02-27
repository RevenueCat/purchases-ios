//
// Created by RevenueCat on 2/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class BackendSubscriberAttributesTests: XCTestCase {

    func testPostSubscriberAttributesSendsRightParameters() {
        let mockHTTPClient = MockHTTPClient(platformFlavor: "iPhone")
        guard let backend = RCBackend(httpClient: mockHTTPClient, apiKey: "key") else { fatalError() }
        let appUserID = "abc123"
        let subscriberAttribute = RCSubscriberAttribute(key: "a key",
                                                        value: "a value",
                                                        appUserID: appUserID)

        backend.postSubscriberAttributes(["a key": subscriberAttribute], 
                                         appUserID: appUserID,
                                         completion: { (error: Error!) in })

        expect(mockHTTPClient.invokedPerformRequest) == true
        expect(mockHTTPClient.invokedPerformRequestCount) == 1

        guard let receivedParameters = mockHTTPClient.invokedPerformRequestParameters else {
            fatalError("no parameters sent!")
        }

        expect(receivedParameters.HTTPMethod) == "POST"
        expect(receivedParameters.path) == "/subscribers/abc123/attributes"
        expect(receivedParameters.requestBody).to(beNil())
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
