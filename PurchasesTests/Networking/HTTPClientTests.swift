//
//  HTTPClientTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
import Nimble

import Purchases
import PurchasesCoreSwift

class HTTPClientTests: XCTestCase {

    let systemInfo = RCSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
    var client: RCHTTPClient!
    var userDefaults: UserDefaults!
    var eTagManager: MockETagManager!

    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
        eTagManager = MockETagManager(userDefaults: userDefaults)
        client = RCHTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
    }

    func testCantPostABodyWithGet() {
        expectToThrowException(.parameterAssert) {
            self.client.performRequest("GET", serially: true, path: "/", body: Dictionary.init(),
                                       headers: nil, completionHandler: nil)
        }
        
    }

    func testUnrecognizedMethodFails() {
        expectToThrowException(.parameterAssert) {
            self.client.performRequest("GE", serially: true, path: "/", body: Dictionary.init(),
                                       headers: nil, completionHandler: nil)
            }
    }

    func testUsesTheCorrectHost() {
        let path = "/a_random_path"
        var hostCorrect = false

        guard let host = RCSystemInfo.serverHostURL().host else { fatalError() }
        stub(condition: isHost(host)) { _ in
            hostCorrect = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: nil, completionHandler:nil)

        expect(hostCorrect).toEventually(equal(true), timeout: .seconds(1))
    }

    func testPassesHeaders() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("test_header")) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysSetsContentTypeHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("content-type", value: "application/json")) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysPassesPlatformHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform", value: "iOS")) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesSandboxHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Is-Sandbox", value: "true")) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: [:],
                                   completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesVersionHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Version", value: Purchases.frameworkVersion())) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesPlatformVersion() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Version", value: ProcessInfo().operatingSystemVersionString)) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testCallsTheGivenPath() {
        let path = "/a_random_path"
        var pathHit = false

        stub(condition: isPath("/v1" + path)) { _ in
            pathHit = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }
        
        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: nil, completionHandler:nil)

        expect(pathHit).toEventually(equal(true), timeout: .seconds(1))
    }

    func testCallsWithCorrectMethod() {
        let path = "/a_random_path"
        let (method, body) = [("POST", Dictionary<String, String>.init()), ("GET", nil)][Int(arc4random() % 2)]
        var pathHit = false

        stub(condition: isPath("/v1" + path)) { request in
            pathHit = request.httpMethod == method
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest(method, serially: true, path: path, body: body, headers: nil, completionHandler:nil)

        expect(pathHit).toEventually(equal(true), timeout: .seconds(1))
    }

    func testSendsBodyData() {
        let path = "/a_random_path"
        let (method, body) = ("POST", ["arg": "value"])
        var pathHit = false

        let bodyData = try! JSONSerialization.data(withJSONObject: body)

        stub(condition: hasBody(bodyData)) { _ in
            pathHit = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest(method, serially: true, path: path, body: body, headers: nil, completionHandler:nil)

        expect(pathHit).toEventually(equal(true))
    }

    func testCallsCompletionHandlerWhenFinished() {
        let path = "/a_random_path"
        var completionCalled = false

        stub(condition: isPath("/v1" + path)) { _ in
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("GET", serially: true, path: path, body: nil, headers: nil) { (status, data, error) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(equal(true), timeout: .seconds(1))
    }

    func testHandlesRealErrorConditions() {
        let path = "/a_random_path"
        var successFailed = false
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        stub(condition: isPath("/v1" + path)) { request in
            let response = HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
            response.error = error
            return response
        }
        self.client.performRequest("GET", serially: true, path: path, body: nil, headers: nil) { (status, data, responseError) in
            if let responseNSError = responseError as NSError? {
                successFailed = (status >= 500
                                 && data == nil
                                 && error.domain == responseNSError.domain
                                 && error.code == responseNSError.code)
            } else {
                successFailed = false
            }
        }

        expect(successFailed).toEventually(equal(true))
    }

    func testServerSide400s() {
        let path = "/a_random_path"
        let errorCode = 400 + arc4random() % 50
        var correctResponse = false
        var message: String?

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:Int32(errorCode), headers:nil)
        }

        self.client.performRequest("GET", serially: true, path: path, body: nil, headers: nil) { (status, data, error) in
            correctResponse = (status == errorCode) && (data != nil) && (error == nil);
            if data != nil {
                message = data!["message"] as! String?
            }
        }

        expect(message).toEventually(equal("something is broken up in the cloud"), timeout: .seconds(1))
        expect(correctResponse).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testServerSide500s()  {
        let path = "/a_random_path"
        let errorCode = 500 + arc4random() % 50
        var correctResponse = false
        var message: String?

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:Int32(errorCode), headers:nil)
        }

        self.client.performRequest("GET", serially: true, path: path, body: nil, headers: nil) { (status, data, error) in
            correctResponse = (status == errorCode) && (data != nil) && (error == nil);
            if data != nil {
                message = data!["message"] as! String?
            }
        }

        expect(message).toEventually(equal("something is broken up in the cloud"), timeout: .seconds(1))
        expect(correctResponse).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testParseError() {
        let path = "/a_random_path"
        let errorCode = 200 + arc4random() % 300
        var correctResponse = false

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{this is not JSON.csdsd"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:Int32(errorCode), headers:nil)
        }

        self.client.performRequest("GET", serially: true, path: path, body: nil, headers: nil) { (status, data, error) in
            correctResponse = (status == errorCode) && (data == nil) && (error != nil);
        }

        expect(correctResponse).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testServerSide200s() {
        let path = "/a_random_path"

        var successIsTrue = false
        var message: String?

        stub(condition: isPath("/v1" + path)) { request in
            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:200, headers:nil)
        }

        self.client.performRequest("GET", serially: true, path: path, body: nil, headers: nil) { (status, data, error) in
            successIsTrue = (status == 200) && (error == nil);
            if data != nil {
                message = data!["message"] as! String?
            }
        }

        expect(message).toEventually(equal("something is great up in the cloud"), timeout: .seconds(1))
        expect(successIsTrue).toEventually(beTrue(), timeout: .seconds(1))
    }
    
    func testAlwaysPassesClientVersion() {
        let path = "/a_random_path"
        var headerPresent = false
        
        let version = RCSystemInfo.appVersion()

        stub(condition: hasHeaderNamed("X-Client-Version", value: version )) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }
        
        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)
        
        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesClientBuildVersion() {
        let path = "/a_random_path"
        var headerPresent = false

        let version = Bundle.main.infoDictionary!["CFBundleVersion"] as! String

        stub(condition: hasHeaderNamed("X-Client-Build-Version", value: version )) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesAppleDeviceIdentifier() {
        let path = "/a_random_path"
        var headerPresent = false

        let idfv = UIDevice.current.identifierForVendor!.uuidString

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testDefaultsPlatformFlavorToNative() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "native")) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }
    
    func testPassesPlatformFlavorHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "react-native")) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }
        let systemInfo = RCSystemInfo(platformFlavor: "react-native",
                                      platformFlavorVersion: "3.2.1",
                                      finishTransactions: true)
        let client = RCHTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)

        client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testPassesPlatformFlavorVersionHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor-Version", value: "1.2.3")) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }
        let systemInfo = RCSystemInfo(platformFlavor: "react-native",
                                      platformFlavorVersion: "1.2.3",
                                      finishTransactions: true)
        let client = RCHTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)

        client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenEnabled() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "false")) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }
        let systemInfo = RCSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
        let client = RCHTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)

        client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenDisabled() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "true")) { request in
            headerPresent = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }
        let systemInfo = RCSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: false)
        let client = RCHTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)

        client.performRequest("POST", serially: true, path: path, body: Dictionary.init(),
                                   headers: ["test_header": "value"], completionHandler:nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testPerformSerialRequestPerformsAllRequestsInTheCorrectOrder() {
        let path = "/a_random_path"
        var completionCallCount = 0

        stub(condition: isPath("/v1" + path)) { request in
            let requestData = request.ohhttpStubs_httpBody!
            let requestBodyDict = try! JSONSerialization.jsonObject(with: requestData, options: []) as! [String: Any]

            let requestNumber = requestBodyDict["requestNumber"] as! Int
            expect(requestNumber) == completionCallCount

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:200, headers:nil)
                .responseTime(0.003)
        }

        let totalRequests = Int.random(in: 50..<100)
        for requestNumber in 0..<totalRequests {
            self.client.performRequest("POST",
                                       serially: true,
                                       path: path,
                                       body: ["requestNumber": requestNumber],
                                       headers: nil) { (status, data, error) in
                completionCallCount += 1
            }
        }
        expect(completionCallCount).toEventually(equal(totalRequests))
    }

    func testPerformSerialRequestWaitsUntilFirstRequestIsDoneBeforeStartingSecond() {
        let path = "/a_random_path"
        var firstRequestFinished = false
        var secondRequestFinished = false

        stub(condition: isPath("/v1" + path)) { request in
            usleep(30)
            let requestData = request.ohhttpStubs_httpBody!
            let requestBodyDict = try! JSONSerialization.jsonObject(with: requestData, options: []) as! [String: Any]

            let requestNumber = requestBodyDict["requestNumber"] as! Int
            if requestNumber == 2 {
                expect(firstRequestFinished) == true
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:200, headers:nil)
                .responseTime(0.1)
        }

        self.client.performRequest("POST",
                                   serially: true,
                                   path: path,
                                   body: ["requestNumber": 1],
                                   headers: nil) { (status, data, error) in
            firstRequestFinished = true
        }

        self.client.performRequest("POST",
                                   serially: true,
                                   path: path,
                                   body: ["requestNumber": 2],
                                   headers: nil) { (status, data, error) in
            secondRequestFinished = true
        }

        expect(firstRequestFinished).toEventually(beTrue())
        expect(secondRequestFinished).toEventually(beTrue())
    }

    func testPerformConcurrentRequestDoesntWaitUntilFirstRequestIsDoneBeforeStartingSecond() {
        let path = "/a_random_path"
        var firstRequestFinished = false
        var secondRequestFinished = false

        stub(condition: isPath("/v1" + path)) { request in
            let requestData = request.ohhttpStubs_httpBody!
            let requestBodyDict = try! JSONSerialization.jsonObject(with: requestData, options: []) as! [String: Any]

            let requestNumber = requestBodyDict["requestNumber"] as! Int
            if requestNumber == 2 {
                expect(firstRequestFinished) == false
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:200, headers:nil)
                .responseTime(0.1)
        }

        self.client.performRequest("POST",
                                   serially: false,
                                   path: path,
                                   body: ["requestNumber": 1],
                                   headers: nil) { (status, data, error) in
            firstRequestFinished = true
        }

        self.client.performRequest("POST",
                                   serially: false,
                                   path: path,
                                   body: ["requestNumber": 2],
                                   headers: nil) { (status, data, error) in
            secondRequestFinished = true
        }

        expect(firstRequestFinished).toEventually(beTrue())
        expect(secondRequestFinished).toEventually(beTrue())
    }

    func testPerformConcurrentRequestDoesntWaitForSerialRequestsBeforeStarting() {
        let path = "/a_random_path"
        var firstRequestFinished = false
        var secondRequestFinished = false

        stub(condition: isPath("/v1" + path)) { request in
            let requestData = request.ohhttpStubs_httpBody!
            let requestBodyDict = try! JSONSerialization.jsonObject(with: requestData, options: []) as! [String: Any]

            let requestNumber = requestBodyDict["requestNumber"] as! Int
            if requestNumber == 2 {
                expect(firstRequestFinished) == false
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:200, headers:nil)
                .responseTime(0.1)
        }

        self.client.performRequest("POST",
                                   serially: true,
                                   path: path,
                                   body: ["requestNumber": 1],
                                   headers: nil) { (status, data, error) in
            firstRequestFinished = true
        }

        self.client.performRequest("POST",
                                   serially: false,
                                   path: path,
                                   body: ["requestNumber": 2],
                                   headers: nil) { (status, data, error) in
            secondRequestFinished = true
        }

        expect(firstRequestFinished).toEventually(beTrue())
        expect(secondRequestFinished).toEventually(beTrue())
    }

    func testPerformSerialRequestDoesntWaitForConcurrentRequestsBeforeStarting() {
        let path = "/a_random_path"
        var firstRequestFinished = false
        var secondRequestFinished = false

        stub(condition: isPath("/v1" + path)) { request in
            let requestData = request.ohhttpStubs_httpBody!
            let requestBodyDict = try! JSONSerialization.jsonObject(with: requestData, options: []) as! [String: Any]

            let requestNumber = requestBodyDict["requestNumber"] as! Int
            if requestNumber == 2 {
                expect(firstRequestFinished) == false
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode:200, headers:nil)
                .responseTime(0.1)
        }

        self.client.performRequest("POST",
                                   serially: false,
                                   path: path,
                                   body: ["requestNumber": 1],
                                   headers: nil) { (status, data, error) in
            firstRequestFinished = true
        }

        self.client.performRequest("POST",
                                   serially: true,
                                   path: path,
                                   body: ["requestNumber": 2],
                                   headers: nil) { (status, data, error) in
            secondRequestFinished = true
        }

        expect(firstRequestFinished).toEventually(beTrue())
        expect(secondRequestFinished).toEventually(beTrue())
    }

    func testPerformRequestFailsAssertionIfPostWithNilBody() {
        let path = "/a_random_path"

        expectToThrowException(.parameterAssert) {
            self.client.performRequest("POST",
                                       serially: true,
                                       path: path,
                                       body: nil,
                                       headers: nil, completionHandler: nil)
        }
    }

    func testPerformRequestExitsWithErrorIfBodyCouldntBeParsedIntoJSON() {
        // infinity can't be cast into JSON, so we use it to force a parsing exception. See:
        // https://developer.apple.com/documentation/foundation/nsjsonserialization?language=objc
        let nonJSONBody = ["something": Double.infinity]

        let path = "/a_random_path"
        var completionCalled = false
        var receivedError: Error? = nil
        var receivedStatus: Int? = nil
        var receivedData: [AnyHashable: Any]? = nil
        self.client.performRequest("POST",
                                   serially: true,
                                   path: path,
                                   body: nonJSONBody,
                                   headers: nil) { (status, data, error) in
            completionCalled = true
            receivedError = error
            receivedStatus = status
            receivedData = data
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == Purchases.ErrorCode.networkError.rawValue
        expect(receivedData).to(beNil())
        expect(receivedStatus) == -1
    }

    func testPerformRequestDoesntPerformRequestIfBodyCouldntBeParsedIntoJSON() {
        // infinity can't be cast into JSON, so we use it to force a parsing exception. See:
        // https://developer.apple.com/documentation/foundation/nsjsonserialization?language=objc
        let nonJSONBody = ["something": Double.infinity]

        let path = "/a_random_path"
        var completionCalled = false
        var httpCallMade = false

        stub(condition: isPath("/v1" + path)) { request in
            httpCallMade = true
            return HTTPStubsResponse(data: Data(), statusCode:200, headers:nil)
        }

        self.client.performRequest("POST",
                                   serially: true,
                                   path: path,
                                   body: nonJSONBody,
                                   headers: nil) { (status, data, error) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(httpCallMade).toEventually(beFalse())
    }

    func testRequestIsRetriedIfResponseFromETagManagerIsNil() {
        let path = "/a_random_path"
        var completionCalled = false

        var firstTimeCalled = false
        stub(condition: isPath("/v1" + path)) { _ in
            if (firstTimeCalled) {
                self.eTagManager.shouldReturnResultFromBackend = true
            }
            firstTimeCalled = true
            return HTTPStubsResponse(data: Data.init(), statusCode:200, headers:nil)
        }

        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = nil
        self.client.performRequest("GET", serially: true, path: path, body: nil, headers: nil) { (status, data, error) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(equal(true), timeout: .seconds(1))
    }
}

