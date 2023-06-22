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

class BaseHTTPClientTests: TestCase {

    typealias EmptyResponse = VerifiedHTTPResponse<HTTPEmptyResponseBody>.Result
    typealias DataResponse = VerifiedHTTPResponse<Data>.Result
    typealias BodyWithDateResponse = VerifiedHTTPResponse<BodyWithDate>.Result

    var systemInfo: MockSystemInfo!
    var client: HTTPClient!
    var eTagManager: MockETagManager!
    var operationDispatcher: OperationDispatcher!

    fileprivate let apiKey = "MockAPIKey"

    override func setUpWithError() throws {
        try super.setUpWithError()

        #if os(watchOS)
        // See https://github.com/AliSoftware/OHHTTPStubs/issues/287
        try XCTSkipIf(true, "OHHTTPStubs does not currently support watchOS")
        #endif

        self.systemInfo = MockSystemInfo(finishTransactions: true)
        self.eTagManager = MockETagManager()
        self.operationDispatcher = OperationDispatcher()
        MockDNSChecker.resetData()
        MockSigning.resetData()

        self.client = self.createClient()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()

        super.tearDown()
    }

    final func createClient() -> HTTPClient {
        return HTTPClient(apiKey: self.apiKey,
                          systemInfo: self.systemInfo,
                          eTagManager: self.eTagManager,
                          dnsChecker: MockDNSChecker.self,
                          signing: MockSigning.self,
                          requestTimeout: 3)
    }

}

final class HTTPClientTests: BaseHTTPClientTests {

    func testUsesTheCorrectHost() throws {
        let hostCorrect: Atomic<Bool> = false

        let host = try XCTUnwrap(SystemInfo.serverHostURL.host)
        stub(condition: isHost(host)) { _ in
            hostCorrect.value = true
            return .emptySuccessResponse()
        }

        let request = HTTPRequest(method: .get, path: .mockPath)

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(hostCorrect.value) == true
    }

    func testPassesHeaders() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("Authorization")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testRequestWithNoNonceDoesNotContainNonceHeader() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let headers: [String: String]? = waitUntilValue { completion in
            stub(condition: isPath(request.path)) { request in
                completion(request.allHTTPHeaderFields)
                return .emptySuccessResponse()
            }

            self.client.perform(request) { (_: EmptyResponse) in }
        }

