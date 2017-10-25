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
        let success: Bool
        let response: [AnyHashable : Any]?
    }

    class MockHTTPClient: RCHTTPClient {

        var mocks: [String: HTTPResponse] = [:]
        var calls: [HTTPRequest] = []

        var shouldFinish = true

        override func performRequest(_ HTTPMethod: String, path: String, body requestBody: [AnyHashable : Any]?, headers: [String: String]?, completionHandler: ((Bool, [AnyHashable : Any]?) -> Void)? = nil) {
            assert(mocks[path] != nil, "Path " + path + " not mocked")
            let response = mocks[path]!

            calls.append(HTTPRequest(HTTPMethod: HTTPMethod, path: path, body: requestBody, headers: headers))

            if shouldFinish {
                completionHandler!(response.success, response.response)
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
                    "expires_date": "2017-08-30T02:40:36"
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
        let response = HTTPResponse(success: true, response: validSubscriberResponse)
        httpClient.mock(requestPath: "/receipts", response: response)



        var completionCalled = false

        backend?.postReceiptData(receiptData, appUserID: userID, completion: { (purchaserInfo, error) in
            completionCalled = true
        })

        let expectedCall = HTTPRequest(HTTPMethod: "POST", path: "/receipts", body: [
            "app_user_id": userID,
            "fetch_token": receiptData.base64EncodedString()
            ], headers: ["Authorization": "Basic " + apiKey])

        expect(self.httpClient.calls.count).to(equal(1))
        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            XCTAssertEqual(call.path, expectedCall.path)
            XCTAssertEqual(call.HTTPMethod, expectedCall.HTTPMethod)
            XCTAssertEqual(call.body!.keys, expectedCall.body!.keys)
            XCTAssertNotNil(call.headers?["Authorization"])
            XCTAssertEqual(call.headers?["Authorization"], expectedCall.headers?["Authorization"])
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testForwardsErrors() {
        let response = HTTPResponse(success: false, response: serverErrorResponse)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: Error?

        backend?.postReceiptData(receiptData, appUserID: userID, completion: { (purchaserInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect(error?.localizedDescription).to(equal(serverErrorResponse["message"]))
        expect((error as NSError?)?.code).to(equal(1))
    }

    func testHandlesUnexpectedErrors() {
        let response = HTTPResponse(success: false, response: nil)
        httpClient.mock(requestPath: "/receipts", response: response)

        var error: Error?

        backend?.postReceiptData(receiptData, appUserID: userID, completion: { (purchaserInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect((error as NSError?)?.domain).to(equal(RCBackendErrorDomain))
        expect((error as NSError?)?.code).to(equal(RCUnexpectedBackendResponse))
    }

    func testPostingReceiptCreatesASubscriberInfoObject() {
        let response = HTTPResponse(success: true, response: validSubscriberResponse)
        httpClient.mock(requestPath: "/receipts", response: response)

        var purchaserInfo: RCPurchaserInfo?

        backend?.postReceiptData(receiptData, appUserID: userID, completion: { (newPurchaserInfo, newError) in
            purchaserInfo = newPurchaserInfo
        })

        expect(purchaserInfo).toEventuallyNot(beNil())
        if purchaserInfo != nil {
            let expiration = purchaserInfo!.expirationDate(forProductIdentifier: "onemonth_freetrial")
            expect(expiration).toNot(beNil())
        }
    }

    func testGetSubscriberCallsBackendProperly() {
        let response = HTTPResponse(success: true, response: validSubscriberResponse)
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
        let response = HTTPResponse(success: true, response: validSubscriberResponse)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var subscriberInfo: RCPurchaserInfo?

        backend?.getSubscriberData(withAppUserID: userID, completion: { (newSubscriberInfo, newError) in
            subscriberInfo = newSubscriberInfo
        })

        expect(subscriberInfo).toEventuallyNot(beNil())
    }

    func testHandlesGetSubscriberInfoErrors() {
        let response = HTTPResponse(success: false, response: nil)
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var error: Error?

        backend?.getSubscriberData(withAppUserID: userID, completion: { (newSubscriberInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect((error as NSError?)?.domain).to(equal(RCBackendErrorDomain))
        expect((error as NSError?)?.code).to(equal(RCUnexpectedBackendResponse))
    }

    func testHandlesInvalidJSON() {
        let response = HTTPResponse(success: true, response: ["sjkaljdklsjadkjs": ""])
        httpClient.mock(requestPath: "/subscribers/" + userID, response: response)

        var error: Error?

        backend?.getSubscriberData(withAppUserID: userID, completion: { (newSubscriberInfo, newError) in
            error = newError
        })

        expect(error).toEventuallyNot(beNil())
        expect((error as NSError?)?.domain).to(equal(RCBackendErrorDomain))
        expect((error as NSError?)?.code).to(equal(RCErrorParsingPurchaserInfo))
    }

    func testTracksNumberOfReceiptPosts() {
        let response = HTTPResponse(success: true, response: validSubscriberResponse)
        httpClient.mock(requestPath: "/receipts", response: response)

        httpClient.shouldFinish = false

        expect(self.backend?.purchasing).to(beFalse())

        backend?.postReceiptData(receiptData, appUserID: userID, completion: { (newPurchaserInfo, newError) in
            
        })

        expect(self.backend?.purchasing).to(beTrue())
    }

    func testPurchasingIsKVOCompliant() {
        class KVOListener: NSObject {
            var lastValue = false;
            override func observeValue(forKeyPath keyPath: String?,
                                       of object: Any?,
                                       change: [NSKeyValueChangeKey : Any]?,
                                       context: UnsafeMutableRawPointer?) {
                lastValue = (object as! RCBackend).purchasing
            }
        }

        let listener = KVOListener()

        backend!.addObserver(listener, forKeyPath: "purchasing",
                             options: [.old, .new, .initial],
                             context: nil)

        expect(listener.lastValue).to(beFalse())

        let response = HTTPResponse(success: true, response: validSubscriberResponse)
        httpClient.mock(requestPath: "/receipts", response: response)

        httpClient.shouldFinish = false

        backend?.postReceiptData(receiptData, appUserID: userID, completion: { (newPurchaserInfo, newError) in

        })

        expect(listener.lastValue).to(beTrue())

        backend!.removeObserver(listener, forKeyPath: "purchasing")
    }

}
