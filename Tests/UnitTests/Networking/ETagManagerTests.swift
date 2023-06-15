import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ETagManagerTests: TestCase {

    private var mockUserDefaults: MockUserDefaults! = nil
    private var eTagManager: ETagManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockUserDefaults = MockUserDefaults()
        self.eTagManager = try self.create()
    }

    override func tearDown() {
        self.mockUserDefaults = nil
        self.eTagManager = nil

        super.tearDown()
    }

    func testETagIsEmptyIfThereIsNoETagSavedForThatRequest() {
        let request = URLRequest(url: Self.testURL)
        let header = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)

        let eTag = header[ETagManager.eTagRequestHeaderName]
        expect(eTag) == ""
    }

    func testETagIsEmptyIfThereIsNoETagSavedForThatRequestWithDifferentURL() throws {
        let request1 = URLRequest(url: Self.testURL)
        let request2 = URLRequest(url: Self.testURL2)

        try self.mockStoredETagResponse(for: request1)

        let header = self.eTagManager.eTagHeader(for: request2, withSignatureVerification: false)
        expect(header[ETagManager.eTagRequestHeaderName]) == ""
    }

    func testETagIsEmptyIfThereIsNoETagSavedForThatRequestWithANewAPIKey() throws {
        var request1 = URLRequest(url: Self.testURL)
        var request2 = URLRequest(url: Self.testURL)

        request1.allHTTPHeaderFields = HTTPClient.authorizationHeader(withAPIKey: "api key 1")
        request2.allHTTPHeaderFields = HTTPClient.authorizationHeader(withAPIKey: "api key 2")

        try self.mockStoredETagResponse(for: request1)

        let eTag = self.eTagManager.eTagHeader(for: request2, withSignatureVerification: false)
        expect(eTag[ETagManager.eTagRequestHeaderName]) == ""
    }

    func testETagIsAddedToHeadersIfThereIsACachedETagForThatURL() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        try self.mockStoredETagResponse(for: request)
        let header = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)

        expect(header[ETagManager.eTagRequestHeaderName]) == eTag
    }

    func testStoredResponseIsUsedIfResponseCodeIs304() throws {
        let request = URLRequest(url: Self.testURL)

        let cachedResponse = try self.mockStoredETagResponse(for: request, statusCode: .success)

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: try request.eTag,
                                       statusCode: .notModified),
            request: request,
            retried: false
        )
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.body) == cachedResponse
    }

    func testValidationTimeIsUpdatedWhenUsingStoredResponse() throws {
        let request = URLRequest(url: Self.testURL)
        let validationTime = Date(timeIntervalSince1970: 10000)

        let cachedResponse = try self.mockStoredETagResponse(for: request,
                                                             statusCode: .success,
                                                             validationTime: validationTime)
        expect(try self.getCachedResponse(for: request).validationTime)
            .to(beCloseTo(validationTime, within: 1))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: try request.eTag,
                                       statusCode: .notModified),
            request: request,
            retried: false
        )
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.body) == cachedResponse

        let newCachedResponse = try self.getCachedResponse(for: request)
        expect(newCachedResponse.validationTime).toNot(beCloseTo(validationTime, within: 1))
        expect(newCachedResponse.validationTime).to(beCloseToNow())
    }

    func testStoredResponseIsNotUsedIfResponseCodeIs200() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        _ = try self.mockStoredETagResponse(for: request, statusCode: .success)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let requestDate = Date().addingTimeInterval(-100000)

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: responseObject,
                                       eTag: eTag,
                                       statusCode: .success,
                                       requestDate: requestDate),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.body) == responseObject
        expect(response?.requestDate) == requestDate
    }

    func testResultIsNilIfResponseCodeIs304ButContainsNoETag() throws {
        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: nil,
                                       statusCode: .notModified,
                                       requestDate: Date()),
            request: URLRequest(url: Self.testURL),
            retried: false
        )

        expect(response).to(beNil())
    }

    func testBackendResponseIsReturnedIf304AndCantFindCachedAndItHasAlreadyRetried() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: eTag,
                statusCode: .notModified
            ),
            request: request,
            retried: true
        )

        expect(response).toNot(beNil())
        expect(response?.statusCode) == .notModified
        expect(response?.body) == responseObject
    }

    func testReturnNullIf304AndCantFindCachedResponse() throws {
        let eTag = "an_etag"
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: eTag,
                statusCode: .notModified
            ),
            request: request,
            retried: false
        )

        expect(response).to(beNil())
    }

    func testResponseIsStoredIfResponseCodeIs200AndVerificationWasNotRequested() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: eTag,
                statusCode: .success,
                verificationResult: .notRequested
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 1

        expect(self.mockUserDefaults.mockValues[eTag]).toNot(beNil())
        let setData = try XCTUnwrap(self.mockUserDefaults.mockValues[eTag] as? Data)

        expect(setData).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == eTag

        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.eTag) == eTag
        expect(eTagResponse.data) == responseObject
    }

    func testResponseIsStoredIfResponseCodeIs200AndVerificationSucceded() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: eTag,
                statusCode: .success,
                verificationResult: .verified
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 1

        expect(self.mockUserDefaults.mockValues[eTag]).toNot(beNil())
        let setData = try XCTUnwrap(self.mockUserDefaults.mockValues[eTag] as? Data)

        expect(setData).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == eTag

        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.eTag) == eTag
        expect(eTagResponse.data) == responseObject
    }

    func testResponseIsNotStoredIfResponseCodeIs500() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let responseObject = Data()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: eTag,
                statusCode: .internalServerError
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(response?.statusCode) == .internalServerError
        expect(response?.body) == responseObject

        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 0

        expect(self.mockUserDefaults.mockValues[eTag]).to(beNil())
    }

    func testResponseIsNotStoredIfVerificationFailedWithInformationalMode() throws {
        self.eTagManager = try self.create(with: .informational)

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let responseObject = Data()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: eTag,
                statusCode: .success,
                verificationResult: .failed
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 0
        expect(self.mockUserDefaults.mockValues[Self.testURL.absoluteString]).to(beNil())
    }

    func testResponseIsNotStoredIfVerificationFailedWithEnforcedMode() throws {
        try self.setEnforcedETagManager()

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let responseObject = Data()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: eTag,
                statusCode: .success,
                verificationResult: .failed
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(response?.verificationResult) == .failed

        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 0

        expect(self.mockUserDefaults.mockValues[eTag]).to(beNil())
    }

    func testClearCachesWorks() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        _ = try self.mockStoredETagResponse(for: request, statusCode: .success)

        expect(self.mockUserDefaults.mockValues[eTag]).toNot(beNil())

        eTagManager.clearCaches()

        expect(self.mockUserDefaults.mockValues.count) == 0
    }

    func testReadingETagWithInvalidBodyFormatFails() throws {
        /// The data that `ETagManager` serialized up until version 4.1.
        struct OldWrapper: Encodable {

            let eTag: String
            let statusCode: Int
            let responseObject: [String: AnyEncodable]

            var asData: Data? {
                return try? JSONSerialization.data(withJSONObject: self.asDictionary(),
                                                   options: .prettyPrinted)
            }

        }

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        let wrapper = OldWrapper(eTag: eTag,
                                 statusCode: HTTPStatusCode.success.rawValue,
                                 responseObject: [
                                    "response": AnyEncodable("cached")
                                 ])
        self.mockUserDefaults.mockValues[eTag] = wrapper.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: actualResponse,
                                       eTag: eTag,
                                       statusCode: .notModified),
            request: request,
            retried: true
        )
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .notModified
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .notRequested
    }

    func testETagHeaderIsNotFoundIfItsMissingResponseVerificationAndVerificationEnforced() throws {
        try self.setEnforcedETagManager()

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsNotFoundIfItsMissingResponseVerificationAndVerificationInformational() throws {
        self.eTagManager = try self.create(with: .informational)

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsFoundIfItsMissingResponseVerificationAndVerificationIsDisabled() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagRequestHeaderName]) == eTag
    }

    func testETagHeaderIsIgnoredIfVerificationFailedAndModeEnforced() throws {
        try self.setEnforcedETagManager()

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerificationFailedAndModeInformational() throws {
        self.eTagManager = try self.create(with: .informational)

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerificationWasNotEnabledAndModeInformational() throws {
        self.eTagManager = try self.create(with: .informational)

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerificationWasNotEnabledAndModeEnforced() throws {
        try self.setEnforcedETagManager()

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsReturnedIfVerificationSucceded() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verified
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeaderName]) == eTag
    }

    func testETagHeaderIsReturnedIfVerificationWasNotRequested() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeaderName]) == eTag
    }

    func testETagHeaderContainsValidationTime() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag
        let validationTime = Date(timeIntervalSince1970: 800000)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            validationTime: validationTime,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response) == [
            ETagManager.eTagRequestHeaderName: eTag,
            ETagManager.eTagValidationTimeRequestHeaderName: validationTime.millisecondsSince1970.description
        ]
    }

    func testETagHeaderDoesNotContainValidationTimeIfNotPresent() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            validationTime: nil,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response) == [
            ETagManager.eTagRequestHeaderName: eTag
        ]
    }

    func testResponseReturnsRequestDateFromServer() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag
        let requestDate = Date().addingTimeInterval(-100000)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: eTag,
                                       statusCode: .notModified,
                                       requestDate: requestDate),
            request: request,
            retried: false
        )
        expect(response?.requestDate) == requestDate
    }

    func testCachedResponseWithNoVerificationResultIsNotIgnored() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: eTag,
                                       statusCode: .notModified),
            request: request,
            retried: false
        )
        expect(response?.verificationResult) == .notRequested
        expect(response?.body) == actualResponse
    }

    func testCachedResponseWithNoValidationTimeIsNotIgnored() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: eTag,
                                       statusCode: .notModified),
            request: request,
            retried: false
        )
        expect(response?.requestDate).to(beNil())
        expect(response?.body) == actualResponse
    }

    func testCachedResponseIsFoundIfVerificationWasNotRequested() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: eTag,
                                       statusCode: .notModified),
            request: request,
            retried: true
        )
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .notRequested
    }

    func testCachedResponseIsFoundIfVerificationSucceeded() throws {
        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)",
        "verification_result": \(VerificationResult.verified.rawValue)
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: eTag,
                                       statusCode: .notModified),
            request: request,
            retried: true
        )
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .verified
    }

    func testCachedResponseIsReturnedEvenIfVerificationFailed() throws {
        // Technically, as tested by `testResponseIsNotStoredIfVerificationFailed`
        // a response can't be stored if verification failed, but useful to test just in case.

        let request = URLRequest(url: Self.testURL)
        let eTag = try request.eTag

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[eTag] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed
        ).asData()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: eTag,
                                       statusCode: .notModified),
            request: request,
            retried: true
        )
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .failed
    }

}

