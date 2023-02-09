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
        self.eTagManager = ETagManager(userDefaults: self.mockUserDefaults)
    }

    override func tearDown() {
        self.mockUserDefaults = nil
        self.eTagManager = nil

        super.tearDown()
    }

    func testETagIsEmptyIfThereIsNoETagSavedForThatRequest() {
        let url = urlForTest()
        let request = URLRequest(url: url)
        let header = eTagManager.eTagHeader(for: request)
        let value2: String? = header[ETagManager.eTagHeaderName]

        expect(value2).toNot(beNil())
        expect(value2) == ""
    }

    func testETagIsAddedToHeadersIfThereIsACachedETagForThatURL() {
        let url = urlForTest()
        _ = mockStoredETagResponse(for: url)
        let request = URLRequest(url: url)
        let header = eTagManager.eTagHeader(for: request)
        let value2: String? = header[ETagManager.eTagHeaderName]

        expect(value2).toNot(beNil())
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

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: url, body: responseObject, eTag: eTag, statusCode: .success),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.body) == responseObject
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

    func testResponseIsStoredIfResponseCodeIs200AndValidationWasNotRequested() throws {
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
                validationResult: .notRequested
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

    func testResponseIsStoredIfResponseCodeIs200AndValidationSucceded() throws {
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
                validationResult: .validated
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

    func testResponseIsNotStoredIfValidationFailed() {
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
                validationResult: .failedValidation
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(response?.validationResult) == .failedValidation

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
        expect(response?.validationResult) == .notRequested
    }

    func testETagHeaderIsNotFoundIfItsMissingResponseValidation() {
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

        let response = self.eTagManager.eTagHeader(for: request)
        expect(response[ETagManager.eTagHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfValidationFailed() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            validationResult: .failedValidation
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request)
        expect(response[ETagManager.eTagHeaderName]).to(beEmpty())
    }

    func testETagHeaderIsReturnedIfValidationSucceded() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            validationResult: .validated
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request)
        expect(response[ETagManager.eTagHeaderName]) == eTag
    }

    func testETagHeaderIsIgnoredIfValidationWasNotRequested() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            validationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request)
        expect(response[ETagManager.eTagHeaderName]) == eTag
    }

    func testCachedResponseWithNoValidationResultIsIgnored() {
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
        expect(response).to(beNil())
    }

    func testCachedResponseIsFoundIfValidationWasNotRequested() {
        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            validationResult: .notRequested
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
        expect(response?.validationResult) == .notRequested
    }

    func testCachedResponseIsFoundIfValidationSucceeded() {
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
        "validation_result": \(HTTPResponseValidationResult.validated.rawValue)
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
        expect(response?.validationResult) == .validated
    }

    func testCachedResponseIsReturnedEvenIfValidationFailed() {
        // Technically, as tested by `testResponseIsNotStoredIfValidationFailed`
        // a response can't be stored if validation failed, but useful to test just in case.

        let eTag = "the_etag"
        let url = self.urlForTest()
        let request = URLRequest(url: url)
        let cacheKey = url.absoluteString

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[cacheKey] = ETagManager.Response(
            eTag: eTag,
            statusCode: .success,
            data: actualResponse,
            validationResult: .failedValidation
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
        expect(response?.validationResult) == .failedValidation
    }

}

private extension ETagManagerTests {

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
            ETagManager.eTagHeaderName: eTag
        ]
            .merging(HTTPClient.authorizationHeader(withAPIKey: "apikey"))
    }

    func mockStoredETagResponse(for url: URL,
                                statusCode: HTTPStatusCode = .success,
                                eTag: String = "an_etag",
                                validationResult: HTTPResponseValidationResult = .notRequested) -> Data {
        // swiftlint:disable:next force_try
        let data = try! JSONSerialization.data(withJSONObject: ["arg": "value"])

        let etagAndResponse = ETagManager.Response(
            eTag: eTag,
            statusCode: statusCode,
            data: data,
            validationResult: validationResult
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
        validationResult: HTTPResponseValidationResult = .notRequested
    ) -> HTTPResponse<Data?> {
        return .init(statusCode: statusCode,
                     responseHeaders: self.getHeaders(eTag: eTag),
                     body: body,
                     validationResult: validationResult)
    }

}

private extension ETagManager.Response {

    static func with(_ data: Data) throws -> Self {
        return try JSONDecoder.default.decode(jsonData: data)
    }

}
