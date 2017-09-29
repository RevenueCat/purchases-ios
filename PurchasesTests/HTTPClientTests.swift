//
//  HTTPClientTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/28/17.
//  Copyright © 2017 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases


class HTTPClientTests: XCTestCase {

    let client = RCHTTPClient()

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
    }

    func testCantPostABodyWithGet() {
        expect {
            self.client.performRequest("GET", path: "/", body: Dictionary.init(),
                                       headers: nil, completionHandler: nil)
        }.to(raiseException())
    }

    func testUnrecognizedMethodFails() {
        expect {
            self.client.performRequest("GE", path: "/", body: Dictionary.init(),
                                       headers: nil, completionHandler: nil)
            }.to(raiseException())
    }

    func testUsesTheCorrectHost() {
        let path = "/a_random_path"
        var hostCorrect = false

        stub(condition: isHost(RCHTTPClient.serverHostName())) { _ in
            hostCorrect = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: nil, completionHandler:nil)

        expect(hostCorrect).toEventually(equal(true), timeout: 1.0)
    }

    func testPassesHeaders() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("test_header")) { _ in
            headerPresent = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true), timeout: 1.0)
    }

    func testAlwaysSetsContentTypeHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("content-type", value: "application/json")) { request in
            headerPresent = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true), timeout: 1.0)
    }

    func testAlwaysPassesPlatformHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform", value: "iOS")) { request in
            headerPresent = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesVersionHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Version", value: RCPurchases.frameworkVersion())) { request in
            headerPresent = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesPlatformVersion() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Version", value: UIDevice.current.systemVersion)) { request in
            headerPresent = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testCallsTheGivenPath() {
        let path = "/a_random_path"
        var pathHit = false

        stub(condition: isPath("/v1" + path)) { _ in
            pathHit = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }
        
        self.client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: nil, completionHandler:nil)

        expect(pathHit).toEventually(equal(true), timeout: 1.0)
    }

    func testCallsWithCorrectMethod() {
        let path = "/a_random_path"
        let (method, body) = [("POST", Dictionary<String, String>.init()), ("GET", nil)][Int(arc4random() % 2)]
        var pathHit = false

        stub(condition: isPath("/v1" + path)) { request in
            pathHit = request.httpMethod == method
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest(method, path: path, body: body, headers: nil, completionHandler:nil)

        expect(pathHit).toEventually(equal(true), timeout: 1.0)
    }

    func testSendsBodyData() {
        let path = "/a_random_path"
        let (method, body) = ("POST", ["arg": "value"])
        var pathHit = false

        let bodyData = try! JSONSerialization.data(withJSONObject: body)

        stub(condition: hasBody(bodyData)) { _ in
            pathHit = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest(method, path: path, body: body, headers: nil, completionHandler:nil)

        expect(pathHit).toEventually(equal(true))
    }

    func testCallsCompletionHandlerWhenFinished() {
        let path = "/a_random_path"
        var completionCalled = false

        stub(condition: isPath("/v1" + path)) { _ in
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (success, data) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(equal(true), timeout: 1.0)
    }

    func testHandlesRealErrorConditions() {
        let path = "/a_random_path"
        var successFailed = false
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        stub(condition: isPath("/v1" + path)) { request in
            let response = OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
            response.error = error
            return response
        }

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (success, data) in
            successFailed = (success == false) && (data == nil)
        }

        expect(successFailed).toEventually(equal(true), timeout: 1.0)
    }

    func testServerSideErrors() {
        let path = "/a_random_path"
        let errorCode = 400 + arc4random() % 150
        var successIsFalse = false
        var message: String?

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return OHHTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:Int32(errorCode), headers:nil)
        }

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (success, data) in
            successIsFalse = success == false
            if data != nil {
                message = data!["message"] as! String?
            }
        }

        expect(message).toEventually(equal("something is broken up in the cloud"), timeout: 1.0)
        expect(successIsFalse).toEventually(beTrue(), timeout: 1.0)
    }

    func testWordsForGoodErrorCodes() {
        let path = "/a_random_path"

        var successIsTrue = false
        var message: String?

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{\"message\": \"something is great up in the cloud\"}"
            return OHHTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:200, headers:nil)
        }

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (success, data) in
            successIsTrue = (success == true)
            if data != nil {
                message = data!["message"] as! String?
            }
        }

        expect(message).toEventually(equal("something is great up in the cloud"), timeout: 1.0)
        expect(successIsTrue).toEventually(beTrue(), timeout: 1.0)
    }
}

