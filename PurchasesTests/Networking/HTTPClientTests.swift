//
//  HTTPClientTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import RevenueCat

class HTTPClientTests: XCTestCase {

    let systemInfo = MockSystemInfo(finishTransactions: true)
    var client: HTTPClient!
    var userDefaults: UserDefaults!
    var eTagManager: MockETagManager!
    var operationDispatcher: OperationDispatcher!

    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
        eTagManager = MockETagManager(userDefaults: userDefaults)
        operationDispatcher = OperationDispatcher()
        MockDNSChecker.resetData()

        client = HTTPClient(
            systemInfo: systemInfo,
            eTagManager: eTagManager,
            dnsChecker: MockDNSChecker.self
        )
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
    }

    func testUsesTheCorrectHost() {
        let path = "/a_random_path"
        var hostCorrect = false

        guard let host = SystemInfo.serverHostURL.host else { fatalError() }
        stub(condition: isHost(host)) { _ in
            hostCorrect = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: [:],
                                       headers: [:],
                                       completionHandler: nil)

        expect(hostCorrect).toEventually(equal(true), timeout: .seconds(1))
    }

    func testPassesHeaders() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("test_header")) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysSetsContentTypeHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("content-type", value: "application/json")) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysPassesPlatformHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform", value: SystemInfo.platformHeader)) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesVersionHeader() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Version", value: Purchases.frameworkVersion)) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesPlatformVersion() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Version", value: ProcessInfo().operatingSystemVersionString)) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testCallsTheGivenPath() {
        let path = "/a_random_path"
        var pathHit = false

        stub(condition: isPath("/v1" + path)) { _ in
            pathHit = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: [:],
                                       completionHandler: nil)

        expect(pathHit).toEventually(equal(true), timeout: .seconds(1))
    }

    func testSendsBodyData() throws {
        let path = "/a_random_path"
        let body = ["arg": "value"]
        var pathHit = false

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        stub(condition: hasBody(bodyData)) { _ in
            pathHit = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: body,
                                       headers: [:],
                                       completionHandler: nil)

        expect(pathHit).toEventually(equal(true))
    }

    func testCallsCompletionHandlerWhenFinished() {
        let path = "/a_random_path"
        var completionCalled = false

        stub(condition: isPath("/v1" + path)) { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performGETRequest(serially: true,
                                      path: path,
                                      headers: [:]) { (_, _, _) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(equal(true), timeout: .seconds(1))
    }

    func testHandlesRealErrorConditions() {
        let path = "/a_random_path"
        var successFailed = false
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = error
            return response
        }
        self.client.performGETRequest(serially: true,
                                      path: path,
                                      headers: [:]) { (status, data, responseError) in
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
        var maybeMessage: String?

        stub(condition: isPath("/v1" + path)) { _ in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.performGETRequest(serially: true,
                                      path: path,
                                      headers: [:]) { (status, data, error) in
            correctResponse = (status == errorCode) && (data != nil) && (error == nil)
            if data != nil {
                maybeMessage = data?["message"] as? String
            }
        }

        expect(maybeMessage).toEventually(equal("something is broken up in the cloud"), timeout: .seconds(1))
        expect(correctResponse).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testServerSide500s() {
        let path = "/a_random_path"
        let errorCode = 500 + arc4random() % 50
        var correctResponse = false
        var maybeMessage: String?

        stub(condition: isPath("/v1" + path)) { _ in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.performGETRequest(serially: true,
                                      path: path,
                                      headers: [:]) { (status, data, error) in
            correctResponse = (status == errorCode) && (data != nil) && (error == nil)
            if data != nil {
                maybeMessage = data?["message"] as? String
            }
        }

        expect(maybeMessage).toEventually(equal("something is broken up in the cloud"), timeout: .seconds(1))
        expect(correctResponse).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testParseError() {
        let path = "/a_random_path"
        let errorCode = 200 + arc4random() % 300
        var correctResponse = false

        stub(condition: isPath("/v1" + path)) { _ in
            let json = "{this is not JSON.csdsd"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.performGETRequest(serially: true,
                                      path: path,
                                      headers: [:]) { (status, data, error) in
            correctResponse = (status == errorCode) && (data == nil) && (error != nil)
        }

        expect(correctResponse).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testServerSide200s() {
        let path = "/a_random_path"

        var successIsTrue = false
        var maybeMessage: String?

        stub(condition: isPath("/v1" + path)) { _ in
            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode: 200, headers: nil)
        }

        self.client.performGETRequest(serially: true,
                                      path: path,
                                      headers: [:]) { (status, data, error) in
            successIsTrue = (status == 200) && (error == nil)
            if data != nil {
                maybeMessage = data?["message"] as? String
            }
        }

        expect(maybeMessage).toEventually(equal("something is great up in the cloud"), timeout: .seconds(1))
        expect(successIsTrue).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testAlwaysPassesClientVersion() {
        let path = "/a_random_path"
        var headerPresent = false

        let version = SystemInfo.appVersion

        stub(condition: hasHeaderNamed("X-Client-Version", value: version )) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAlwaysPassesClientBuildVersion() throws {
        let path = "/a_random_path"
        var headerPresent = false

        let version = try XCTUnwrap(Bundle.main.infoDictionary!["CFBundleVersion"] as? String)

        stub(condition: hasHeaderNamed("X-Client-Build-Version", value: version )) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    #if os(macOS) || targetEnvironment(macCatalyst)
    func testAlwaysPassesAppleDeviceIdentifierWhenIsSandbox() {
        let path = "/a_random_path"
        var headerPresent = false
        systemInfo.stubbedIsSandbox = true

        let idfv = systemInfo.identifierForVendor!

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testAppleDeviceIdentifierNilWhenIsNotSandbox() {
        systemInfo.stubbedIsSandbox = false

        let obtainedIdentifierForVendor = systemInfo.identifierForVendor

        expect(obtainedIdentifierForVendor).to(beNil())
    }

    #endif

    #if !os(macOS) && !targetEnvironment(macCatalyst)
    func testAlwaysPassesAppleDeviceIdentifier() {
        let path = "/a_random_path"
        var headerPresent = false

        let idfv = systemInfo.identifierForVendor!

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }
    #endif

    func testDefaultsPlatformFlavorToNative() {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "native")) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testPassesPlatformFlavorHeader() throws {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "react-native")) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let systemInfo = try SystemInfo(platformFlavor: "react-native",
                                        platformFlavorVersion: "3.2.1",
                                        finishTransactions: true)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        client.performPOSTRequest(serially: true,
                                  path: path,
                                  requestBody: Dictionary.init(),
                                  headers: ["test_header": "value"],
                                  completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testPassesPlatformFlavorVersionHeader() throws {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor-Version", value: "1.2.3")) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let systemInfo = try SystemInfo(platformFlavor: "react-native",
                                        platformFlavorVersion: "1.2.3",
                                        finishTransactions: true)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)

        client.performPOSTRequest(serially: true,
                                  path: path,
                                  requestBody: Dictionary.init(),
                                  headers: ["test_header": "value"],
                                  completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenEnabled() throws {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "false")) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let systemInfo = try SystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        client.performPOSTRequest(serially: true,
                                  path: path,
                                  requestBody: Dictionary.init(),
                                  headers: ["test_header": "value"],
                                  completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenDisabled() throws {
        let path = "/a_random_path"
        var headerPresent = false

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "true")) { _ in
            headerPresent = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let systemInfo = try SystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: false)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        client.performPOSTRequest(serially: true,
                                  path: path,
                                  requestBody: Dictionary.init(),
                                  headers: ["test_header": "value"],
                                  completionHandler: nil)

        expect(headerPresent).toEventually(equal(true))
    }

    func testPerformSerialRequestPerformsAllRequestsInTheCorrectOrder() {
        let path = "/a_random_path"
        var completionCallCount = 0

        stub(condition: isPath("/v1" + path)) { request in
            let requestNumber = self.extractRequestNumber(from: request)
            expect(requestNumber) == completionCallCount

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode: 200, headers: nil)
                .responseTime(0.003)
        }

        let serialRequests = 200
        for requestNumber in 0..<serialRequests {
            client.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: ["requestNumber": requestNumber],
                                      headers: [:]) { (_, _, _) in
                completionCallCount += 1
            }
        }
        expect(completionCallCount).toEventually(equal(serialRequests), timeout: .seconds(5))
    }

    func testPerformSerialRequestWaitsUntilFirstRequestIsDoneBeforeStartingSecond() {
        let path = "/a_random_path"
        var firstRequestFinished = false
        var secondRequestFinished = false

        stub(condition: isPath("/v1" + path)) { request in
            usleep(30)
            let requestNumber = self.extractRequestNumber(from: request)
            if requestNumber == 2 {
                expect(firstRequestFinished) == true
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode: 200, headers: nil)
                .responseTime(0.1)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: ["requestNumber": 1],
                                       headers: [:]) { (_, _, _) in
            firstRequestFinished = true
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: ["requestNumber": 2],
                                       headers: [:]) { (_, _, _) in
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
            let requestNumber = self.extractRequestNumber(from: request)
            if requestNumber == 2 {
                expect(firstRequestFinished) == false
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode: 200, headers: nil)
                .responseTime(0.1)
        }

        self.client.performPOSTRequest(serially: false,
                                       path: path,
                                       requestBody: ["requestNumber": 1],
                                       headers: [:]) { (_, _, _) in
            firstRequestFinished = true
        }

        self.client.performPOSTRequest(serially: false,
                                       path: path,
                                       requestBody: ["requestNumber": 2],
                                       headers: [:]) { (_, _, _) in
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
            let requestNumber = self.extractRequestNumber(from: request)
            if requestNumber == 2 {
                expect(firstRequestFinished) == false
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode: 200, headers: nil)
                .responseTime(0.1)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: ["requestNumber": 1],
                                       headers: [:]) { (_, _, _) in
            firstRequestFinished = true
        }

        self.client.performPOSTRequest(serially: false,
                                       path: path,
                                       requestBody: ["requestNumber": 2],
                                       headers: [:]) { (_, _, _) in
            secondRequestFinished = true
        }

        expect(firstRequestFinished).toEventually(beTrue())
        expect(secondRequestFinished).toEventually(beTrue())
    }

    func testPerformSerialRequestWaitsUntilRequestsAreDoneBeforeStartingNext() {
        let path = "/a_random_path"
        var firstRequestFinished = false
        var secondRequestFinished = false
        var thirdRequestFinished = false

        stub(condition: isPath("/v1" + path)) { request in
            let requestNumber = self.extractRequestNumber(from: request)
            var responseTime = 0.5
            if requestNumber == 1 {
                expect(secondRequestFinished) == false
                expect(thirdRequestFinished) == false
            } else if requestNumber == 2 {
                expect(firstRequestFinished) == true
                expect(thirdRequestFinished) == false
                responseTime = 0.3
            } else if requestNumber == 3 {
                expect(firstRequestFinished) == true
                expect(secondRequestFinished) == true
                responseTime = 0.1
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode: 200, headers: nil)
                .responseTime(responseTime)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: ["requestNumber": 1],
                                       headers: [:]) { (_, _, _) in
            firstRequestFinished = true
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: ["requestNumber": 2],
                                       headers: [:]) { (_, _, _) in
            secondRequestFinished = true
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: ["requestNumber": 3],
                                       headers: [:]) { (_, _, _) in
            thirdRequestFinished = true
        }

        expect(firstRequestFinished).toEventually(beTrue(), timeout: .seconds(1))
        expect(secondRequestFinished).toEventually(beTrue(), timeout: .seconds(2))
        expect(thirdRequestFinished).toEventually(beTrue(), timeout: .seconds(3))
    }

    func testPerformSerialRequestDoesntWaitForConcurrentRequestsBeforeStarting() {
        let path = "/a_random_path"
        var firstRequestFinished = false
        var secondRequestFinished = false

        stub(condition: isPath("/v1" + path)) { request in
            let requestNumber = self.extractRequestNumber(from: request)
            if requestNumber == 2 {
                expect(firstRequestFinished) == false
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode: 200, headers: nil)
                .responseTime(0.1)
        }

        self.client.performPOSTRequest(serially: false,
                                       path: path,
                                       requestBody: ["requestNumber": 1],
                                       headers: [:]) { (_, _, _) in
            firstRequestFinished = true
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: ["requestNumber": 2],
                                       headers: [:]) { (_, _, _) in
            secondRequestFinished = true
        }

        expect(firstRequestFinished).toEventually(beTrue())
        expect(secondRequestFinished).toEventually(beTrue())
    }

    func testPerformRequestExitsWithErrorIfBodyCouldntBeParsedIntoJSON() {
        // infinity can't be cast into JSON, so we use it to force a parsing exception. See:
        // https://developer.apple.com/documentation/foundation/nsjsonserialization?language=objc
        let nonJSONBody = ["something": Double.infinity]

        let path = "/a_random_path"
        var completionCalled = false
        var receivedError: Error?
        var receivedStatus: Int?
        var receivedData: [String: Any]?
        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: nonJSONBody,
                                       headers: [:]) { (status, data, error) in
            completionCalled = true
            receivedError = error
            receivedStatus = status
            receivedData = data
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError.code) == ErrorCode.networkError.rawValue
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

        stub(condition: isPath("/v1" + path)) { _ in
            httpCallMade = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(serially: true,
                                       path: path,
                                       requestBody: nonJSONBody,
                                       headers: [:]) { (_, _, _) in
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
            if firstTimeCalled {
                self.eTagManager.shouldReturnResultFromBackend = true
            }
            firstTimeCalled = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = nil
        self.client.performGETRequest(serially: true,
                                      path: path,
                                      headers: [:]) { (_, _, _) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(equal(true), timeout: .seconds(1))
    }

    func testDNSCheckerIsCalledWhenGETRequestFailedWithUnknownError() {
        let path = "/a_random_path"
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        MockDNSChecker.stubbedIsBlockedAPIErrorResult = false

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = error
            return response
        }

        self.client.performGETRequest(
            serially: true,
            path: path,
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError).toEventually(equal(false))
    }

    func testDNSCheckerIsCalledWhenPOSTRequestFailedWithUnknownError() {
        let path = "/a_random_path"
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        MockDNSChecker.stubbedIsBlockedAPIErrorResult = false

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = error
            return response
        }

        self.client.performPOSTRequest(
            serially: true,
            path: path,
            requestBody: [:],
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError).toEventually(equal(false))
    }

    func testDNSCheckedIsCalledWhenPOSTRequestFailedWithDNSError() {
        let path = "/a_random_path"
        let fakeSubscribersURL = URL(string: "https://0.0.0.0/subscribers")!
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL]
        let nsErrorWithUserInfo = NSError(domain: NSURLErrorDomain,
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        MockDNSChecker.stubbedIsBlockedAPIErrorResult = true

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = nsErrorWithUserInfo
            return response
        }

        self.client.performPOSTRequest(
            serially: true,
            path: path,
            requestBody: [:],
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError).toEventually(equal(true))
    }

    func testDNSCheckedIsCalledWhenGETRequestFailedWithDNSError() {
        let path = "/a_random_path"
        let fakeSubscribersURL = URL(string: "https://0.0.0.0/subscribers")!
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL]
        let nsErrorWithUserInfo = NSError(domain: NSURLErrorDomain,
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        MockDNSChecker.stubbedIsBlockedAPIErrorResult = true

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = nsErrorWithUserInfo
            return response
        }

        self.client.performGETRequest(
            serially: true,
            path: path,
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError).toEventually(equal(true))
    }

    func testErrorIsLoggedAndReturnsDNSErrorWhenGETRequestFailedWithDNSError() {
        let path = "/a_random_path"
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        let expectedDNSError = DNSError.blocked(
            failedURL: URL(string: "https://0.0.0.0/subscribers")!,
            resolvedHost: "0.0.0.0"
        )
        MockDNSChecker.stubbedIsBlockedAPIErrorResult = true
        MockDNSChecker.stubbedErrorWithBlockedHostFromErrorResult = expectedDNSError
        let expectedMessage = "\(LogIntent.rcError.prefix) \(expectedDNSError.description)"

        var loggedMessages = [String]()
        let originalLogHandler = Logger.logHandler
        Logger.logHandler = { _, message, _, _, _ in
            loggedMessages.append(message)
        }
        defer { Logger.logHandler = originalLogHandler }

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = error
            return response
        }

        var obtainedError: DNSError?
        self.client.performGETRequest(
            serially: true,
            path: path,
            headers: [:]) { _, _, error in
                obtainedError = error as? DNSError
            }

        expect(MockDNSChecker.invokedIsBlockedAPIError).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError).toEventually(equal(true))
        expect(obtainedError).toEventually(equal(expectedDNSError))
        expect(loggedMessages).toEventually(contain(expectedMessage))
    }

    func testErrorIsntLoggedWhenGETRequestFailedWithUnknownError() {
        let path = "/a_random_path"
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        let unexpectedDNSError = DNSError.blocked(
            failedURL: URL(string: "https://0.0.0.0/subscribers")!,
            resolvedHost: "0.0.0.0"
        )
        MockDNSChecker.stubbedIsBlockedAPIErrorResult = false

        var loggedMessages = [String]()
        let originalLogHandler = Logger.logHandler
        Logger.logHandler = { _, message, _, _, _ in
            loggedMessages.append(message)
        }

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = error
            return response
        }

        self.client.performGETRequest(
            serially: true,
            path: path,
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError).toEventually(equal(false))
        expect(loggedMessages).toNotEventually(contain(unexpectedDNSError.description))
        Logger.logHandler = originalLogHandler
    }

}

private extension HTTPClientTests {

    func extractRequestNumber(from urlRequest: URLRequest) -> Int? {
        do {
            let requestData = urlRequest.ohhttpStubs_httpBody!
            let requestBodyDict = try XCTUnwrap(try JSONSerialization.jsonObject(with: requestData,
                                                                                 options: []) as? [String: Any])
            return try XCTUnwrap(requestBodyDict["requestNumber"] as? Int)
        } catch {
            XCTFail("Couldn't extract the request number from the URLRequest")
            return nil
        }
    }

}
