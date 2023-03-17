import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ETagManagerTests: TestCase {

    private var mockUserDefaults: MockUserDefaults! = nil
    private var eTagManager: ETagManager!
    private let baseURL = URL(string: "https://api.revenuecat.com")!

    override func setUp() {
        super.setUp()

        self.mockUserDefaults = MockUserDefaults()
        self.eTagManager = self.create()
    }

    override func tearDown() {
        self.mockUserDefaults = nil
        self.eTagManager = nil

        super.tearDown()
    }

    func testETagIsEmptyIfThereIsNoETagSavedForThatRequest() {
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let header = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        let value2: String? = header[ETagManager.eTagRequestHeaderName]

        expect(value2) == ""
    }

    func testETagIsAddedToHeadersIfThereIsACachedETagForThatURL() {
        let url = self.urlForTest()
        _ = self.mockStoredETagResponse(for: url)
        let request = URLRequest(url: url)
        let header = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        let value2: String? = header[ETagManager.eTagRequestHeaderName]

        expect(value2) == "an_etag"
    }

    func testStoredResponseIsUsedIfResponseCodeIs304() throws {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let cachedResponse = mockStoredETagResponse(for: url, statusCode: .success, eTag: eTag)

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: url,
                                       body: nil,
                                       eTag: eTag,
                                       statusCode: .notModified),
            request: request,
            retried: false
        )
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.body) == cachedResponse
    }

    func testStoredResponseIsNotUsedIfResponseCodeIs200() throws {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        _ = mockStoredETagResponse(for: url, statusCode: .success, eTag: eTag)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let requestDate = Date().addingTimeInterval(-100000)

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: url,
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

    func testBackendResponseIsReturnedIf304AndCantFindCachedAndItHasAlreadyRetried() throws {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: url,
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
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: url,
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
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: url,
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

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).toNot(beNil())
        let setData = try XCTUnwrap(self.mockUserDefaults.mockValues[cacheKey] as? Data)

        expect(setData).toNot(beNil())
        let expectedCachedValue = "https://api.revenuecat.com/v1/subscribers/appUserID"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedCachedValue

        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.eTag) == eTag
        expect(eTagResponse.data) == responseObject
    }

    func testResponseIsStoredIfResponseCodeIs200AndVerificationSucceded() throws {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: url,
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

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).toNot(beNil())
        let setData = try XCTUnwrap(self.mockUserDefaults.mockValues[cacheKey] as? Data)

        expect(setData).toNot(beNil())
        let expectedCachedValue = "https://api.revenuecat.com/v1/subscribers/appUserID"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedCachedValue

        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.eTag) == eTag
        expect(eTagResponse.data) == responseObject
    }

    func testResponseIsNotStoredIfResponseCodeIs500() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = Data()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: url,
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

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).to(beNil())
    }

    func testResponseIsNotStoredIfVerificationFailedWithInformationalMode() throws {
        self.eTagManager = self.create(with: .informational)

        let eTag = "an_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let responseObject = Data()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: url,
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
        expect(self.mockUserDefaults.mockValues[url.absoluteString]).to(beNil())
    }

    func testResponseIsNotStoredIfVerificationFailedWithEnforcedMode() throws {
        try self.setEnforcedETagManager()

        let eTag = "an_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let responseObject = Data()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: url,
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

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).to(beNil())
    }

    func testClearCachesWorks() {
        let eTag = "an_etag"
        let url = urlForTest()
        _ = mockStoredETagResponse(for: url, statusCode: .success, eTag: eTag)

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).toNot(beNil())

        eTagManager.clearCaches()

        expect(self.mockUserDefaults.mockValues.count) == 0
    }

    func testReadingETagWithInvalidBodyFormatFails() {
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

        let eTag = "the_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        let wrapper = OldWrapper(eTag: eTag,
                                 statusCode: HTTPStatusCode.success.rawValue,
                                 responseObject: [
                                    "response": AnyEncodable("cached")
                                 ])
        self.mockUserDefaults.mockValues[cacheKey] = wrapper.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: url,
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

        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = """
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

    func testETagHeaderIsNotFoundIfItsMissingResponseVerificationAndVerificationInformational() {
        self.eTagManager = self.create(with: .informational)

        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = """
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

    func testETagHeaderIsFoundIfItsMissingResponseVerificationAndVerificationIsDisabled() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeaderName]) == eTag
    }

    func testETagHeaderIsIgnoredIfVerificationFailedAndModeEnforced() throws {
        try self.setEnforcedETagManager()

        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerificationFailedAndModeInformational() {
        self.eTagManager = self.create(with: .informational)

        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerificationWasNotEnabledAndModeInformational() {
        self.eTagManager = self.create(with: .informational)

        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
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

        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsReturnedIfVerificationSucceded() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verified
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeaderName]) == eTag
    }

    func testETagHeaderIsReturnedIfVerificationWasNotRequested() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeaderName]) == eTag
    }

    func testResponseReturnsRequestDateFromServer() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString
        let requestDate = Date().addingTimeInterval(-100000)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: url,
                                       body: nil,
                                       eTag: eTag,
                                       statusCode: .notModified,
                                       requestDate: requestDate),
            request: request,
            retried: false
        )
        expect(response?.requestDate) == requestDate
    }

    func testCachedResponseWithNoVerificationResultIsNotIgnored() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: url,
                                       body: nil,
                                       eTag: eTag,
                                       statusCode: .notModified),
            request: request,
            retried: false
        )
        expect(response?.verificationResult) == .notRequested
        expect(response?.body) == actualResponse
    }

    func testCachedResponseIsFoundIfVerificationWasNotRequested() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: url,
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

    func testCachedResponseIsFoundIfVerificationSucceeded() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = """
        {
        "e_tag": "\(eTag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)",
        "verification_result": \(VerificationResult.verified.rawValue)
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: url,
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

    func testCachedResponseIsReturnedEvenIfVerificationFailed() {
        // Technically, as tested by `testResponseIsNotStoredIfVerificationFailed`
        // a response can't be stored if verification failed, but useful to test just in case.

        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed
        ).asData()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: url,
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

    func create(with verificationMode: Configuration.EntitlementVerificationMode = .disabled) -> ETagManager {
        let mode: Signing.ResponseVerificationMode

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            mode = Signing.verificationMode(with: verificationMode)
        } else {
            mode = .disabled
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

    func getHeaders(eTag: String) -> [String: String] {
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
            .merging(HTTPClient.authorizationHeader(withAPIKey: "apikey"))
    }

    func mockStoredETagResponse(for url: URL,
                                statusCode: HTTPStatusCode = .success,
                                eTag: String = "an_etag",
                                verificationResult: RevenueCat.VerificationResult = .defaultValue) -> Data {
        // swiftlint:disable:next force_try
        let data = try! JSONSerialization.data(withJSONObject: ["arg": "value"])

        let etagAndResponse = ETagManager.Response(
            eTag: eTag,
            statusCode: statusCode,
            data: data,
            verificationResult: verificationResult
        )
        let cacheKey = url.absoluteString
        self.mockUserDefaults.mockValues[cacheKey] = etagAndResponse.asData()!

        return data
    }

    func urlForTest() -> URL {
        guard let url: URL = URL(string: "/v1/subscribers/appUserID", relativeTo: baseURL) else {
            fatalError("Error initializing URL")
        }
        return url
    }

    func responseForTest(
        url: URL,
        body: Data?,
        eTag: String,
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

}

private extension ETagManager.Response {

    static func with(_ data: Data) throws -> Self {
        return try JSONDecoder.default.decode(jsonData: data)
    }

}
