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

class HTTPClientTests: TestCase {

    private typealias EmptyResponse = HTTPResponse<HTTPEmptyResponseBody>.Result
    let apiKey = "MockAPIKey"
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

        client = HTTPClient(apiKey: apiKey,
                            systemInfo: systemInfo,
                            eTagManager: eTagManager,
                            dnsChecker: MockDNSChecker.self,
                            requestTimeout: 3)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()

        super.tearDown()
    }

    func testUsesTheCorrectHost() throws {
        let hostCorrect: Atomic<Bool> = false

        let host = try XCTUnwrap(SystemInfo.serverHostURL.host)
        stub(condition: isHost(host)) { _ in
            hostCorrect.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .get, path: .mockPath)
        self.client.perform(request) { (_: EmptyResponse) in }

        expect(hostCorrect.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testPassesHeaders() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("Authorization")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)
        self.client.perform(request) { (_: EmptyResponse) in }

        expect(headerPresent.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysSetsContentTypeHeader() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("content-type", value: "application/json")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request) { (_: EmptyResponse) in }

        expect(headerPresent.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testAlwaysPassesPlatformHeader() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform", value: SystemInfo.platformHeader)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request) { (_: EmptyResponse) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesVersionHeader() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Version", value: Purchases.frameworkVersion)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request) { (_: EmptyResponse) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesPlatformVersion() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform-Version", value: ProcessInfo().operatingSystemVersionString)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request) { (_: EmptyResponse) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesIsSandboxWhenEnabled() {
        let headerName = "X-Is-Sandbox"
        self.systemInfo.stubbedIsSandbox = true

        let header: Atomic<String?> = nil

        stub(condition: hasHeaderNamed(headerName)) { request in
            header.value = request.value(forHTTPHeaderField: headerName)
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request) { (_: EmptyResponse) in }

        expect(header.value).toEventuallyNot(beNil())
        expect(header.value) == "true"
    }

    func testAlwaysPassesIsSandboxWhenDisabled() {
        let headerName = "X-Is-Sandbox"
        self.systemInfo.stubbedIsSandbox = false

        let header: Atomic<String?> = nil

        stub(condition: hasHeaderNamed(headerName)) { request in
            header.value = request.value(forHTTPHeaderField: headerName)
            return .emptySuccessResponse
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        self.client.perform(request) { (_: EmptyResponse) in }

        expect(header.value).toEventuallyNot(beNil())
        expect(header.value) == "false"
    }

    func testCallsTheGivenPath() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let pathHit: Atomic<Bool> = false

        stub(condition: isPath(request.path)) { _ in
            pathHit.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request) { (_: EmptyResponse) in }

        expect(pathHit.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testSendsBodyData() throws {
        let body = ["arg": "value"]
        let pathHit: Atomic<Bool> = false

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        stub(condition: hasBody(bodyData)) { _ in
            pathHit.value = true
            return .emptySuccessResponse
        }
        let request = HTTPRequest(method: .post(body), path: .mockPath)

        self.client.perform(request) { (_: EmptyResponse) in }

        expect(pathHit.value).toEventually(equal(true))
    }

    func testCallsCompletionHandlerWhenFinished() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let completionCalled: Atomic<Bool> = false

        stub(condition: isPath(request.path)) { _ in
            return .emptySuccessResponse
        }

        self.client.perform(request) { (_: EmptyResponse) in
            completionCalled.value = true
        }

        expect(completionCalled.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testHandlesRealErrorConditions() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let receivedError: Atomic<NetworkError?> = nil
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        stub(condition: isPath(request.path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse
            response.error = error
            return response
        }
        self.client.perform(request) { (result: EmptyResponse) in
            receivedError.value = result.error
        }

        expect(receivedError.value).toEventuallyNot(beNil())

        switch receivedError.value {
        case let .networkError(actualError, _):
            expect(actualError.domain) == error.domain
            expect(actualError.code) == error.code
        default:
            fail("Unexpected error: \(String(describing: receivedError.value))")
        }
    }

    func testServerSide400s() throws {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let errorCode = HTTPStatusCode.invalidRequest.rawValue + Int.random(in: 0..<50)
        let result: Atomic<HTTPResponse<Data>.Result?> = nil

        stub(condition: isPath(request.path)) { _ in
            let json = "{\"code\": 7101, \"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.perform(request) { (response: HTTPResponse<Data>.Result) in
            result.value = response
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value).to(beFailure())

        let error = try XCTUnwrap(result.value?.error)
        expect(error) == .errorResponse(
            .init(code: .storeProblem, message: "something is broken up in the cloud"),
            HTTPStatusCode(rawValue: errorCode)
        )
    }

    func testServerSide500s() throws {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let errorCode = 500 + Int.random(in: 0..<50)
        let result: Atomic<HTTPResponse<Data>.Result?> = nil

        stub(condition: isPath(request.path)) { _ in
            let json = "{\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.perform(request) { (response: HTTPResponse<Data>.Result) in
            result.value = response
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value).to(beFailure())

        let error = try XCTUnwrap(result.value?.error)
        expect(error) == .errorResponse(
            .init(code: .unknownBackendError, message: "something is broken up in the cloud"),
            HTTPStatusCode(rawValue: errorCode)
        )
    }

    func testInvalidJSONAsDataDoesNotFail() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let statusCode = HTTPStatusCode.success
        let data = "{this is not JSON.csdsd".data(using: String.Encoding.utf8)!

        let result: Atomic<HTTPResponse<Data>.Result?> = nil

        stub(condition: isPath(request.path)) { _ in
            return HTTPStubsResponse(
                data: data,
                statusCode: Int32(statusCode.rawValue),
                headers: nil
            )
        }

        self.client.perform(request) { (response: HTTPResponse<Data>.Result) in
            result.value = response
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value).to(beSuccess())
        expect(result.value?.value?.body) == data
    }

    func testParseError() throws {
        struct CustomResponse: Decodable, HTTPResponseBody {
            let data: String
        }

        let request = HTTPRequest(method: .get, path: .mockPath)

        let errorCode = HTTPStatusCode.success.rawValue
        let result: Atomic<HTTPResponse<CustomResponse>.Result?> = nil

        stub(condition: isPath(request.path)) { _ in
            let json = "{this is not JSON.csdsd"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        self.client.perform(request) { (response: HTTPResponse<CustomResponse>.Result) in
            result.value = response
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value).to(beFailure())

        let error = try XCTUnwrap(result.value?.error)
        switch error {
        case .decoding:
            break // correct error

        default:
            fail("Invalid error: \(error)")
        }
    }

    func testServerSide200s() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let responseData = "{\"message\": \"something is great up in the cloud\"}".data(using: String.Encoding.utf8)!

        let result: Atomic<HTTPResponse<Data>.Result?> = nil

        stub(condition: isPath(request.path)) { _ in
            return HTTPStubsResponse(data: responseData,
                                     statusCode: .success,
                                     headers: nil)
        }

        self.client.perform(request) { (response: HTTPResponse<Data>.Result) in
            result.value = response
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value).to(beSuccess())
        expect(result.value?.value?.body) == responseData
    }

    func testResponseDeserialization() throws {
        struct CustomResponse: Codable, Equatable, HTTPResponseBody {
            let message: String
        }

        let request = HTTPRequest(method: .get, path: .mockPath)

        let response = CustomResponse(message: "Something is great up in the cloud")
        let responseData = try JSONEncoder.default.encode(response)

        let result: Atomic<HTTPResponse<CustomResponse>.Result?> = nil

        stub(condition: isPath(request.path)) { _ in
            return HTTPStubsResponse(data: responseData,
                                     statusCode: .success,
                                     headers: nil)
        }

        self.client.perform(request) { (response: HTTPResponse<CustomResponse>.Result) in
            result.value = response
        }

        expect(result.value).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(result.value).to(beSuccess())
        expect(result.value?.value?.body) == response
        expect(result.value?.value?.statusCode) == .success
    }

    func testAlwaysPassesClientVersion() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        let version = SystemInfo.appVersion

        stub(condition: hasHeaderNamed("X-Client-Version", value: version )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request) { (_: HTTPResponse<Data>.Result) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testAlwaysPassesClientBuildVersion() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        let version = try XCTUnwrap(Bundle.main.infoDictionary!["CFBundleVersion"] as? String)

        stub(condition: hasHeaderNamed("X-Client-Build-Version", value: version )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request) { (_: HTTPResponse<Data>.Result) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    #if os(macOS) || targetEnvironment(macCatalyst)
    func testAlwaysPassesAppleDeviceIdentifierWhenIsSandbox() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let headerPresent: Atomic<Bool> = false
        systemInfo.stubbedIsSandbox = true

        let idfv = systemInfo.identifierForVendor!

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request) { (_: HTTPResponse<Data>.Result) in }

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

        let headerPresent: Atomic<Bool> = false

        let idfv = systemInfo.identifierForVendor!

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

            self.client.perform(request) { (_: HTTPResponse<Data>.Result) in }

        expect(headerPresent.value).toEventually(equal(true))
    }
    #endif

    func testDefaultsPlatformFlavorToNative() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "native")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }

        self.client.perform(request) { (_: HTTPResponse<Data>.Result) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesPlatformFlavorHeader() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "react-native")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }
        let platformInfo = Purchases.PlatformInfo(flavor: "react-native", version: "3.2.1")
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: true)

        let client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: eTagManager)
        client.perform(request) { (_: HTTPResponse<Data>.Result) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesPlatformFlavorVersionHeader() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor-Version", value: "1.2.3")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }
        let platformInfo = Purchases.PlatformInfo(flavor: "react-native", version: "1.2.3")
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: true)
        let client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: eTagManager)

        client.perform(request) { (_: HTTPResponse<Data>.Result) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenEnabled() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "false")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }
        let systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: true)
        let client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: eTagManager)

        client.perform(request) { (_: HTTPResponse<Data>.Result) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPassesObserverModeHeaderCorrectlyWhenDisabled() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "true")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse
        }
        let systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: false)
        let client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: eTagManager)

        client.perform(request) { (_: HTTPResponse<Data>.Result) in }

        expect(headerPresent.value).toEventually(equal(true))
    }

    func testPerformSerialRequestPerformsAllRequestsInTheCorrectOrder() {
        let path: HTTPRequest.Path = .mockPath

        let completionCallCount: Atomic<Int> = .init(0)

        stub(condition: isPath(path)) { request in
            let requestNumber = self.extractRequestNumber(from: request)
            expect(requestNumber) == completionCallCount.value

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.asData,
                                     statusCode: .success,
                                     headers: nil)
                .responseTime(0.003)
        }

        let serialRequests = 10
        for requestNumber in 0..<serialRequests {
            client.perform(.init(method: .requestNumber(requestNumber), path: path)) { (_: HTTPResponse<Data>.Result) in
                completionCallCount.value += 1
            }
        }
        expect(completionCallCount.value).toEventually(equal(serialRequests), timeout: .seconds(5))
    }

    func testPerformSerialRequestWaitsUntilFirstRequestIsDoneBeforeStartingSecond() {
        let path: HTTPRequest.Path = .mockPath

        let firstRequestFinished: Atomic<Bool> = false
        let secondRequestFinished: Atomic<Bool> = false

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

        self.client.perform(.init(method: .requestNumber(1), path: path)) { (_: HTTPResponse<Data>.Result) in
            firstRequestFinished.value = true
        }

        self.client.perform(.init(method: .requestNumber(2), path: path)) { (_: HTTPResponse<Data>.Result) in
            secondRequestFinished.value = true
        }

        expect(firstRequestFinished.value).toEventually(beTrue())
        expect(secondRequestFinished.value).toEventually(beTrue())
    }

    func testPerformSerialRequestWaitsUntilRequestsAreDoneBeforeStartingNext() {
        let path: HTTPRequest.Path = .mockPath

        let firstRequestFinished: Atomic<Bool> = false
        let secondRequestFinished: Atomic<Bool> = false
        let thirdRequestFinished: Atomic<Bool> = false

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
            return HTTPStubsResponse(data: json.asData,
                                     statusCode: .success,
                                     headers: nil)
                .responseTime(responseTime)
        }

        self.client.perform(.init(method: .requestNumber(1), path: path)) { (_: HTTPResponse<Data>.Result) in
            firstRequestFinished.value = true
        }

        self.client.perform(.init(method: .requestNumber(2), path: path)) { (_: HTTPResponse<Data>.Result) in
            secondRequestFinished.value = true
        }

        self.client.perform(.init(method: .requestNumber(3), path: path)) { (_: HTTPResponse<Data>.Result) in
            thirdRequestFinished.value = true
        }

        expect(firstRequestFinished.value).toEventually(beTrue(), timeout: .seconds(1))
        expect(secondRequestFinished.value).toEventually(beTrue(), timeout: .seconds(2))
        expect(thirdRequestFinished.value).toEventually(beTrue(), timeout: .seconds(3))
    }

    func testPerformRequestExitsWithErrorIfBodyCouldntBeParsedIntoJSON() throws {
        let response: Atomic<HTTPResponse<Data>.Result?> = nil

        self.client.perform(.init(method: .invalidBody(), path: .mockPath)) { (result: HTTPResponse<Data>.Result) in
            response.value = result
        }

        expect(response).toEventuallyNot(beNil())

        let error = try XCTUnwrap(response.value?.error)
        expect(error) == .unableToCreateRequest(.mockPath)
    }

    func testPerformRequestDoesntPerformRequestIfBodyCouldntBeParsedIntoJSON() {
        let path: HTTPRequest.Path = .mockPath

        let completionCalled: Atomic<Bool> = false
        let httpCallMade: Atomic<Bool> = false

        stub(condition: isPath(path)) { _ in
            httpCallMade.value = true
            return .emptySuccessResponse
        }

        self.client.perform(.init(method: .invalidBody(), path: path)) { (_: HTTPResponse<Data>.Result) in
            completionCalled.value = true
        }

        expect(completionCalled.value).toEventually(beTrue())
        expect(httpCallMade.value).toEventually(beFalse())
    }

    func testRequestIsRetriedIfResponseFromETagManagerIsNil() {
        let path: HTTPRequest.Path = .mockPath

        let completionCalled: Atomic<Bool> = false

        let firstTimeCalled: Atomic<Bool> = false
        stub(condition: isPath(path)) { _ in
            if firstTimeCalled.value {
                self.eTagManager.shouldReturnResultFromBackend = true
            }
            firstTimeCalled.value = true
            return .emptySuccessResponse
        }

        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = nil
        self.client.perform(.init(method: .get, path: path)) { (_: HTTPResponse<Data>.Result) in
            completionCalled.value = true
        }

        expect(completionCalled.value).toEventually(equal(true), timeout: .seconds(1))
    }

    func testGetsResponseFromETagManagerWhenStatusCodeIsNotModified() throws {
        let path: HTTPRequest.Path = .mockPath

        let mockedCachedResponse = try JSONSerialization.data(withJSONObject: [
            "test": "data"
        ])

        let response: Atomic<HTTPResponse<Data>.Result?> = nil

        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = .init(
            statusCode: .success,
            body: mockedCachedResponse
        )

        stub(condition: isPath(path)) { _ in
            return .init(data: Data(),
                         statusCode: .notModified,
                         headers: nil)
        }

        self.client.perform(.init(method: .get, path: path)) { (result: HTTPResponse<Data>.Result) in
            response.value = result
        }

        expect(response.value).toEventuallyNot(beNil(), timeout: .seconds(1))

        expect(response.value?.value?.statusCode) == .success
        expect(response.value?.value?.body) == mockedCachedResponse
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

        self.client.perform(.init(method: .get, path: path)) { (_: HTTPResponse<Data>.Result) in }

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

        self.client.perform(.init(method: .post([:]), path: path)) { (_: HTTPResponse<Data>.Result) in
        }

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

        self.client.perform(.init(method: .post([:]), path: path)) { (_: HTTPResponse<Data>.Result) in
        }

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

        self.client.perform(.init(method: .get, path: path)) { (_: HTTPResponse<Data>.Result) in }

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(true))
    }

    func testOfflineConnectionError() {
        let path: HTTPRequest.Path = .mockPath

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse
            response.error = error
            return response
        }

        let obtainedError: Atomic<NetworkError?> = nil
        self.client.perform(.init(method: .get, path: path)) { (result: HTTPResponse<Data>.Result) in
            obtainedError.value = result.error
        }

        expect(obtainedError.value).toEventuallyNot(beNil())
        expect(obtainedError.value) == .offlineConnection()
    }

    func testErrorIsLoggedAndReturnsDNSErrorWhenGETRequestFailedWithDNSError() {
        let path: HTTPRequest.Path = .mockPath

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        let expectedDNSError: NetworkError = .dnsError(
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

        let obtainedError: Atomic<NetworkError?> = nil
        self.client.perform(.init(method: .get, path: path)) { (result: HTTPResponse<Data>.Result) in
            obtainedError.value = result.error
        }

        expect(MockDNSChecker.invokedIsBlockedAPIError.value).toEventually(equal(true))
        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value).toEventually(equal(true))
        expect(obtainedError.value).toEventually(equal(expectedDNSError))
        expect(loggedMessages).toEventually(contain(expectedMessage))
    }

    func testErrorIsntLoggedWhenGETRequestFailedWithUnknownError() {
        let path: HTTPRequest.Path = .mockPath

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        let unexpectedDNSError: NetworkError = .dnsError(
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

        self.client.perform(.init(method: .get, path: path)) { (_: HTTPResponse<Data>.Result) in }

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
