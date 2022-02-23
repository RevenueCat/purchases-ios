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
        let hostCorrect: Atomic<Bool> = .init(false)

        guard let host = SystemInfo.serverHostURL.host else { fatalError() }
        stub(condition: isHost(host)) { _ in
            hostCorrect.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: [:],
                                       headers: [:],
                                       completionHandler: nil)

        expect(hostCorrect.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testPassesHeaders() {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("test_header")) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysSetsContentTypeHeader() {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("content-type", value: "application/json")) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysPassesPlatformHeader() {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform", value: SystemInfo.platformHeader)) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesVersionHeader() {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Version", value: Purchases.frameworkVersion)) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesPlatformVersion() {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform-Version", value: ProcessInfo().operatingSystemVersionString)) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testCallsTheGivenPath() {
        let path = "/a_random_path"
        let pathHit: Atomic<Bool> = .init(false)

        stub(condition: isPath("/v1" + path)) { _ in
            pathHit.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: [:],
                                       completionHandler: nil)

        expect(pathHit.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testSendsBodyData() throws {
        let path = "/a_random_path"
        let body = ["arg": "value"]
        let pathHit: Atomic<Bool> = .init(false)

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        stub(condition: hasBody(bodyData)) { _ in
            pathHit.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: body,
                                       headers: [:],
                                       completionHandler: nil)

        expect(pathHit.value).toEventually(equal(true))
    }

    func testCallsCompletionHandlerWhenFinished() {
        let path = "/a_random_path"
        let completionCalled: Atomic<Bool> = .init(false)

        stub(condition: isPath("/v1" + path)) { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performGETRequest(path: path,
                                      headers: [:]) { (_, _, _) in
            completionCalled.value = true
        }

        expect(completionCalled.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testHandlesRealErrorConditions() {
        let path = "/a_random_path"
        let successFailed: Atomic<Bool> = .init(false)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = error
            return response
        }
        self.client.performGETRequest(path: path,
                                      headers: [:]) { (status, data, responseError) in
            if let responseNSError = responseError as NSError? {
                successFailed.value = (status >= 500
                                       && data == nil
                                       && error.domain == responseNSError.domain
                                       && error.code == responseNSError.code)
            } else {
                successFailed.value = false
            }
        }

        expect(successFailed.value).toEventually(equal(true))
    }

    func testServerSide400s() {
        let path = "/a_random_path"
        let errorCode = 400 + arc4random() % 50
        let correctResponse: Atomic<Bool> = .init(false)
        let message: Atomic<String?> = .init(nil)

        stub(condition: isPath("/v1" + path)) { _ in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.performGETRequest(path: path,
                                      headers: [:]) { (status, data, error) in
            correctResponse.value = (status == errorCode) && (data != nil) && (error == nil)
            if data != nil {
                message.value = data?["message"] as? String
            }
        }

        expect(message.value).toEventually(equal("something is broken up in the cloud"), timeout: .seconds(1))
        expect(correctResponse.value).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testServerSide500s() {
        let path = "/a_random_path"
        let errorCode = 500 + arc4random() % 50
        let correctResponse: Atomic<Bool> = .init(false)
        let message: Atomic<String?> = .init(nil)

        stub(condition: isPath("/v1" + path)) { _ in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.performGETRequest(path: path,
                                      headers: [:]) { (status, data, error) in
            correctResponse.value = (status == errorCode) && (data != nil) && (error == nil)
            if data != nil {
                message.value = data?["message"] as? String
            }
        }

        expect(message.value).toEventually(equal("something is broken up in the cloud"), timeout: .seconds(1))
        expect(correctResponse.value).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testParseError() {
        let path = "/a_random_path"
        let errorCode = 200 + arc4random() % 300
        let correctResponse: Atomic<Bool> = .init(false)

        stub(condition: isPath("/v1" + path)) { _ in
            let json = "{this is not JSON.csdsd"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.performGETRequest(path: path,
                                      headers: [:]) { (status, data, error) in
            correctResponse.value = (status == errorCode) && (data == nil) && (error != nil)
        }

        expect(correctResponse.value).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testServerSide200s() {
        let path = "/a_random_path"

        let successIsTrue: Atomic<Bool> = .init(false)
        let message: Atomic<String?> = .init(nil)

        stub(condition: isPath("/v1" + path)) { _ in
            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode: 200, headers: nil)
        }

        self.client.performGETRequest(path: path,
                                      headers: [:]) { (status, data, error) in
            successIsTrue.value = (status == 200) && (error == nil)
            if data != nil {
                message.value = data?["message"] as? String
            }
        }

        expect(message.value).toEventually(equal("something is great up in the cloud"), timeout: .seconds(1))
        expect(successIsTrue.value).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testAlwaysPassesClientVersion() {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        let version = SystemInfo.appVersion

        stub(condition: hasHeaderNamed("X-Client-Version", value: version )) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesClientBuildVersion() throws {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        let version = try XCTUnwrap(Bundle.main.infoDictionary!["CFBundleVersion"] as? String)

        stub(condition: hasHeaderNamed("X-Client-Build-Version", value: version )) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    #if os(macOS) || targetEnvironment(macCatalyst)
    func testAlwaysPassesAppleDeviceIdentifierWhenIsSandbox() {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)
        systemInfo.stubbedIsSandbox = true

        let idfv = systemInfo.identifierForVendor!

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
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
        let headerPresent: Atomic<Bool> = .init(false)

        let idfv = systemInfo.identifierForVendor!

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }
    #endif

    func testDefaultsPlatformFlavorToNative() {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "native")) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: Dictionary.init(),
                                       headers: ["test_header": "value"],
                                       completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesPlatformFlavorHeader() throws {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "react-native")) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let platformInfo = Purchases.PlatformInfo(flavor: "react-native", version: "3.2.1")
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: true)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        client.performPOSTRequest(path: path,
                                  requestBody: Dictionary.init(),
                                  headers: ["test_header": "value"],
                                  completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesPlatformFlavorVersionHeader() throws {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform-Flavor-Version", value: "1.2.3")) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let platformInfo = Purchases.PlatformInfo(flavor: "react-native", version: "1.2.3")
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: true)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)

        client.performPOSTRequest(path: path,
                                  requestBody: Dictionary.init(),
                                  headers: ["test_header": "value"],
                                  completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenEnabled() throws {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "false")) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: true)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        client.performPOSTRequest(path: path,
                                  requestBody: Dictionary.init(),
                                  headers: ["test_header": "value"],
                                  completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenDisabled() throws {
        let path = "/a_random_path"
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "true")) { _ in
            headerPresent.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: false)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        client.performPOSTRequest(path: path,
                                  requestBody: Dictionary.init(),
                                  headers: ["test_header": "value"],
                                  completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPerformSerialRequestPerformsAllRequestsInTheCorrectOrder() {
        let path = "/a_random_path"
        let completionCallCount: Atomic<Int> = .init(0)

        stub(condition: isPath("/v1" + path)) { request in
            let requestNumber = self.extractRequestNumber(from: request)
            expect(requestNumber) == completionCallCount.value

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: nil)
                .responseTime(0.003)
        }

        let serialRequests = 10
        for requestNumber in 0..<serialRequests {
            client.performPOSTRequest(path: path,
                                      requestBody: ["requestNumber": requestNumber],
                                      headers: [:]) { (_, _, _) in
                completionCallCount.value += 1
            }
        }
        expect(completionCallCount.value).toEventually(equal(serialRequests), timeout: .seconds(5))
    }

    func testPerformSerialRequestWaitsUntilFirstRequestIsDoneBeforeStartingSecond() {
        let path = "/a_random_path"
        let firstRequestFinished: Atomic<Bool> = .init(false)
        let secondRequestFinished: Atomic<Bool> = .init(false)

        stub(condition: isPath("/v1" + path)) { request in
            usleep(30)
            let requestNumber = self.extractRequestNumber(from: request)
            if requestNumber == 2 {
                expect(firstRequestFinished.value) == true
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!, statusCode: 200, headers: nil)
                .responseTime(0.1)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: ["requestNumber": 1],
                                       headers: [:]) { (_, _, _) in
            firstRequestFinished.value = true
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: ["requestNumber": 2],
                                       headers: [:]) { (_, _, _) in
            secondRequestFinished.value = true
        }

        expect(firstRequestFinished.value).toEventually(beTrue())
        expect(secondRequestFinished.value).toEventually(beTrue())
    }

    func testPerformSerialRequestWaitsUntilRequestsAreDoneBeforeStartingNext() {
        let path = "/a_random_path"
        let firstRequestFinished: Atomic<Bool> = .init(false)
        let secondRequestFinished: Atomic<Bool> = .init(false)
        let thirdRequestFinished: Atomic<Bool> = .init(false)

        stub(condition: isPath("/v1" + path)) { request in
            let requestNumber = self.extractRequestNumber(from: request)
            var responseTime = 0.5
            if requestNumber == 1 {
                expect(secondRequestFinished.value) == false
                expect(thirdRequestFinished.value) == false
            } else if requestNumber == 2 {
                expect(firstRequestFinished.value) == true
                expect(thirdRequestFinished.value) == false
                responseTime = 0.3
            } else if requestNumber == 3 {
                expect(firstRequestFinished.value) == true
                expect(secondRequestFinished.value) == true
                responseTime = 0.1
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: nil)
                .responseTime(responseTime)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: ["requestNumber": 1],
                                       headers: [:]) { (_, _, _) in
            firstRequestFinished.value = true
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: ["requestNumber": 2],
                                       headers: [:]) { (_, _, _) in
            secondRequestFinished.value = true
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: ["requestNumber": 3],
                                       headers: [:]) { (_, _, _) in
            thirdRequestFinished.value = true
        }

        expect(firstRequestFinished.value).toEventually(beTrue(), timeout: .seconds(1))
        expect(secondRequestFinished.value).toEventually(beTrue(), timeout: .seconds(2))
        expect(thirdRequestFinished.value).toEventually(beTrue(), timeout: .seconds(3))
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
        self.client.performPOSTRequest(path: path,
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
        let httpCallMade: Atomic<Bool> = .init(false)

        stub(condition: isPath("/v1" + path)) { _ in
            httpCallMade.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.client.performPOSTRequest(path: path,
                                       requestBody: nonJSONBody,
                                       headers: [:]) { (_, _, _) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(httpCallMade.value).toEventually(beFalse())
    }

    func testRequestIsRetriedIfResponseFromETagManagerIsNil() {
        let path = "/a_random_path"
        let completionCalled: Atomic<Bool> = .init(false)

        let firstTimeCalled: Atomic<Bool> = .init(false)
        stub(condition: isPath("/v1" + path)) { _ in
            if firstTimeCalled.value {
                self.eTagManager.shouldReturnResultFromBackend = true
            }
            firstTimeCalled.value = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = nil
        self.client.performGETRequest(path: path,
                                      headers: [:]) { (_, _, _) in
            completionCalled.value = true
        }

        expect(completionCalled.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testDNSCheckerIsCalledWhenGETRequestFailedWithUnknownError() {
        let path = "/a_random_path"
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = false

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = error
            return response
        }

        self.client.performGETRequest(
            path: path,
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(false))
    }

    func testDNSCheckerIsCalledWhenPOSTRequestFailedWithUnknownError() {
        let path = "/a_random_path"
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = false

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = error
            return response
        }

        self.client.performPOSTRequest(
            path: path,
            requestBody: [:],
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(false))
    }

    func testDNSCheckedIsCalledWhenPOSTRequestFailedWithDNSError() {
        let path = "/a_random_path"
        let fakeSubscribersURL = URL(string: "https://0.0.0.0/subscribers")!
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL]
        let nsErrorWithUserInfo = NSError(domain: NSURLErrorDomain,
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = true

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = nsErrorWithUserInfo
            return response
        }

        self.client.performPOSTRequest(
            path: path,
            requestBody: [:],
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(true))
    }

    func testDNSCheckedIsCalledWhenGETRequestFailedWithDNSError() {
        let path = "/a_random_path"
        let fakeSubscribersURL = URL(string: "https://0.0.0.0/subscribers")!
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL]
        let nsErrorWithUserInfo = NSError(domain: NSURLErrorDomain,
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = true

        stub(condition: isPath("/v1" + path)) { _ in
            let response = HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
            response.error = nsErrorWithUserInfo
            return response
        }

        self.client.performGETRequest(
            path: path,
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(true))
    }

    func testErrorIsLoggedAndReturnsDNSErrorWhenGETRequestFailedWithDNSError() {
        let path = "/a_random_path"
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        let expectedDNSError = DNSError.blocked(
            failedURL: URL(string: "https://0.0.0.0/subscribers")!,
            resolvedHost: "0.0.0.0"
        )
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = true
        MockDNSChecker.stubbedErrorWithBlockedHostFromErrorResult.value = expectedDNSError
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

        let obtainedError: Atomic<DNSError?> = .init(nil)
        self.client.performGETRequest(
            path: path,
            headers: [:]) { _, _, error in
                obtainedError.value = error as? DNSError
            }

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(true))
        expect(obtainedError.value).toEventually(equal(expectedDNSError))
        expect(loggedMessages).toEventually(contain(expectedMessage))
    }

    func testErrorIsntLoggedWhenGETRequestFailedWithUnknownError() {
        let path = "/a_random_path"
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        let unexpectedDNSError = DNSError.blocked(
            failedURL: URL(string: "https://0.0.0.0/subscribers")!,
            resolvedHost: "0.0.0.0"
        )
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = false

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
            path: path,
            headers: [:],
            completionHandler: nil
        )

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(false))
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
