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

    func testUsesTheCorrectHost() throws {
        let hostCorrect: Atomic<Bool> = .init(false)

        let host = try XCTUnwrap(SystemInfo.serverHostURL.host)
        stub(condition: isHost(host)) { _ in
            hostCorrect.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .get, path: .mockPath)
        self.client.perform(request, authHeaders: [:], completionHandler: nil)

        expect(hostCorrect.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testPassesHeaders() {
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("test_header")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)
        self.client.perform(request,
                            authHeaders: ["test_header": "value"],
                            completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysSetsContentTypeHeader() {
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("content-type", value: "application/json")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysPassesPlatformHeader() {
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform", value: SystemInfo.platformHeader)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesVersionHeader() {
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Version", value: Purchases.frameworkVersion)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesPlatformVersion() {
        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform-Version", value: ProcessInfo().operatingSystemVersionString)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testCallsTheGivenPath() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let pathHit: Atomic<Bool> = .init(false)

        stub(condition: isPath(request.path)) { _ in
            pathHit.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request, authHeaders: [:], completionHandler: nil)

        expect(pathHit.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testSendsBodyData() throws {
        let body = ["arg": "value"]
        let pathHit: Atomic<Bool> = .init(false)

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        stub(condition: hasBody(bodyData)) { _ in
            pathHit.value = true
            return .emptySuccessResponse
        }
        let request = HTTPRequest(method: .post(body), path: .mockPath)

        self.client.perform(request, authHeaders: [:], completionHandler: nil)

        expect(pathHit.value).toEventually(equal(true))
    }

    func testCallsCompletionHandlerWhenFinished() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let completionCalled: Atomic<Bool> = .init(false)

        stub(condition: isPath(request.path)) { _ in
            return .emptySuccessResponse
        }

        self.client.perform(request, authHeaders: [:]) { _ in
            completionCalled.value = true
        }

        expect(completionCalled.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testHandlesRealErrorConditions() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let correctResult: Atomic<Bool?> = .init(nil)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        stub(condition: isPath(request.path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse
            response.error = error
            return response
        }
        self.client.perform(request, authHeaders: [:]) { result in
            if let responseNSError = result.error as NSError? {
                correctResult.value = (error.domain == responseNSError.domain
                                       && error.code == responseNSError.code)
            } else {
                correctResult.value = false
            }
        }

        expect(correctResult.value).toEventuallyNot(beNil())
        expect(correctResult.value) == true
    }

    func testServerSide400s() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let errorCode = HTTPStatusCode.invalidRequest.rawValue + Int.random(in: 0..<50)
        let result: Atomic<Result<HTTPResponse, Error>?> = .init(nil)

        stub(condition: isPath(request.path)) { _ in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.perform(request, authHeaders: [:]) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value?.value?.statusCode.rawValue) == errorCode
        expect(result.value?.value?.jsonObject["message"] as? String) == "something is broken up in the cloud"
    }

    func testServerSide500s() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let errorCode = 500 + Int.random(in: 0..<50)
        let result: Atomic<Result<HTTPResponse, Error>?> = .init(nil)

        stub(condition: isPath(request.path)) { _ in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.perform(request, authHeaders: [:]) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value?.value?.statusCode.rawValue) == errorCode
        expect(result.value?.value?.jsonObject["message"] as? String) == "something is broken up in the cloud"
    }

    func testParseError() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let errorCode = HTTPStatusCode.success.rawValue
        let result: Atomic<Result<HTTPResponse, Error>?> = .init(nil)

        stub(condition: isPath(request.path)) { _ in
            let json = "{this is not JSON.csdsd"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.perform(request, authHeaders: [:]) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value).to(beFailure())
    }

    func testServerSide200s() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let result: Atomic<Result<HTTPResponse, Error>?> = .init(nil)

        stub(condition: isPath(request.path)) { _ in
            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!,
                                     statusCode: .success,
                                     headers: nil)
        }

        self.client.perform(request, authHeaders: [:]) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value).to(beSuccess())
        expect(result.value?.value?.jsonObject["message"] as? String) == "something is great up in the cloud"
    }

    func testAlwaysPassesClientVersion() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = .init(false)

        let version = SystemInfo.appVersion

        stub(condition: hasHeaderNamed("X-Client-Version", value: version )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesClientBuildVersion() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = .init(false)

        let version = try XCTUnwrap(Bundle.main.infoDictionary!["CFBundleVersion"] as? String)

        stub(condition: hasHeaderNamed("X-Client-Build-Version", value: version )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    #if os(macOS) || targetEnvironment(macCatalyst)
    func testAlwaysPassesAppleDeviceIdentifierWhenIsSandbox() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let headerPresent: Atomic<Bool> = .init(false)
        systemInfo.stubbedIsSandbox = true

        let idfv = systemInfo.identifierForVendor!

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAppleDeviceIdentifierNilWhenIsNotSandbox() {
        systemInfo.stubbedIsSandbox = false

        let obtainedIdentifierForVendor = systemInfo.identifierForVendor

        expect(obtainedIdentifierForVendor).to(beNil())
    }

    #else

    func testAlwaysPassesAppleDeviceIdentifier() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = .init(false)

        let idfv = systemInfo.identifierForVendor!

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }
    #endif

    func testDefaultsPlatformFlavorToNative() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "native")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesPlatformFlavorHeader() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "react-native")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }
        let platformInfo = Purchases.PlatformInfo(flavor: "react-native", version: "3.2.1")
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: true)

        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesPlatformFlavorVersionHeader() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Platform-Flavor-Version", value: "1.2.3")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }
        let platformInfo = Purchases.PlatformInfo(flavor: "react-native", version: "1.2.3")
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: true)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)

        client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenEnabled() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "false")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }
        let systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: true)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)

        client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenDisabled() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = .init(false)

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "true")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }
        let systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: false)
        let client = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)

        client.perform(request, authHeaders: ["test_header": "value"], completionHandler: nil)

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPerformSerialRequestPerformsAllRequestsInTheCorrectOrder() {
        let path: HTTPRequest.Path = .mockPath

        let completionCallCount: Atomic<Int> = .init(0)

        stub(condition: isPath(path)) { request in
            let requestNumber = self.extractRequestNumber(from: request)
            expect(requestNumber) == completionCallCount.value

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: .utf8)!,
                                     statusCode: .success,
                                     headers: nil)
                .responseTime(0.003)
        }

        let serialRequests = 10
        for requestNumber in 0..<serialRequests {
            client.perform(.init(method: .requestNumber(requestNumber), path: path),
                           authHeaders: [:]) { _ in
                completionCallCount.value += 1
            }
        }
        expect(completionCallCount.value).toEventually(equal(serialRequests), timeout: .seconds(5))
    }

    func testPerformSerialRequestWaitsUntilFirstRequestIsDoneBeforeStartingSecond() {
        let path: HTTPRequest.Path = .mockPath

        let firstRequestFinished: Atomic<Bool> = .init(false)
        let secondRequestFinished: Atomic<Bool> = .init(false)

        stub(condition: isPath(path)) { request in
            usleep(30)
            let requestNumber = self.extractRequestNumber(from: request)
            if requestNumber == 2 {
                expect(firstRequestFinished.value) == true
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!,
                                     statusCode: .success,
                                     headers: nil)
                .responseTime(0.1)
        }

        self.client.perform(.init(method: .requestNumber(1), path: path),
                            authHeaders: [:]) { _ in
            firstRequestFinished.value = true
        }

        self.client.perform(.init(method: .requestNumber(2), path: path),
                            authHeaders: [:]) { _ in
            secondRequestFinished.value = true
        }

        expect(firstRequestFinished.value).toEventually(beTrue())
        expect(secondRequestFinished.value).toEventually(beTrue())
    }

    func testPerformSerialRequestWaitsUntilRequestsAreDoneBeforeStartingNext() {
        let path: HTTPRequest.Path = .mockPath

        let firstRequestFinished: Atomic<Bool> = .init(false)
        let secondRequestFinished: Atomic<Bool> = .init(false)
        let thirdRequestFinished: Atomic<Bool> = .init(false)

        stub(condition: isPath(path)) { request in
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
            return HTTPStubsResponse(data: json.data(using: .utf8)!,
                                     statusCode: .success,
                                     headers: nil)
                .responseTime(responseTime)
        }

        self.client.perform(.init(method: .requestNumber(1), path: path),
                            authHeaders: [:]) { _ in
            firstRequestFinished.value = true
        }

        self.client.perform(.init(method: .requestNumber(2), path: path),
                            authHeaders: [:]) { _ in
            secondRequestFinished.value = true
        }

        self.client.perform(.init(method: .requestNumber(3), path: path),
                            authHeaders: [:]) { _ in
            thirdRequestFinished.value = true
        }

        expect(firstRequestFinished.value).toEventually(beTrue(), timeout: .seconds(1))
        expect(secondRequestFinished.value).toEventually(beTrue(), timeout: .seconds(2))
        expect(thirdRequestFinished.value).toEventually(beTrue(), timeout: .seconds(3))
    }

    func testPerformRequestExitsWithErrorIfBodyCouldntBeParsedIntoJSON() throws {
        let response: Atomic<Result<HTTPResponse, Error>?> = .init(nil)

        self.client.perform(.init(method: .invalidBody(), path: .mockPath),
                            authHeaders: [:]) {
            response.value = $0
        }

        expect(response).toEventuallyNot(beNil())

        let receivedNSError = try XCTUnwrap(response.value?.error as NSError?)
        expect(receivedNSError.code) == ErrorCode.networkError.rawValue
    }

    func testPerformRequestDoesntPerformRequestIfBodyCouldntBeParsedIntoJSON() {
        let path: HTTPRequest.Path = .mockPath

        let completionCalled: Atomic<Bool> = .init(false)
        let httpCallMade: Atomic<Bool> = .init(false)

        stub(condition: isPath(path)) { _ in
            httpCallMade.value = true
            return .emptySuccessResponse
        }

        self.client.perform(.init(method: .invalidBody(), path: path),
                            authHeaders: [:]) { _ in
            completionCalled.value = true
        }

        expect(completionCalled.value).toEventually(beTrue())
        expect(httpCallMade.value).toEventually(beFalse())
    }

    func testRequestIsRetriedIfResponseFromETagManagerIsNil() {
        let path: HTTPRequest.Path = .mockPath

        let completionCalled: Atomic<Bool> = .init(false)

        let firstTimeCalled: Atomic<Bool> = .init(false)
        stub(condition: isPath(path)) { _ in
            if firstTimeCalled.value {
                self.eTagManager.shouldReturnResultFromBackend = true
            }
            firstTimeCalled.value = true
            return .emptySuccessResponse
        }

        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = nil
        self.client.perform(.init(method: .get, path: path), authHeaders: [:]) { _ in
            completionCalled.value = true
        }

        expect(completionCalled.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testGetsResponseFromETagManagerWhenStatusCodeIsNotModified() {
        let path: HTTPRequest.Path = .mockPath

        let mockedCachedResponse: [String: String] = [
            "test": "data"
        ]

        let response: Atomic<Result<HTTPResponse, Error>?> = .init(nil)

        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = .init(
            statusCode: .success,
            jsonObject: mockedCachedResponse
        )

        stub(condition: isPath(path)) { _ in
            return .init(data: Data(),
                         statusCode: .notModified,
                         headers: nil)
        }

        self.client.perform(.init(method: .get, path: path), authHeaders: [:]) {
            response.value = $0
        }

        expect(response.value).toEventuallyNot(beNil(), timeout: .seconds(1))

        expect(response.value?.value?.statusCode) == .success
        expect(response.value?.value?.jsonObject as? [String: String]) == mockedCachedResponse
    }

    func testDNSCheckerIsCalledWhenGETRequestFailedWithUnknownError() {
        let path: HTTPRequest.Path = .mockPath

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = false

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse
            response.error = error
            return response
        }

        self.client.perform(.init(method: .get, path: path), authHeaders: [:], completionHandler: nil)

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(false))
    }

    func testDNSCheckerIsCalledWhenPOSTRequestFailedWithUnknownError() {
        let path: HTTPRequest.Path = .mockPath

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = false

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse
            response.error = error
            return response
        }

        self.client.perform(.init(method: .post([:]), path: path), authHeaders: [:], completionHandler: nil)

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(false))
    }

    func testDNSCheckedIsCalledWhenPOSTRequestFailedWithDNSError() {
        let path: HTTPRequest.Path = .mockPath

        let fakeSubscribersURL = URL(string: "https://0.0.0.0/subscribers")!
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL]
        let nsErrorWithUserInfo = NSError(domain: NSURLErrorDomain,
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = true

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse
            response.error = nsErrorWithUserInfo
            return response
        }

        self.client.perform(.init(method: .post([:]), path: path), authHeaders: [:], completionHandler: nil)

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(true))
    }

    func testDNSCheckedIsCalledWhenGETRequestFailedWithDNSError() {
        let path: HTTPRequest.Path = .mockPath

        let fakeSubscribersURL = URL(string: "https://0.0.0.0/subscribers")!
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL]
        let nsErrorWithUserInfo = NSError(domain: NSURLErrorDomain,
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = true

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse
            response.error = nsErrorWithUserInfo
            return response
        }

        self.client.perform(.init(method: .get, path: path), authHeaders: [:], completionHandler: nil)

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(true))
    }

    func testErrorIsLoggedAndReturnsDNSErrorWhenGETRequestFailedWithDNSError() {
        let path: HTTPRequest.Path = .mockPath

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

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse
            response.error = error
            return response
        }

        let obtainedError: Atomic<DNSError?> = .init(nil)
        self.client.perform(.init(method: .get, path: path), authHeaders: [:] ) { result in
            obtainedError.value = result.error as? DNSError
        }

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(true))
        expect(obtainedError.value).toEventually(equal(expectedDNSError))
        expect(loggedMessages).toEventually(contain(expectedMessage))
    }

    func testErrorIsntLoggedWhenGETRequestFailedWithUnknownError() {
        let path: HTTPRequest.Path = .mockPath

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

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse
            response.error = error
            return response
        }

        self.client.perform(.init(method: .get, path: path), authHeaders: [:], completionHandler: nil)

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(false))
        expect(loggedMessages).toNotEventually(contain(unexpectedDNSError.description))
        Logger.logHandler = originalLogHandler
    }

}

