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

        let httpURLResponse = self.httpURLResponseForTest(url: url,
                                                          eTag: eTag,
                                                          statusCode: .notModified)

        let response = eTagManager.httpResultFromCacheOrBackend(with: httpURLResponse,
                                                                data: nil,
                                                                request: request,
                                                                retried: false)
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
        let httpURLResponse = httpURLResponseForTest(url: url, eTag: eTag, statusCode: .success)

        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, data: responseObject, request: request, retried: false
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
        let httpURLResponse = httpURLResponseForTest(
            url: url,
            eTag: eTag,
            statusCode: .notModified
        )

        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, data: responseObject, request: request, retried: true)

        expect(response).toNot(beNil())
        expect(response?.statusCode) == .notModified
        expect(response?.body) == responseObject
    }

    func testReturnNullIf304AndCantFindCachedResponse() throws {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let httpURLResponse = httpURLResponseForTest(
            url: url,
            eTag: eTag,
            statusCode: .notModified
        )

        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, data: responseObject, request: request, retried: false)

        expect(response).to(beNil())
    }

    func testResponseIsStoredIfResponseCodeIs200() throws {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let httpURLResponse = httpURLResponseForTest(
            url: url,
            eTag: eTag,
            statusCode: .success
        )
        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, data: responseObject, request: request, retried: false)

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

        let httpURLResponse = httpURLResponseForTest(
            url: url,
            eTag: eTag,
            statusCode: .internalServerError
        )
        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, data: responseObject, request: request, retried: false)

        expect(response).toNot(beNil())
        expect(response?.statusCode) == .internalServerError
        expect(response?.body) == responseObject

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

        let httpURLResponse = self.httpURLResponseForTest(url: url,
                                                          eTag: eTag,
                                                          statusCode: .notModified)

        let response = eTagManager.httpResultFromCacheOrBackend(with: httpURLResponse,
                                                                data: actualResponse,
                                                                request: request,
                                                                retried: true)
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .notModified
        expect(response?.body) == actualResponse
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
                                eTag: String = "an_etag") -> Data {
        // swiftlint:disable:next force_try
        let data = try! JSONSerialization.data(withJSONObject: ["arg": "value"])

        let etagAndResponse = ETagManager.Response(
            eTag: eTag,
            statusCode: statusCode,
            data: data
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

    func httpURLResponseForTest(url: URL, eTag: String, statusCode: HTTPStatusCode) -> HTTPURLResponse {
        guard let httpURLResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode.rawValue,
            httpVersion: "HTTP/1.1",
            headerFields: getHeaders(eTag: eTag)
        ) else {
            fatalError("Error initializing HTTPURLResponse")
        }
        return httpURLResponse
    }

}

private extension ETagManager.Response {

    static func with(_ data: Data) throws -> Self {
        return try JSONDecoder.default.decode(jsonData: data)
    }

}
