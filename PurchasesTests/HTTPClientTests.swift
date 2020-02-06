//
//  HTTPClientTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases


class HTTPClientTests: XCTestCase {

    let client = RCHTTPClient(platformFlavor: nil)

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

        stub(condition: hasHeaderNamed("X-Version", value: Purchases.frameworkVersion())) { request in
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

        stub(condition: hasHeaderNamed("X-Platform-Version", value: ProcessInfo().operatingSystemVersionString)) { request in
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

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (status, data, error) in
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

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (status, data, responseError) in
            successFailed = (status >= 500) && (data == nil) && (error == responseError as NSError?)
        }

        expect(successFailed).toEventually(equal(true), timeout: 1.0)
    }

    func testServerSide400s() {
        let path = "/a_random_path"
        let errorCode = 400 + arc4random() % 50
        var correctResponse = false
        var message: String?

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return OHHTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:Int32(errorCode), headers:nil)
        }

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (status, data, error) in
            correctResponse = (status == errorCode) && (data != nil) && (error == nil);
            if data != nil {
                message = data!["message"] as! String?
            }
        }

        expect(message).toEventually(equal("something is broken up in the cloud"), timeout: 1.0)
        expect(correctResponse).toEventually(beTrue(), timeout: 1.0)
    }

    func testServerSide500s()  {
        let path = "/a_random_path"
        let errorCode = 500 + arc4random() % 50
        var correctResponse = false
        var message: String?

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return OHHTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:Int32(errorCode), headers:nil)
        }

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (status, data, error) in
            correctResponse = (status == errorCode) && (data != nil) && (error == nil);
            if data != nil {
                message = data!["message"] as! String?
            }
        }

        expect(message).toEventually(equal("something is broken up in the cloud"), timeout: 1.0)
        expect(correctResponse).toEventually(beTrue(), timeout: 1.0)
    }

    func testParseError() {
        let path = "/a_random_path"
        let errorCode = 200 + arc4random() % 300
        var correctResponse = false

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{this is not JSON.csdsd"
            return OHHTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:Int32(errorCode), headers:nil)
        }

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (status, data, error) in
            correctResponse = (status == errorCode) && (data == nil) && (error != nil);
        }

        expect(correctResponse).toEventually(beTrue(), timeout: 1.0)
    }

    func testServerSide200s() {
        let path = "/a_random_path"

        var successIsTrue = false
        var message: String?

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{\"message\": \"something is great up in the cloud\"}"
            return OHHTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:200, headers:nil)
        }

        self.client.performRequest("GET", path: path, body: nil, headers: nil) { (status, data, error) in
            successIsTrue = (status == 200) && (error == nil);
            if data != nil {
                message = data!["message"] as! String?
            }
        }

        expect(message).toEventually(equal("something is great up in the cloud"), timeout: 1.0)
        expect(successIsTrue).toEventually(beTrue(), timeout: 1.0)
    }
    
    func testAlwaysPassesClientVersion() {
        let path = "/a_random_path"
        var headerPresent = false
        
        let version = "" // for unit tests the version will empty

        stub(condition: hasHeaderNamed("X-Client-Version", value: version )) { request in
            headerPresent = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }
        
        self.client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)
        
        expect(headerPresent).toEventually(equal(true))
    }

    func testDefaultsPlatformFlavorToNative() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "native")) { request in
            headerPresent = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }
    
    func testPassesPlatformFlavorHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "react-native")) { request in
            headerPresent = true
            return OHHTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }
        let client = RCHTTPClient(platformFlavor: "react-native")

        client.performRequest("POST", path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }
}