// MARK: - Extensions

private extension HTTPRequest.Path {

    // Doesn't matter which path this is, we stub requests to it.
    static let mockPath: Self = .logIn

}

extension HTTPRequest.Method {

    fileprivate static func requestNumber(_ number: Int) -> Self {
        return .post([HTTPClientTests.requestNumberKeyName: number])
    }

    fileprivate static func invalidBody() -> Self {
        // infinity can't be cast into JSON, so we use it to force a parsing exception. See:
        // https://developer.apple.com/documentation/foundation/nsjsonserialization?language=objc
        let nonJSONBody = ["something": Double.infinity]

        return .post(nonJSONBody)
    }

    /// Creates a `HTTPRequest.Method.post` request with `[String: Any]`.
    /// - Note: this is for testing only, real requests must use `Encodable`.
    internal static func post(_ body: [String: Any]) -> Self {
        return .post(AnyEncodable(body))
    }

}

private extension HTTPClientTests {

    func extractRequestNumber(from urlRequest: URLRequest) -> Int? {
        do {
            let requestData = urlRequest.ohhttpStubs_httpBody!
            let requestBodyDict = try XCTUnwrap(try JSONSerialization.jsonObject(with: requestData,
                                                                                 options: []) as? [String: Any])
            return try XCTUnwrap(requestBodyDict[Self.requestNumberKeyName] as? Int)
        } catch {
            XCTFail("Couldn't extract the request number from the URLRequest")
            return nil
        }
    }

    static let requestNumberKeyName = "request_number"

}

private func isPath(_ path: HTTPRequest.Path) -> HTTPStubsTestBlock {
    return isPath(path.relativePath)
}

private extension HTTPStubsResponse {

    static let emptySuccessResponse: HTTPStubsResponse = .init(data: Data(),
                                                               statusCode: .success,
                                                               headers: nil)

    convenience init(data: Data, statusCode: HTTPStatusCode, headers: HTTPClient.RequestHeaders?) {
        self.init(data: data, statusCode: Int32(statusCode.rawValue), headers: headers)
    }

}
