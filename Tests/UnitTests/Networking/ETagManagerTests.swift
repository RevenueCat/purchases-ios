import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ETagManagerTests: XCTestCase {

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
        _ = mockStoredETagAndResponse(for: url)
        let request = URLRequest(url: url)
        let header = eTagManager.eTagHeader(for: request)
        let value2: String? = header[ETagManager.eTagHeaderName]

        expect(value2).toNot(beNil())
        expect(value2) == "an_etag"
    }

    func testStoredResponseIsUsedIfResponseCodeIs304() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let cachedResponse = mockStoredETagAndResponse(for: url, statusCode: .success, eTag: eTag)

        guard let httpURLResponse = HTTPURLResponse(url: url,
                                                    statusCode: HTTPStatusCode.notModified.rawValue,
                                                    httpVersion: "HTTP/1.1",
                                                    headerFields: getHeaders(eTag: eTag)) else {
            fatalError("Error initializing HTTPURLResponse")
        }
        let response = eTagManager.httpResultFromCacheOrBackend(with: httpURLResponse,
                                                                jsonObject: [:],
                                                                request: request,
                                                                retried: false)
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.jsonObject as? [String: String]).to(equal(cachedResponse))
    }

    func testStoredResponseIsNotUsedIfResponseCodeIs200() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        _ = mockStoredETagAndResponse(for: url, statusCode: .success, eTag: eTag)
        let responseObject = ["a": "response"]
        let httpURLResponse = httpURLResponseForTest(url: url, eTag: eTag, statusCode: .success)
        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, jsonObject: responseObject, request: request, retried: false)
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .success
        expect(response?.jsonObject as? [String: String]).to(equal(responseObject))
    }

    func testBackendResponseIsReturnedIf304AndCantFindCachedAndItHasAlreadyRetried() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = ["a": "response"]
        let httpURLResponse = httpURLResponseForTest(
            url: url,
            eTag: eTag,
            statusCode: .notModified
        )
        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, jsonObject: responseObject, request: request, retried: true)
        expect(response).toNot(beNil())
        expect(response?.statusCode) == .notModified
        expect(response?.jsonObject as? [String: String]).to(equal(responseObject))
    }

    func testReturnNullIf304AndCantFindCachedResponse() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = ["a": "response"]
        let httpURLResponse = httpURLResponseForTest(
            url: url,
            eTag: eTag,
            statusCode: .notModified
        )
        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, jsonObject: responseObject, request: request, retried: false)
        expect(response).to(beNil())
    }

    func testResponseIsStoredIfResponseCodeIs200() throws {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = ["a": "response"]
        let httpURLResponse = httpURLResponseForTest(
            url: url,
            eTag: eTag,
            statusCode: .success
        )
        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, jsonObject: responseObject, request: request, retried: false)

        expect(response).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 1

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).toNot(beNil())
        let setData = try XCTUnwrap(self.mockUserDefaults.mockValues[cacheKey] as? Data)

        expect(setData).toNot(beNil())
        let expectedCachedValue = "https://api.revenuecat.com/v1/subscribers/appUserID"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedCachedValue
        guard let eTagAndResponseWrapper = ETagAndResponseWrapper(with: setData) else {
            fatalError("Error creating ETagAndResponseWrapper")
        }
        expect(eTagAndResponseWrapper.eTag) == eTag
        expect(eTagAndResponseWrapper.jsonObject as? [String: String]) == responseObject
    }

    func testResponseIsNotStoredIfResponseCodeIs500() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject: [String: String] = [:]

        let httpURLResponse = httpURLResponseForTest(
            url: url,
            eTag: eTag,
            statusCode: .internalServerError
        )
        let response = eTagManager.httpResultFromCacheOrBackend(
            with: httpURLResponse, jsonObject: responseObject, request: request, retried: false)

        expect(response).toNot(beNil())
        expect(response?.statusCode) == .internalServerError
        expect(response?.jsonObject as? [String: String]).to(equal(responseObject))

        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 0

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).to(beNil())
    }

    func testClearCachesWorks() {
        let eTag = "an_etag"
        let url = urlForTest()
        _ = mockStoredETagAndResponse(for: url, statusCode: .success, eTag: eTag)

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).toNot(beNil())

        eTagManager.clearCaches()

        expect(self.mockUserDefaults.mockValues.count) == 0
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

    func mockStoredETagAndResponse(for url: URL,
                                           statusCode: HTTPStatusCode = .success,
                                           eTag: String = "an_etag") -> [String: String] {
        let jsonObject = ["arg": "value"]
        let etagAndResponse = ETagAndResponseWrapper(
            eTag: eTag,
            statusCode: statusCode,
            jsonObject: jsonObject)
        let cacheKey = url.absoluteString
        self.mockUserDefaults.mockValues[cacheKey] = etagAndResponse.asData()
        return jsonObject
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