private extension ETagManagerTests {

    /// - Throws: `XCTSkip` prior to iOS 13
    func create(with verificationMode: Configuration.EntitlementVerificationMode = .disabled) throws -> ETagManager {
        let mode: Signing.ResponseVerificationMode

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            mode = Signing.verificationMode(with: verificationMode)
        } else if verificationMode == .disabled {
            mode = .disabled
        } else {
            throw XCTSkip("Response verification not available")
        }

        return self.create(mode)
    }

    /// - Throws: `XCTSkip` prior to iOS 13
    func setEnforcedETagManager() throws {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            self.eTagManager = self.create(Signing.enforcedVerificationMode())
        } else {
            throw XCTSkip("iOS 13 required for this test")
        }
    }

    private func create(_ mode: Signing.ResponseVerificationMode) -> ETagManager {
        return .init(userDefaults: self.mockUserDefaults, verificationMode: mode)
    }

    func getHeaders(eTag: String?) -> [String: String] {
        return [
            "Content-Type": "application/json",
            "X-Platform": "android",
            "X-Platform-Flavor": "native",
            "X-Platform-Version": "29",
            "X-Version": "4.1.0",
            "X-Client-Locale": "en-US",
            "X-Client-Version": "1.0",
            "X-Observer-Mode-Enabled": "false",
            ETagManager.eTagRequestHeaderName: eTag
        ]
            .compactMapValues { $0 }
            .merging(HTTPClient.authorizationHeader(withAPIKey: "apikey"))
    }

    @discardableResult
    func mockStoredETagResponse(for request: URLRequest,
                                statusCode: HTTPStatusCode = .success,
                                validationTime: Date? = nil,
                                verificationResult: RevenueCat.VerificationResult = .defaultValue) throws -> Data {
        // swiftlint:disable:next force_try
        let data = try! JSONSerialization.data(withJSONObject: ["arg": "value"])

        let eTag = try request.eTag

        let etagAndResponse = ETagManager.Response(
            eTag: eTag,
            statusCode: statusCode,
            data: data,
            validationTime: validationTime,
            verificationResult: verificationResult
        )
        self.mockUserDefaults.mockValues[eTag] = etagAndResponse.asData()!

        return data
    }

    func getCachedResponse(for request: URLRequest) throws -> ETagManager.Response {
        let cachedData = try XCTUnwrap(self.mockUserDefaults.mockValues[request.eTag] as? Data)
        return try ETagManager.Response.with(cachedData)
    }

    func responseForTest(
        url: URL,
        body: Data?,
        eTag: String?,
        statusCode: HTTPStatusCode,
        requestDate: Date? = nil,
        verificationResult: RevenueCat.VerificationResult = .defaultValue
    ) -> HTTPResponse<Data?> {
        return .init(statusCode: statusCode,
                     responseHeaders: self.getHeaders(eTag: eTag),
                     body: body,
                     requestDate: requestDate,
                     verificationResult: verificationResult)
    }

    private static let testURL = HTTPRequest.Path.getCustomerInfo(appUserID: "appUserID").url!
    private static let testURL2 = HTTPRequest.Path.getCustomerInfo(appUserID: "appUserID_2").url!

}

private extension ETagManager.Response {

    static func with(_ data: Data) throws -> Self {
        return try JSONDecoder.default.decode(jsonData: data)
    }

}

private extension URLRequest {

    var eTag: String {
        get throws {
            return try XCTUnwrap(ETagManager.eTag(for: self))
        }
    }

}