        expect(headers).toNot(beEmpty())
        expect(headers?.keys).toNot(contain(HTTPClient.RequestHeader.nonce.rawValue))
    }

    func testRequestIncludesNonceInBase64() {
        let request = HTTPRequest(method: .get, path: .mockPath, nonce: "1234567890ab".asData)

        let headers: [String: String]? = waitUntilValue { completion in
            stub(condition: isPath(request.path)) { request in
                completion(request.allHTTPHeaderFields)
                return .emptySuccessResponse()
            }

            self.client.perform(request) { (_: EmptyResponse) in }
        }

        expect(headers).toNot(beEmpty())
        expect(headers?.keys).to(contain(HTTPClient.RequestHeader.nonce.rawValue))
        expect(headers?[HTTPClient.RequestHeader.nonce.rawValue]) == "MTIzNDU2Nzg5MGFi"
    }

    func testAlwaysSetsContentTypeHeader() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("content-type", value: "application/json")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testAlwaysPassesPlatformHeader() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform", value: SystemInfo.platformHeader)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testAlwaysPassesVersionHeader() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Version", value: Purchases.frameworkVersion)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testAlwaysPassesPlatformVersion() {
        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform-Version", value: ProcessInfo().operatingSystemVersionString)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testAlwaysPassesIsSandboxWhenEnabled() {
        let headerName = "X-Is-Sandbox"
        self.systemInfo.stubbedIsSandbox = true

        let header: Atomic<String?> = nil

        stub(condition: hasHeaderNamed(headerName)) { request in
            header.value = request.value(forHTTPHeaderField: headerName)
            return .emptySuccessResponse()
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(header.value) == "true"
    }

    func testAlwaysPassesIsSandboxWhenDisabled() {
        let headerName = "X-Is-Sandbox"
        self.systemInfo.stubbedIsSandbox = false

        let header: Atomic<String?> = nil

        stub(condition: hasHeaderNamed(headerName)) { request in
            header.value = request.value(forHTTPHeaderField: headerName)
            return .emptySuccessResponse()
        }

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(header.value) == "false"
    }

    func testCallsTheGivenPath() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let pathHit: Atomic<Bool> = false

        stub(condition: isPath(request.path)) { _ in
            pathHit.value = true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(pathHit.value) == true
    }

    func testSendsBodyData() throws {
        let body = ["arg": "value"]
        let pathHit: Atomic<Bool> = false

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        stub(condition: hasBody(bodyData)) { _ in
            pathHit.value = true
            return .emptySuccessResponse()
        }
        let request = HTTPRequest(method: .post(body), path: .mockPath)

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(pathHit.value) == true
    }

    func testCallsCompletionHandlerWhenFinished() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        stub(condition: isPath(request.path)) { _ in
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in
                completion()
            }
        }
    }

    func testHandlesRealErrorConditions() {
        let request = HTTPRequest(method: .get, path: .mockPath)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        stub(condition: isPath(request.path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse()
            response.error = error
            return response
        }
        let receivedError = waitUntilValue { completion in
            self.client.perform(request) { (result: EmptyResponse) in
                completion(result.error)
            }
        }

        expect(receivedError).toNot(beNil())
        expect(receivedError?.isServerDown) == false

        switch receivedError {
        case let .networkError(actualError, _):
            expect(actualError.domain) == error.domain
            expect(actualError.code) == error.code
        default:
            fail("Unexpected error: \(String(describing: receivedError))")
        }
    }

    func testServerSide400s() throws {
        let request = HTTPRequest(method: .get, path: .mockPath)
        let errorCode = HTTPStatusCode.invalidRequest.rawValue + Int.random(in: 0..<50)

        stub(condition: isPath(request.path)) { _ in
            let json = "{\"code\": 7101, \"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: [
                    HTTPClient.ResponseHeader.contentType.rawValue: "application/json"
                ]
            )
        }

        let result = waitUntilValue { completion in
            self.client.perform(request) { (response: DataResponse) in
                completion(response)
            }
        }

        expect(result).toNot(beNil())
        expect(result).to(beFailure())

        let error = try XCTUnwrap(result?.error)
        expect(error) == .errorResponse(
            .init(code: .storeProblem,
                  originalCode: 7101,
                  message: "something is broken up in the cloud"),
            HTTPStatusCode(rawValue: errorCode)
        )
        expect(error.isServerDown) == false

        expect(MockSigning.requests).to(beEmpty())
    }

    func testServerSide500sWithErrorResponse() throws {
        let request = HTTPRequest(method: .get, path: .mockPath)
        let errorCode = 500 + Int.random(in: 0..<50)

        stub(condition: isPath(request.path)) { _ in
            let json = "{\"code\": 5000,\"message\": \"something is broken up in the cloud\"}"
            return HTTPStubsResponse(
                data: json.asData,
                statusCode: Int32(errorCode),
                headers: [
                    HTTPClient.ResponseHeader.contentType.rawValue: "application/json"
                ]
            )
        }

        let result = waitUntilValue { completion in
            self.client.perform(request) { (response: DataResponse) in
                completion(response)
            }
        }

        expect(result).toNot(beNil())
        expect(result).to(beFailure())

        let error = try XCTUnwrap(result?.error)
        expect(error) == .errorResponse(
            .init(code: .unknownBackendError,
                  originalCode: 5000,
                  message: "something is broken up in the cloud"),
            HTTPStatusCode(rawValue: errorCode)
        )
        expect(error.isServerDown) == true

        expect(MockSigning.requests).to(beEmpty())
    }

    func testServerSide500sWithUnknownBody() throws {
        let logger = TestLogHandler()

        let request = HTTPRequest(method: .get, path: .mockPath)
        let errorCode = 500 + Int.random(in: 0..<50)

        stub(condition: isPath(request.path)) { _ in
            let json = "The server is broken"
            return HTTPStubsResponse(
                data: json.asData,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        let result = waitUntilValue { completion in
            self.client.perform(request) { (response: DataResponse) in
                completion(response)
            }
        }

        expect(result).toNot(beNil())
        expect(result).to(beFailure())

        let error = try XCTUnwrap(result?.error)
        expect(error) == .errorResponse(
            .init(code: .unknownError,
                  originalCode: BackendErrorCode.unknownError.rawValue,
                  message: nil),
            HTTPStatusCode(rawValue: errorCode)
        )
        expect(error.isServerDown) == true

        expect(MockSigning.requests).to(beEmpty())

        logger.verifyMessageWasNotLogged("Couldn't decode data from json")
    }

    func testInvalidJSONAsDataDoesNotFail() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let statusCode = HTTPStatusCode.success
        let data = "{this is not JSON.csdsd".data(using: String.Encoding.utf8)!

        stub(condition: isPath(request.path)) { _ in
            return HTTPStubsResponse(
                data: data,
                statusCode: Int32(statusCode.rawValue),
                headers: nil
            )
        }

        let result = waitUntilValue { completion in
            self.client.perform(request) { (response: DataResponse) in
                completion(response)
            }
        }

        expect(result).toNot(beNil())
        expect(result).to(beSuccess())
        expect(result?.value?.body) == data
    }

    func testParseError() throws {
        struct CustomResponse: Decodable, HTTPResponseBody {
            let data: String
        }

        let request = HTTPRequest(method: .get, path: .mockPath)
        let errorCode = HTTPStatusCode.success.rawValue

        stub(condition: isPath(request.path)) { _ in
            let json = "{this is not JSON.csdsd"
            return HTTPStubsResponse(
                data: json.data(using: String.Encoding.utf8)!,
                statusCode: Int32(errorCode),
                headers: nil
            )
        }

        let result = waitUntilValue { completion in
            self.client.perform(request) { (response: VerifiedHTTPResponse<CustomResponse>.Result) in
                completion(response)
            }
        }

        expect(result).toNot(beNil())
        expect(result).to(beFailure())

        let error = try XCTUnwrap(result?.error)
        switch error {
        case .decoding:
            break // correct error

        default:
            fail("Invalid error: \(error)")
        }
    }

    func testServerSide200s() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let responseData = "{\"message\": \"something is great up in the cloud\"}".asData

        stub(condition: isPath(request.path)) { _ in
            return HTTPStubsResponse(data: responseData,
                                     statusCode: .success,
                                     headers: nil)
        }

        let result = waitUntilValue { completion in
            self.client.perform(request) { (response: DataResponse) in
                completion(response)
            }
        }

        expect(result).toNot(beNil())
        expect(result).to(beSuccess())
        expect(result?.value?.body) == responseData
    }

    func testServerSide200WithETagInRequest() {
        let request = HTTPRequest(method: .get, path: .mockPath)
        let responseData = "{\"message\": \"something is great up in the cloud\"}".asData
        let eTag = "etag"
        let eTagValidationTime = Date(timeIntervalSince1970: 1234567)

        self.eTagManager.stubResponseEtag(eTag, validationTime: eTagValidationTime)

        stub(condition: isPath(request.path)) { request in
            expect(request.allHTTPHeaderFields?[ETagManager.eTagRequestHeaderName]) == eTag
            expect(request.allHTTPHeaderFields?[ETagManager.eTagValidationTimeRequestHeaderName])
            == eTagValidationTime.millisecondsSince1970.description

            return HTTPStubsResponse(data: responseData,
                                     statusCode: .success,
                                     headers: nil)
        }

        let result = waitUntilValue { completion in
            self.client.perform(request) { (response: DataResponse) in
                completion(response)
            }
        }

        expect(result).toNot(beNil())
        expect(result).to(beSuccess())
        expect(result?.value?.body) == responseData

        expect(self.eTagManager.invokedHTTPResultFromCacheOrBackend) == true
        expect(self.eTagManager.invokedHTTPResultFromCacheOrBackendCount) == 1
    }

    func testResponseDeserialization() throws {
        struct CustomResponse: Codable, Equatable, HTTPResponseBody {
            let message: String
        }

        let request = HTTPRequest(method: .get, path: .mockPath)

        let response = CustomResponse(message: "Something is great up in the cloud")
        let responseData = try JSONEncoder.default.encode(response)

        stub(condition: isPath(request.path)) { _ in
            return HTTPStubsResponse(data: responseData,
                                     statusCode: .success,
                                     headers: nil)
        }

        let result = waitUntilValue { completion in
            self.client.perform(request) { (response: VerifiedHTTPResponse<CustomResponse>.Result) in
                completion(response)
            }
        }

        expect(result).toNot(beNil())
        expect(result).to(beSuccess())
        expect(result?.value?.body) == response
        expect(result?.value?.statusCode) == .success
    }

    func testCachedRequestsIncludeETagHeader() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)
        let eTag = "ETAG"

        let headerPresent: Atomic<Bool> = false

        self.eTagManager.stubResponseEtag(eTag)

        stub(condition: isPath(request.path)) { request in
            headerPresent.value = request.allHTTPHeaderFields?[ETagManager.eTagRequestHeaderName] == eTag
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
        expect(self.eTagManager.invokedETagHeader) == true
    }

    func testNotCachedRequestsDontIncludeETagHeader() {
        let request = HTTPRequest(method: .post([:]), path: .health)
        let headerPresent: Atomic<Bool?> = nil

        stub(condition: isPath(request.path)) { request in
            headerPresent.value = request.allHTTPHeaderFields?.keys.contains(ETagManager.eTagRequestHeaderName) == true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == false
        expect(self.eTagManager.invokedETagHeader) == false
    }

    func testAlwaysPassesClientVersion() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        let version = SystemInfo.appVersion

        stub(condition: hasHeaderNamed("X-Client-Version", value: version)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testAlwaysPassesClientBuildVersion() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        let version = try XCTUnwrap(Bundle.main.infoDictionary!["CFBundleVersion"] as? String)

        stub(condition: hasHeaderNamed("X-Client-Build-Version", value: version )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testAlwaysPassesClientBundleID() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        let bundleID = try XCTUnwrap(Bundle.main.bundleIdentifier)

        stub(condition: hasHeaderNamed("X-Client-Bundle-ID", value: bundleID)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testPassesStoreKit2EnabledHeader() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        let enabled = self.systemInfo.storeKit2Setting.isEnabledAndAvailable.description

        stub(condition: hasHeaderNamed("X-StoreKit2-Enabled",
                                       value: enabled)) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    #if os(macOS) || targetEnvironment(macCatalyst)
    func testAlwaysPassesAppleDeviceIdentifierWhenIsSandbox() {
        let request = HTTPRequest(method: .get, path: .mockPath)

        let headerPresent: Atomic<Bool> = false
        systemInfo.stubbedIsSandbox = true

        let idfv = systemInfo.identifierForVendor!

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testAppleDeviceIdentifierNilWhenIsNotSandboxInMacOS() {
        self.systemInfo.stubbedIsSandbox = false

        expect(self.systemInfo.identifierForVendor).to(beNil())
    }

    #else

    func testAlwaysPassesAppleDeviceIdentifier() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        let idfv = try XCTUnwrap(self.systemInfo.identifierForVendor)

        stub(condition: hasHeaderNamed("X-Apple-Device-Identifier", value: idfv )) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }
    #endif

    func testDefaultsPlatformFlavorToNative() {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "native")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testPassesPlatformFlavorHeader() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor", value: "react-native")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }
        let platformInfo = Purchases.PlatformInfo(flavor: "react-native", version: "3.2.1")
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: true)

        self.client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: self.eTagManager)

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testPassesPlatformFlavorVersionHeader() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Platform-Flavor-Version", value: "1.2.3")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }
        let platformInfo = Purchases.PlatformInfo(flavor: "react-native", version: "1.2.3")
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: true)
        self.client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: self.eTagManager)

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testPassesObserverModeHeaderCorrectlyWhenEnabled() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "false")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }
        let systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: true)
        self.client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: self.eTagManager)

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testRequestsWithCustomEntitlementsSendHeader() {
        self.systemInfo = MockSystemInfo(finishTransactions: true, customEntitlementsComputation: true)
        self.client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: self.eTagManager)

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        var headerPresent = false

        stub(condition: isPath(request.path)) { request in
            let headers =  request.allHTTPHeaderFields ?? [:]
            headerPresent = headers["X-Custom-Entitlements-Computation"] != nil
                && headers["X-Custom-Entitlements-Computation"] == "true"
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent) == true
    }

    func testRequestsWithoutCustomEntitlementsDoNotSendHeader() {
        self.systemInfo = MockSystemInfo(finishTransactions: true, customEntitlementsComputation: false)
        self.client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: self.eTagManager)

        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        var headerPresent = false

        stub(condition: isPath(request.path)) { request in
            let headers =  request.allHTTPHeaderFields ?? [:]
            headerPresent = headers["X-Custom-Entitlements-Computation"] != nil
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent) == false
    }

    func testPassesObserverModeHeaderCorrectlyWhenDisabled() throws {
        let request = HTTPRequest(method: .post([:]), path: .mockPath)

        let headerPresent: Atomic<Bool> = false

        stub(condition: hasHeaderNamed("X-Observer-Mode-Enabled", value: "true")) { _ in
            headerPresent.value = true
            return .emptySuccessResponse()
        }
        let systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: false)
        self.client = HTTPClient(apiKey: self.apiKey, systemInfo: systemInfo, eTagManager: self.eTagManager)

        waitUntil { completion in
            self.client.perform(request) { (_: DataResponse) in completion() }
        }

        expect(headerPresent.value) == true
    }

    func testPerformSerialRequestPerformsAllRequestsInTheCorrectOrder() {
        let path: HTTPRequest.Path = .mockPath

        let completionCallCount: Atomic<Int> = .init(0)

        stub(condition: isPath(path)) { request in
            let requestNumber = Self.extractRequestNumber(from: request)
            expect(requestNumber) == completionCallCount.value

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.asData,
                                     statusCode: .success,
                                     headers: nil)
                .responseTime(0.003)
        }

        let serialRequests = 10
        for requestNumber in 0..<serialRequests {
            let expectation = self.expectation(description: "Request \(requestNumber)")

            client.perform(.init(method: .requestNumber(requestNumber), path: path)) { (_: DataResponse) in
                completionCallCount.value += 1
                expectation.fulfill()
            }
        }

        self.waitForExpectations(timeout: 1)
        expect(completionCallCount.value) == serialRequests
    }

    func testPerformSerialRequestWaitsUntilFirstRequestIsDoneBeforeStartingSecond() {
        let path: HTTPRequest.Path = .mockPath

        let firstRequestFinished: Atomic<Bool> = false
        let secondRequestFinished: Atomic<Bool> = false

        stub(condition: isPath(path)) { request in
            usleep(30)
            let requestNumber = Self.extractRequestNumber(from: request)
            if requestNumber == 2 {
                expect(firstRequestFinished.value) == true
            }

            let json = "{\"message\": \"something is great up in the cloud\"}"
            return HTTPStubsResponse(data: json.data(using: String.Encoding.utf8)!,
                                     statusCode: .success,
                                     headers: nil)
                .responseTime(0.1)
        }

        let expectations = [
            self.expectation(description: "Request 1"),
            self.expectation(description: "Request 2")
        ]

        self.client.perform(.init(method: .requestNumber(1), path: path)) { (_: DataResponse) in
            firstRequestFinished.value = true
            expectations[0].fulfill()
        }

        self.client.perform(.init(method: .requestNumber(2), path: path)) { (_: DataResponse) in
            secondRequestFinished.value = true
            expectations[1].fulfill()
        }

        self.waitForExpectations(timeout: 1)

        expect(firstRequestFinished.value) == true
        expect(secondRequestFinished.value) == true
    }

    func testPerformSerialRequestWaitsUntilRequestsAreDoneBeforeStartingNext() {
        let path: HTTPRequest.Path = .mockPath

        let firstRequestFinished: Atomic<Bool> = false
        let secondRequestFinished: Atomic<Bool> = false
        let thirdRequestFinished: Atomic<Bool> = false

        stub(condition: isPath(path)) { request in
            let requestNumber = Self.extractRequestNumber(from: request)
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

        let expectations = [
            self.expectation(description: "Request 1"),
            self.expectation(description: "Request 2"),
            self.expectation(description: "Request 3")
        ]

        self.client.perform(.init(method: .requestNumber(1), path: path)) { (_: DataResponse) in
            firstRequestFinished.value = true
            expectations[0].fulfill()
        }

        self.client.perform(.init(method: .requestNumber(2), path: path)) { (_: DataResponse) in
            secondRequestFinished.value = true
            expectations[1].fulfill()
        }

        self.client.perform(.init(method: .requestNumber(3), path: path)) { (_: DataResponse) in
            thirdRequestFinished.value = true
            expectations[2].fulfill()
        }

        self.waitForExpectations(timeout: 3)

        expect(firstRequestFinished.value) == true
        expect(secondRequestFinished.value) == true
        expect(thirdRequestFinished.value) == true
    }

    func testPerformRequestExitsWithErrorIfBodyCouldntBeParsedIntoJSON() throws {
        let response = waitUntilValue { completion in
            self.client.perform(.init(method: .invalidBody(), path: .mockPath)) { (result: DataResponse) in
                completion(result)
            }
        }

        let error = try XCTUnwrap(response?.error)
        expect(error) == .unableToCreateRequest(.mockPath)
    }

    func testPerformRequestDoesntPerformRequestIfBodyCouldntBeParsedIntoJSON() {
        let path: HTTPRequest.Path = .mockPath

        let httpCallMade: Atomic<Bool> = false

        stub(condition: isPath(path)) { _ in
            httpCallMade.value = true
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(.init(method: .invalidBody(), path: path)) { (_: DataResponse) in
                completion()
            }
        }

        expect(httpCallMade.value) == false
    }

    func testRequestIsRetriedIfResponseFromETagManagerIsNil() {
        let path: HTTPRequest.Path = .mockPath

        let requests: Atomic<Int> = .init(0)

        stub(condition: isPath(path)) { [eTagManager = self.eTagManager!] _ in
            defer { requests.value += 1 }

            if requests.value > 0 {
                eTagManager.shouldReturnResultFromBackend = true
            }

            return .emptySuccessResponse()
        }

        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = nil

        let result: DataResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path)) {
                completion($0)
            }
        }

        expect(result).to(beSuccess())
        expect(requests.value) == 2
    }

    func testGetsResponseFromETagManagerWhenStatusCodeIsNotModified() throws {
        let path: HTTPRequest.Path = .mockPath

        let mockedCachedResponse = try JSONSerialization.data(withJSONObject: [
            "test": "data"
        ])
        let eTag = "tag"
        let requestDate = Date().addingTimeInterval(-1000000)

        let headers: [String: String] = [
            HTTPClient.ResponseHeader.contentType.rawValue: "application/json",
            HTTPClient.ResponseHeader.signature.rawValue: UUID().uuidString,
            HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate.millisecondsSince1970)
        ]

        self.eTagManager.stubResponseEtag(eTag)
        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = .init(
            statusCode: .success,
            responseHeaders: headers,
            body: mockedCachedResponse
        )

        stub(condition: isPath(path)) { response in
            expect(response.allHTTPHeaderFields?[ETagManager.eTagRequestHeaderName]) == eTag

            return .init(data: Data(),
                         statusCode: .notModified,
                         headers: headers)
        }

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path)) { (result: DataResponse) in
                completion(result)
            }
        }

        expect(response).toNot(beNil())
        expect(response?.value?.statusCode) == .success
        expect(response?.value?.body) == mockedCachedResponse
        expect(response?.value?.requestDate).to(beCloseToDate(requestDate))
        expect(response?.value?.verificationResult) == .notRequested
        expect(response?.value?.responseHeaders.keys).to(contain(Array(headers.keys.map(AnyHashable.init))))

        expect(self.eTagManager.invokedETagHeaderParametersList).to(haveCount(1))
    }

    func testDNSCheckerIsCalledWhenGETRequestFailedWithUnknownError() {
        let path: HTTPRequest.Path = .mockPath

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = false

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse()
            response.error = error
            return response
        }

        waitUntil { completion in
            self.client.perform(.init(method: .get, path: path)) { (_: DataResponse) in
                completion()
            }
        }

        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value) == true
        expect(MockDNSChecker.invokedIsBlockedAPIError.value) == false
    }

    func testDNSCheckerIsCalledWhenPOSTRequestFailedWithUnknownError() {
        let path: HTTPRequest.Path = .mockPath

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = false

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse()
            response.error = error
            return response
        }

        waitUntil { completion in
            self.client.perform(.init(method: .post([:]), path: path)) { (_: DataResponse) in
                completion()
            }
        }

        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value) == true
        expect(MockDNSChecker.invokedIsBlockedAPIError.value) == false
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
            let response = HTTPStubsResponse.emptySuccessResponse()
            response.error = nsErrorWithUserInfo
            return response
        }

        waitUntil { completion in
            self.client.perform(.init(method: .post([:]), path: path)) { (_: DataResponse) in
                completion()
            }
        }

        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value) == true
        expect(MockDNSChecker.invokedIsBlockedAPIError.value) == false
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
            let response = HTTPStubsResponse.emptySuccessResponse()
            response.error = nsErrorWithUserInfo
            return response
        }
        waitUntil { completion in
            self.client.perform(.init(method: .get, path: path)) { (_: DataResponse) in
                completion()
            }
        }

        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value) == true
        expect(MockDNSChecker.invokedIsBlockedAPIError.value) == false
    }

    func testOfflineConnectionError() {
        let path: HTTPRequest.Path = .mockPath

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse()
            response.error = error
            return response
        }

        let obtainedError: NetworkError? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path)) { (result: DataResponse) in
                completion(result.error)
            }
        }

        expect(obtainedError).toNot(beNil())
        expect(obtainedError) == .offlineConnection()
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

        let logHandler = TestLogHandler()

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse()
            response.error = error
            return response
        }

        let obtainedError: NetworkError? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path)) { (result: DataResponse) in
                completion(result.error)
            }
        }

        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value) == true
        expect(MockDNSChecker.invokedIsBlockedAPIError.value) == false
        expect(obtainedError) == expectedDNSError
        expect(logHandler.messages.map(\.message))
            .to(contain(expectedMessage))
    }

    func testErrorIsntLoggedWhenGETRequestFailedWithUnknownError() {
        let path: HTTPRequest.Path = .mockPath

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        let unexpectedDNSError: NetworkError = .dnsError(
            failedURL: URL(string: "https://0.0.0.0/subscribers")!,
            resolvedHost: "0.0.0.0"
        )
        MockDNSChecker.stubbedIsBlockedAPIErrorResult.value = false

        let logHandler = TestLogHandler()

        stub(condition: isPath(path)) { _ in
            let response = HTTPStubsResponse.emptySuccessResponse()
            response.error = error
            return response
        }

        waitUntil { completion in
            self.client.perform(.init(method: .get, path: path)) { (_: DataResponse) in
                completion()
            }
        }

        expect(MockDNSChecker.invokedErrorWithBlockedHostFromError.value) == true
        expect(MockDNSChecker.invokedIsBlockedAPIError.value) == false
        expect(logHandler.messages.map(\.message))
            .toNot(contain(unexpectedDNSError.description))
    }

    func testResponseFromServerUpdatesRequestDate() throws {
        let path: HTTPRequest.Path = .mockPath
        let mockedResponse = BodyWithDate(data: "test", requestDate: Date().addingTimeInterval(-3000000))
        let encodedResponse = try mockedResponse.jsonEncodedData
        let requestDate = Date().addingTimeInterval(-100000)

        stub(condition: isPath(path)) { _ in
            return HTTPStubsResponse(
                data: encodedResponse,
                statusCode: .success,
                headers: [
                    HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate.millisecondsSince1970)
                ]
            )
        }

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path), completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseTo(requestDate, within: 1))
    }

    func testCachedResponseUpdatesRequestDate() throws {
        let path: HTTPRequest.Path = .mockPath
        let eTag = "etag"
        let mockedResponse = BodyWithDate(data: "test", requestDate: Date().addingTimeInterval(-30000000))
        let encodedResponse = try mockedResponse.jsonEncodedData
        let requestDate = Date().addingTimeInterval(-1000000)

        self.eTagManager.stubResponseEtag(eTag)
        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = .init(
            statusCode: .success,
            responseHeaders: [:],
            body: encodedResponse,
            requestDate: requestDate
        )

        stub(condition: isPath(path)) { _ in
            return HTTPStubsResponse(
                data: .init(),
                statusCode: .notModified,
                headers: [
                    HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate.millisecondsSince1970)
                ]
            )
        }

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path), completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseTo(requestDate, within: 1))
        expect(response?.value?.verificationResult) == .notRequested

        expect(self.eTagManager.invokedETagHeaderParametersList).to(haveCount(1))
    }

    func testFakeServerErrors() throws {
        let path: HTTPRequest.Path = .mockPath

        stub(condition: isPath(path)) { _ in
            fail("Should not perform request")
            return .emptySuccessResponse()
        }

        self.systemInfo = try .init(
            platformInfo: nil,
            finishTransactions: false,
            dangerousSettings: .init(
                autoSyncPurchases: true,
                internalSettings: DangerousSettings.Internal(forceServerErrors: true)
            )
        )
        self.client = self.createClient()

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path), completionHandler: completion)
        }

        expect(response).to(beFailure())
        expect(response?.error).to(matchError(NetworkError.errorResponse(
            ErrorResponse(code: .internalServerError,
                          originalCode: BackendErrorCode.unknownBackendError.rawValue),
            .internalServerError)
        ))
    }

    func testRedirectIsLogged() throws {
        // Task delegate is only available after iOS 15.
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let pathA: HTTPRequest.Path = .logIn
        let pathB: HTTPRequest.Path = .health

        let responseData = "{\"message\": \"something is great up in the cloud\"}".asData

        stub(condition: isPath(pathA)) { _ in
            return HTTPStubsResponse(
                data: .init(),
                statusCode: .temporaryRedirect,
                headers: [
                    HTTPClient.ResponseHeader.location.rawValue: pathB.url!.absoluteString
                ]
            )
        }
        stub(condition: isPath(pathB)) { _ in
            return HTTPStubsResponse(
                data: responseData,
                statusCode: .success,
                headers: nil
            )
        }

        let logger = TestLogHandler()

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: pathA), completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body) == responseData

        logger.verifyMessageWasLogged(
            "Performing redirect from '\(pathA.url!.absoluteString)' to '\(pathB.url!.absoluteString)'",
            level: .debug
        )
    }

    func testNormalResponsesAreNotDetectedAsLoadSheddder() throws {
        let path: HTTPRequest.Path = .logIn

        stub(condition: isPath(path)) { _ in
            return HTTPStubsResponse(
                data: .init(),
                statusCode: .success,
                headers: [:]
            )
        }

        let logger = TestLogHandler()

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path), completionHandler: completion)
        }
        expect(response).to(beSuccess())

        logger.verifyMessageWasNotLogged(Strings.network.request_handled_by_load_shedder(path))
    }

    func testLoadShedderResponsesAreLogged() throws {
        let path: HTTPRequest.Path = .logIn

        stub(condition: isPath(path)) { _ in
            return HTTPStubsResponse(
                data: .init(),
                statusCode: .success,
                headers: [
                    HTTPClient.ResponseHeader.isLoadShedder.rawValue: "true"
                ]
            )
        }

        let logger = TestLogHandler()

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path), completionHandler: completion)
        }
        expect(response).to(beSuccess())

        logger.verifyMessageWasLogged(
            Strings.network.request_handled_by_load_shedder(path),
            level: .debug
        )
    }

}

func isPath(_ path: HTTPRequest.Path) -> HTTPStubsTestBlock {
    return isPath(path.relativePath)
}

extension HTTPStubsResponse {

    static func emptySuccessResponse() -> HTTPStubsResponse {
        // `HTTPStubsResponse` doesn't have value semantics, it's a mutable class!
        // This creates a new response each time so modifications in one test don't affect others.
        return .init(data: Data(),
                     statusCode: .success,
                     headers: nil)
    }

    convenience init(data: Data, statusCode: HTTPStatusCode, headers: HTTPClient.RequestHeaders?) {
        self.init(data: data, statusCode: Int32(statusCode.rawValue), headers: headers)
    }

}

// MARK: - Extensions

private extension BaseHTTPClientTests {

    static func extractRequestNumber(from urlRequest: URLRequest) -> Int? {
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

extension BaseHTTPClientTests {

    struct BodyWithDate: Equatable, Codable, HTTPResponseBody {
        var data: String
        var requestDate: Date

        func copy(with newRequestDate: Date) -> HTTPClientTests.BodyWithDate {
            var copy = self
            copy.requestDate = newRequestDate
            return copy
        }
    }

}

extension HTTPRequest.Path {

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
